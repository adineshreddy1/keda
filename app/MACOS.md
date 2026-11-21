# Run the KEDA demo on macOS

## Quick start

1. Start Docker Desktop.
2. Open Terminal in the repository root.
3. Enable and run the scripts:

```bash
chmod +x app/run-mac.sh app/build-and-load.sh app/test-mac.sh app/cleanup-mac.sh
app/run-mac.sh
```

The runner will:

- Install missing Homebrew dependencies
- Create or reuse a Kind cluster
- Install KEDA with Helm
- Build and load the worker image
- Deploy Redis, the worker, and the KEDA ScaledObject

Docker Desktop is supported on Intel and Apple Silicon Macs.

## Add work

Push 20 jobs:

```bash
app/test-mac.sh
```

Push a custom number:

```bash
app/test-mac.sh 50
```

## Watch autoscaling

Watch replicas:

```bash
kubectl -n keda-demo get deployment queue-worker --watch
```

Watch worker logs:

```bash
kubectl -n keda-demo logs -l app=queue-worker -f --all-pods=true
```

Inspect KEDA:

```bash
kubectl -n keda-demo get scaledobject,hpa
kubectl -n keda-demo describe scaledobject queue-worker-scaler
```

After the queue is empty, the worker should scale to zero after the configured cooldown period.

## Cleanup

```bash
app/cleanup-mac.sh
```

This removes the demo namespace, uninstalls KEDA, and deletes the Kind cluster.
