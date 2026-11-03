#!/bin/bash
set -euo pipefail

# Build a device app and package it as an unsigned IPA.
# Requirements: macOS with Xcode installed. Sideloadly/AltStore signs the IPA during installation.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/FitnessFlow.xcodeproj"
BUILD_DIR="$ROOT/.build"
EXPORT_DIR="$ROOT/build-output"
APP="$BUILD_DIR/Build/Products/Release-iphoneos/FitnessFlow.app"

rm -rf "$BUILD_DIR" "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR/Payload"

xcodebuild \
  -project "$PROJECT" \
  -scheme FitnessFlow \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

if [[ ! -d "$APP" ]]; then
  echo "Expected app bundle was not produced: $APP" >&2
  exit 1
fi

cp -R "$APP" "$EXPORT_DIR/Payload/FitnessFlow.app"
(cd "$EXPORT_DIR" && /usr/bin/zip -qry FitnessFlow-unsigned.ipa Payload)

echo "Created: $EXPORT_DIR/FitnessFlow-unsigned.ipa"
unzip -l "$EXPORT_DIR/FitnessFlow-unsigned.ipa" | head -20
