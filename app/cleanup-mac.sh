#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${KEDA_DEMO_CLUSTER:-keda-demo}

if kubectl config get-contexts "kind-$CLUSTER_NAME" >/dev/null 2>&1; then
  kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null
  kubectl delete namespace keda-demo --ignore-not-found

  if helm status keda --namespace keda >/dev/null 2>&1; then
    helm uninstall keda --namespace keda
  fi

  kubectl delete namespace keda --ignore-not-found
  kind delete cluster --name "$CLUSTER_NAME"
else
  echo "Kind cluster '$CLUSTER_NAME' was not found. Nothing to clean up."
fi
