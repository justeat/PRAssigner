#!/bin/bash

set -eu

executable=$1

target=.build/lambda/$executable
rm -rf "$target"
mkdir -p "$target"
cp ".build/release/$executable" "$target/"
cp -Pv \
  /usr/lib/swift/linux/libBlocksRuntime.so \
  /usr/lib/swift/linux/libFoundation*.so \
  /usr/lib/swift/linux/libdispatch.so \
  /usr/lib/swift/linux/libicu* \
  /usr/lib/swift/linux/libswiftCore.so \
  /usr/lib/swift/linux/libswiftDispatch.so \
  /usr/lib/swift/linux/libswiftGlibc.so \
  "$target"
cd "$target"
ln -s "$executable" "bootstrap"
zip --symlinks lambda.zip *
