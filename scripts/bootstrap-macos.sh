#!/usr/bin/env bash
# Generate App/RTXOn.xcodeproj from App/project.yml. macOS + Xcode only.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install xcodegen
  elif command -v mint >/dev/null 2>&1; then
    mint install yonaskolb/XcodeGen
  else
    echo "xcodegen not found; install Homebrew (https://brew.sh) then re-run." >&2
    exit 1
  fi
fi

xcodegen generate --spec App/project.yml --project App
echo "Generated App/RTXOn.xcodeproj"
