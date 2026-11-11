#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
mac_build_dir="$project_root/DerivedData/Mac"
mac_app="$mac_build_dir/Build/Products/Debug-maccatalyst/FretMap.app"

if [[ $# -gt 1 || ( $# -eq 1 && "$1" != "--open" ) ]]; then
    printf 'Usage: %s [--open]\n' "$0" >&2
    exit 2
fi

if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

xcodebuild -project "$project_root/FretMap.xcodeproj" -scheme FretMap \
    -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' \
    -derivedDataPath "$mac_build_dir" CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual \
    build -quiet

printf '\nMac app: %s\n' "$mac_app"
if [[ "${1:-}" == "--open" ]]; then
    open "$mac_app"
fi
