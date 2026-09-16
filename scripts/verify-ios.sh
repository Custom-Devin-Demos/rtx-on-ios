#!/usr/bin/env bash
# Build, unit-test, install, and launch RTX ON on an iPhone simulator.
#
#   scripts/verify-ios.sh                 build + test + install + launch
#   RECORD=1 scripts/verify-ios.sh        also record the simulator to artifacts/ios-run.mp4 (Ctrl-C to stop)
#   SIMULATOR="iPhone 16 Pro" ...         pick a device (default: first available iPhone)
#   SKIP_TESTS=1 ...                      skip xcodebuild test
#   RESET=1 ...                           uninstall first so progress starts from zero
#
# Requires macOS with Xcode 16+ and xcodegen (scripts/bootstrap-macos.sh).
set -euo pipefail
cd "$(dirname "$0")/.."

SCHEME=RTXOn
PROJECT=App/RTXOn.xcodeproj
BUNDLE_ID=com.devindemos.nvidia.rtxon
DERIVED=build/DerivedData
ARTIFACTS=artifacts
mkdir -p "$ARTIFACTS"

[ -d "$PROJECT" ] || scripts/bootstrap-macos.sh

pick_simulator() {
  xcrun simctl list devices available -j | SIMULATOR="${SIMULATOR:-}" python3 -c '
import json, os, sys
devices = json.load(sys.stdin)["devices"]
runtimes = sorted((rt for rt in devices if "iOS" in rt), reverse=True)
want = os.environ.get("SIMULATOR") or ""
for rt in runtimes:
    for d in devices[rt]:
        if (want and d["name"] == want) or (not want and d["name"].startswith("iPhone")):
            print(d["udid"]); sys.exit(0)
sys.exit("no matching iPhone simulator")'
}

UDID="$(pick_simulator)"
echo "==> Commit: $(git rev-parse --short HEAD)  Xcode: $(xcodebuild -version | tr '\n' ' ')"
echo "==> Simulator: $UDID ($(xcrun simctl list devices | grep "$UDID" | sed 's/^ *//'))"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
open -a Simulator --args -CurrentDeviceUDID "$UDID" || true

DEST="platform=iOS Simulator,id=$UDID"

echo "==> Building"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
  -destination "$DEST" -derivedDataPath "$DERIVED" \
  build 2>&1 | tee "$ARTIFACTS/xcodebuild-build.log" | grep -E "error:|\*\* BUILD" || true
grep -q "BUILD SUCCEEDED" "$ARTIFACTS/xcodebuild-build.log"

if [ -z "${SKIP_TESTS:-}" ]; then
  echo "==> Unit tests"
  rm -rf "$ARTIFACTS/RTXOnTests.xcresult"
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
    -destination "$DEST" -derivedDataPath "$DERIVED" \
    -resultBundlePath "$ARTIFACTS/RTXOnTests.xcresult" \
    test 2>&1 | tee "$ARTIFACTS/xcodebuild-test.log" | grep -E "Test Case|error:|\*\* TEST|Executed" || true
  grep -q "TEST SUCCEEDED" "$ARTIFACTS/xcodebuild-test.log"
fi

APP="$(find "$DERIVED/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name 'RTXOn.app' | head -n1)"
if [ -n "${RESET:-}" ]; then
  xcrun simctl uninstall "$UDID" "$BUNDLE_ID" 2>/dev/null || true
fi
echo "==> Installing $APP"
xcrun simctl install "$UDID" "$APP"

if [ -n "${RECORD:-}" ]; then
  rm -f "$ARTIFACTS/ios-run.mp4"
  xcrun simctl io "$UDID" recordVideo --codec h264 --force "$ARTIFACTS/ios-run.mp4" &
  RECORD_PID=$!
  trap 'kill -INT $RECORD_PID 2>/dev/null; wait $RECORD_PID 2>/dev/null; echo "Recording: $ARTIFACTS/ios-run.mp4"' EXIT
  sleep 1
fi

echo "==> Launching $BUNDLE_ID"
xcrun simctl launch "$UDID" "$BUNDLE_ID"
sleep 3
xcrun simctl io "$UDID" screenshot "$ARTIFACTS/launch.png" >/dev/null
echo "Screenshot: $ARTIFACTS/launch.png"

if [ -n "${RECORD:-}" ]; then
  echo "Recording. Drive the app (Fermi 01 -> place mirror -> solve -> share; RTX toggle; rtx-smi), then press Ctrl-C to stop."
  wait $RECORD_PID
fi
