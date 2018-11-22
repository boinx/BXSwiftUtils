#!/usr/bin/env bash
set -e
set -x

_artifacts="Artifacts"
rm -Rf "$_artifacts"
mkdir "$_artifacts"

set -o pipefail; xcodebuild -scheme "BXSwiftUtils" -configuration "Release" clean build | xcpretty

source .bx_build_env

pushd "$BUILD_PRODUCTS_DIR"
zip -ryq "$SRCROOT/$_artifacts/BXSwiftUtils-macOS.framework.zip" "$PRODUCT_NAME"
popd

set -o pipefail; xcodebuild -scheme "BXSwiftUtils" -configuration "Release" -destination "platform=iOS Simulator,name=iPhone X,OS=latest" clean build | xcpretty

source .bx_build_env

pushd "$BUILD_PRODUCTS_DIR"
zip -ryq "$SRCROOT/$_artifacts/BXSwiftUtils-iOS.framework.zip" "$PRODUCT_NAME"
popd

