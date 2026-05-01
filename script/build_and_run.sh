#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/buddi.xcodeproj"
DERIVED_DATA="$ROOT_DIR/.derived-data"
APP_PATH="$DERIVED_DATA/Build/Products/Debug/buddi.app"

cd "$ROOT_DIR"

pkill -9 -f "$APP_PATH" >/dev/null 2>&1 || true
pkill -9 -f "/Applications/Clicky.app/Contents/MacOS/Clicky" >/dev/null 2>&1 || true
pkill -9 -x Clicky >/dev/null 2>&1 || true
pkill -9 -x BuddiXPCHelper >/dev/null 2>&1 || true
pkill -9 -x buddi >/dev/null 2>&1 || true

xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme buddi \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

/usr/bin/open -n "$APP_PATH"

if [[ "${1:-}" == "--verify" ]]; then
  sleep 1
  pgrep -x buddi >/dev/null
  if pgrep -x Clicky >/dev/null; then
    echo "another Clicky process is still running" >&2
    exit 1
  fi
  echo "Clicky launched"
fi
