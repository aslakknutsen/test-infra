#!/bin/bash

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NAMESPACE=${NAMESPACE:-default}
WORKER_NS=${WORKER_NS:-test-pods}

# safety measure: make sure we're on the right cluster
(kubectl get nodes | grep maistra.test) || (echo "Wrong cluster. Exiting..."; exit 1)

# make sure we use the latest configuration
./"${DIR}"/gen-config.sh

# update config and plugins
kubectl -n "${NAMESPACE}" create configmap config --from-file=config.yaml="${DIR}"/config.gen.yaml --dry-run -o yaml | kubectl -n "${NAMESPACE}" replace configmap config -f -
kubectl -n "${NAMESPACE}" create configmap plugins --from-file=plugins.yaml="${DIR}"/plugins.yaml --dry-run -o yaml | kubectl -n "${NAMESPACE}" replace configmap plugins -f -

# update deployments etc.
for file in "${DIR}"/cluster/*; do
  # shellcheck disable=SC2016 ## in case of sed expression first '' is not an actual variable to be expanded
  sed -e 's@${NAMESPACE}@'"${NAMESPACE}"'@g' -e 's@${WORKER_NS}@'"${WORKER_NS}"'@g' "$file" | kubectl apply -f -
done

# restart deployments
for deployment in $(kubectl get deployments -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  kubectl rollout restart deployment "${deployment}" -n "${NAMESPACE}"
done
