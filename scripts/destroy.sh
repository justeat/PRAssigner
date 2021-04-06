#!/bin/bash

set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/config.sh

echo "-------------------------------------------------------------------------"
echo "Destroy \"$executable\" using Serverless"
echo "-------------------------------------------------------------------------"

serverless remove --config "./serverless.yml" -v

echo "Done ✅"
echo "$executable has been successfully destroyed 🙌"
