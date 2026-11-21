# Local KEDA Redis Autoscaling Demo

A UI-free Kubernetes demo that proves KEDA can scale a worker Deployment from zero based on Redis list length.

## Components

- Redis 7 StatefulSet: stores the `jobs` list.
- Python worker Deployment: consumes `jobs` with `BRPOP`.
- KEDA ScaledObject: one worker per queued item, from 0 to 10 replicas.

## Prerequisites

- Docker running
- A local Kubernetes cluster created with kind or k3d
- `kubectl` and `helm`
- A load balancer implementation is not required

## 1. Create a local cluster

Using kind:

```bash
kind create cluster --name keda-demo
```

Using k3d:

```bash
k3d cluster create keda-demo
kubectl config use-context k3d-keda-demo
```

## 2. Install KEDA

```bash
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade --install keda kedacore/keda --namespace keda --create-namespace
kubectl -n keda rollout status deployment/keda-operator
kubectl -n keda rollout status deployment/keda-metrics-apiserver
```

## 3. Build and load the worker image

```bash
chmod +x app/build-and-load.sh
app/build-and-load.sh
```

The script loads the image into kind or k3d. If neither tool is installed, build/push the image to a registry and change `spec.template.spec.containers[0].image` in `app/worker.yaml`.

## 4. Deploy Redis and the worker

```bash
kubectl apply -f app/namespace.yaml
kubectl apply -f app/redis.yaml
kubectl apply -f app/worker.yaml
kubectl apply -f app/scaledobject.yaml

kubectl -n keda-demo rollout status statefulset/redis
kubectl -n keda-demo get deployment queue-worker
```

The worker should initially have 0 replicas.

## 5. Add work

Run a Redis pod and push jobs:

```bash
kubectl -n keda-demo run redis-producer --rm -it --restart=Never \
  --image=redis:7-alpine -- redis-cli -h redis
```

At the `redis:6379>` prompt:

```text
LPUSH jobs job-1
LPUSH jobs job-2
LPUSH jobs job-3
LLEN jobs
```

Exit by typing `exit`.

## 6. Watch KEDA scale and process

Open one terminal:

```bash
kubectl -n keda-demo get deployment queue-worker --watch
```

Open another:

```bash
kubectl -n keda-demo logs -l app=queue-worker -f --all-pods=true
```

You can also inspect KEDA resources:

```bash
kubectl -n keda-demo get scaledobject,hpa
kubectl -n keda-demo describe scaledobject queue-worker-scaler
```

After the Redis queue remains empty, KEDA should scale the Deployment back to 0 after the cooldown period.

## 7. Push a batch

```bash
kubectl -n keda-demo run redis-batch --rm -it --restart=Never \
  --image=redis:7-alpine -- sh -c \
  'for i in $(seq 1 20); do redis-cli -h redis LPUSH jobs "job-$i"; done'
```

With `listLength: 1`, KEDA can scale up to 10 replicas; the worker processes jobs with a 2-second simulated processing time.

## Cleanup

```bash
kubectl delete namespace keda-demo
helm uninstall keda --namespace keda
kubectl delete namespace keda
kind delete cluster --name keda-demo
```

# App Documentation

Use [`MACOS.md`](MACOS.md) for macOS setup, testing, and cleanup.

The Kubernetes manifests are:

- `namespace.yaml`
- `redis.yaml`
- `worker.yaml`
- `scaledobject.yaml`
