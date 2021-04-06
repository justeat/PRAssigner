#!/bin/bash

set -eu

executable=$1
workspace="$(pwd)"

echo "-------------------------------------------------------------------------"
echo "Building \"$executable\" lambda"
echo "-------------------------------------------------------------------------"
swift build --product $executable -c release
echo "Done ✅"

echo "-------------------------------------------------------------------------"
echo "Packaging \"$executable\" lambda"
echo "-------------------------------------------------------------------------"
./scripts/package.sh $executable
echo "Done ✅"
