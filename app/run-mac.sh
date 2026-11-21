#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CLUSTER_NAME=${KEDA_DEMO_CLUSTER:-keda-demo}

fail() {
  echo "Error: $1" >&2
  exit 1
}

command -v brew >/dev/null 2>&1 || fail "Install Homebrew first: https://brew.sh"

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker Desktop..."
  brew install --cask docker
fi

for tool in kubectl helm kind; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Installing $tool with Homebrew..."
    brew install "$tool"
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop, wait until it says Docker is running, then rerun this script."
  open -a Docker
  exit 1
fi

if ! kind get clusters 2>/dev/null | grep -Fxq "$CLUSTER_NAME"; then
  echo "Creating Kind cluster '$CLUSTER_NAME'..."
  kind create cluster --name "$CLUSTER_NAME"
fi

kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null
kubectl cluster-info >/dev/null

helm repo add kedacore https://kedacore.github.io/charts >/dev/null 2>&1 || true
helm repo update
if ! helm status keda --namespace keda >/dev/null 2>&1; then
  helm upgrade --install keda kedacore/keda --namespace keda --create-namespace --wait
fi

"$SCRIPT_DIR/build-and-load.sh" --cluster "$CLUSTER_NAME"

kubectl apply -f "$SCRIPT_DIR/namespace.yaml"
kubectl apply -f "$SCRIPT_DIR/redis.yaml"
kubectl apply -f "$SCRIPT_DIR/worker.yaml"
kubectl apply -f "$SCRIPT_DIR/scaledobject.yaml"

kubectl -n keda-demo rollout status statefulset/redis --timeout=180s
kubectl -n keda-demo rollout status deployment/queue-worker --timeout=180s || true

cat <<EOF

KEDA demo is running on this Mac.
Cluster: kind-$CLUSTER_NAME
Namespace: keda-demo

Push 20 jobs:
  app/test-mac.sh

Watch scaling:
  kubectl -n keda-demo get deployment queue-worker --watch

Watch worker logs:
  kubectl -n keda-demo logs -l app=queue-worker -f --all-pods=true
EOF
