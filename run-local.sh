#!/usr/bin/env zsh

set -e

if [ $# -lt 1 ]; then
    echo "Usage: ./run-local.sh <SCRIPT_NAME> [K6_OPTIONS]"
    exit 1
fi

# By default, we're assuming you're running the extended k6 image "javaducky/demo-k6-operator:latest".
# If not, override the name on the command-line with `IMAGE_NAME=...`.
IMAGE_NAME=${IMAGE_NAME:="javaducky/demo-k6-operator:latest"}

docker run -v $PWD:/scripts -it --rm $IMAGE_NAME run /scripts/$1 ${@:2}
