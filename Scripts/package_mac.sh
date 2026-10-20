#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$project_root/DerivedData/MacPackage"
output_dir="$project_root/outputs/mac"
image_path="$output_dir/FretMap-$(date +%Y%m%d-%H%M%S).dmg"

if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

# Personal-use package: ad-hoc signed, not Developer ID signed or notarized.
xcodebuild -project "$project_root/FretMap.xcodeproj" -scheme FretMap \
    -configuration Release -destination 'generic/platform=macOS,variant=Mac Catalyst' \
    -derivedDataPath "$build_dir" CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual \
    ONLY_ACTIVE_ARCH=NO build -quiet

app_path="$build_dir/Build/Products/Release-maccatalyst/FretMap.app"
codesign --verify --deep --strict "$app_path"
mkdir -p "$output_dir"
staging_dir="$(mktemp -d -t FretMapDMG)"
trap 'rm -rf -- "$staging_dir"' EXIT
ditto "$app_path" "$staging_dir/FretMap.app"
ln -s /Applications "$staging_dir/Applications"
hdiutil create -volname FretMap -srcfolder "$staging_dir" \
    -format UDZO "$image_path"
hdiutil verify "$image_path"

printf '\nDMG: %s\n' "$image_path"
