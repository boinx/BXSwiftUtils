#!/usr/bin/env bash
set -e
set -x

_artifacts="Artifacts"
rm -Rf "$_artifacts"
mkdir "$_artifacts"

set -o pipefail; xcodebuild -scheme "BXSwiftUtils-macOS" -configuration "Release" clean build | xcpretty

mkdir -p "$_artifacts/macOS"
cp -R $(cat .bx_product_path) "$_artifacts/macOS/"

set -o pipefail; xcodebuild -scheme "BXSwiftUtils-iOS" -configuration "Release" clean build | xcpretty

mkdir -p "$_artifacts/iOS"
cp -R $(cat .bx_product_path) "$_artifacts/iOS/"

# Delete git tag if already existing
_git_tag="latest"
git tag -d ${_git_tag}
git push origin :refs/tags/${_git_tag}

# Create new "latest" tag
_commit_hash=$(git rev-parse HEAD)
git tag -f -m "Travis tagged with ${_git_tag}" -a "${_git_tag}" "${_commit_hash}"
git push --tags
