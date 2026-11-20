#!/bin/sh
# Zips build/PowerLevel.app for a release and writes its SHA-256 and a Homebrew cask.
#   Output: build/PowerLevel-<version>.zip, build/PowerLevel-<version>.zip.sha256, build/powerlevel.rb
# Run ./scripts/build-app.sh first.
set -eu
cd "$(dirname "$0")/.."
VERSION=$(tr -d '[:space:]' < version.txt)
ZIP="build/PowerLevel-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent build/PowerLevel.app "$ZIP"   # ditto keeps the code signature intact
SHA=$(shasum -a 256 "$ZIP" | awk '{print $1}')
echo "$SHA  PowerLevel-$VERSION.zip" > "$ZIP.sha256"
./scripts/make-cask.sh "$VERSION" "$SHA" > build/powerlevel.rb
echo "Packaged $ZIP"
echo "sha256 $SHA"
