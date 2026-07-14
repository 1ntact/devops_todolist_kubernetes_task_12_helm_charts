# Validation Instructions

## 1. Run the bootstrap script
Use the following command to create the cluster, install prerequisites, and deploy the Helm chart:

```bash
./bootstrap.sh
```

## 2. Verify the cluster
Run the following command to confirm the kind cluster and deployed resources:

```bash
kubectl get all,cm,secret,ing -A
```

## 2. Verify the Helm release
Confirm that the Helm release is deployed successfully:

```bash
helm list -A
```

## 3. Verify the application pod status
Check that the application and MySQL pods are running:

```bash
kubectl get pods -A
```

## 4. Generate the output log
Capture the cluster inventory with:

```bash
kubectl get all,cm,secret,ing -A > output.log
```

## 5. Verify node labels and taints
If you want to confirm the MySQL node taint is applied, run:

```bash
kubectl get nodes --show-labels
kubectl describe node $(kubectl get nodes -l app=mysql -o jsonpath='{.items[0].metadata.name}') | grep -i taint -A2 -B2
```

## 6. Optional: inspect the deployed resources
You can view the rendered manifests with:

```bash
helm template todoapp .infrastructure/helm-chart -f .infrastructure/helm-chart/values.yml
```
