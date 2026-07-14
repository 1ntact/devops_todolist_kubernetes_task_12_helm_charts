#!/bin/bash
set -euo pipefail

CHART_DIR=".infrastructure/helm-chart"
VALUES_FILE="$CHART_DIR/values.yml"
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

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Creating Kubernetes cluster with kind..."
  kind create cluster --config cluster.yml
fi

echo "Installing ingress controller prerequisites..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=available \
  --timeout=300s deployment/ingress-nginx-controller

echo "Building Helm dependencies..."
helm dependency build "$CHART_DIR"

for node in $(kubectl get nodes -o name | sed 's#^node/##'); do
  if kubectl get node "$node" -o jsonpath='{.metadata.labels.app}' 2>/dev/null | grep -q '^mysql$'; then
    echo "Tainting node $node with app=mysql:NoSchedule"
    kubectl taint nodes "$node" app=mysql:NoSchedule --overwrite 2>/dev/null || true
  fi
done

echo "Deploying the todoapp Helm chart..."
helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  -f "$VALUES_FILE"
