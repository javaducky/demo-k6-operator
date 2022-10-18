#!/usr/bin/env zsh

set -e

if [ $# -ne 1 ]; then
    echo "Usage: ./run-kube.sh <RESOURCE_NAME>"
    exit 1
fi

RESOURCE_NAME=$1
TAG_PREFIX="$(basename -s .yaml $RESOURCE_NAME)"
TAG_NAME="$TAG_PREFIX-$(date +%s)"

# Replacement doesn't seem to trigger, so we need to delete any previous execution
kubectl delete -n k6-demo --ignore-not-found=true --wait=true -f $RESOURCE_NAME

# Update '--tag testid=...' to include the timestamp for uniqueness, then apply
sed "s/testid\=${TAG_PREFIX}/testid\=${TAG_NAME}/g" $RESOURCE_NAME | kubectl apply -n k6-demo -f -
