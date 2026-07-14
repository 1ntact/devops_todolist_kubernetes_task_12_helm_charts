# Validation Instructions

## 1. Verify the cluster
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

## 4. Verify the generated output log
The full cluster inventory is stored in:

```bash
output.log
```

## 5. Optional: inspect the deployed resources
You can view the rendered manifests with:

```bash
helm template todoapp .infrastructure/helm-chart -f .infrastructure/helm-chart/values.yml
```
