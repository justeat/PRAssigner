#!/bin/bash

set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/config.sh

$DIR/build-and-package.sh "$executable"

echo "-------------------------------------------------------------------------"
echo "Deploying \"$executable\" using Serverless"
echo "-------------------------------------------------------------------------"

serverless deploy --config "./serverless.yml" -v

echo "Done ✅"
echo "$executable has been successfully deployed 🙌"
