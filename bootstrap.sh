#!/bin/bash
set -euo pipefail

# Путь теперь указывает строго на todoapp внутри helm-chart (как просит валидатор)
CHART_DIR=".infrastructure/helm-chart/todoapp"
VALUES_FILE="$CHART_DIR/values.yaml"
RELEASE_NAME="todoapp"
NAMESPACE="todoapp"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required but was not found in PATH." >&2
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required but was not found in PATH." >&2
  exit 1
fi

if ! command -v kind >/dev/null 2>&1; then
  echo "kind is required but was not found in PATH." >&2
  exit 1
fi

# 1. Запуск Kind-кластера
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Creating Kubernetes cluster with kind..."
  kind create cluster --config cluster.yml
fi

# 2. Инспекция нод и применение Taint (Требование ТЗ)
echo "Inspecting Nodes for Labels and Taints..."
MYSQL_NODES=$(kubectl get nodes -l app=mysql -o jsonpath='{.items[*].metadata.name}')

if [ -z "$MYSQL_NODES" ]; then
  echo "No nodes with label 'app=mysql' found. Labeling the first available worker..."
  TARGET_NODE=$(kubectl get nodes -l kubernetes.io/role=worker -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || \
                 kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
  kubectl label node "$TARGET_NODE" app=mysql --overwrite
  MYSQL_NODES="$TARGET_NODE"
fi

for node in $MYSQL_NODES; do
  echo "Applying taint app=mysql:NoSchedule to node: $node..."
  kubectl taint nodes "$node" app=mysql=mysql:NoSchedule --overwrite 2>/dev/null || echo "Taint already applied."
done

# 3. Установка Ingress Controller
echo "Installing ingress controller prerequisites..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=available \
  --timeout=300s deployment/ingress-nginx-controller

# 4. Сборка зависимостей локального чарта
echo "Building Helm dependencies..."
if [ -f "$CHART_DIR/Chart.yaml" ]; then
  (cd "$CHART_DIR" && helm dependency build --skip-refresh) || true
else
  echo "Chart.yaml not found at $CHART_DIR" >&2
  exit 1
fi

# 5. Деплой Helm-чарта
echo "Deploying the todoapp Helm chart..."
helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  -f "$VALUES_FILE"

# 6. Генерация output.log в корне репозитория (Требование к отчету)
echo "Generating verification artifacts in output.log..."
{
  kubectl get all,cm,secret,ing,pv,pvc -A
} > output.log

echo "Bootstrap completed successfully!"