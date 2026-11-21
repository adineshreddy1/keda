#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CLUSTER_NAME=${KEDA_DEMO_CLUSTER:-keda-demo}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cluster)
      CLUSTER_NAME=${2:?Missing cluster name}
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker build -t keda-demo-worker:latest "$SCRIPT_DIR"
else
  echo "Docker is not running. Start Docker Desktop, then rerun this script." >&2
  exit 1
fi

if command -v kind >/dev/null 2>&1; then
  kind load docker-image keda-demo-worker:latest --name "$CLUSTER_NAME"
elif command -v k3d >/dev/null 2>&1; then
  k3d image import keda-demo-worker:latest --cluster "$CLUSTER_NAME"
else
  echo "Kind or k3d is required to load the local image into the cluster." >&2
  exit 1
fi
