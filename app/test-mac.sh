#!/usr/bin/env bash
set -euo pipefail

JOB_COUNT=${1:-20}
CLUSTER_NAME=${KEDA_DEMO_CLUSTER:-keda-demo}

kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null

kubectl -n keda-demo run "redis-batch-$RANDOM" --rm -it --restart=Never \
  --image=redis:7-alpine -- sh -c \
  "for i in \$(seq 1 $JOB_COUNT); do redis-cli -h redis LPUSH jobs \"job-\$i\"; done"

echo "Pushed $JOB_COUNT jobs to the 'jobs' Redis list."
