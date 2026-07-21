#!/bin/sh
set -eu

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
reference="$root_dir/FretMap/en.lproj/Localizable.strings"

extract_keys() {
    sed -n 's/^"\([^"]*\)"[[:space:]]*=.*/\1/p' "$1" | LC_ALL=C sort
}

reference_keys="$(mktemp)"
candidate_keys=""
trap 'rm -f "$reference_keys" ${candidate_keys:+"$candidate_keys"}' EXIT
extract_keys "$reference" > "$reference_keys"

for localization in "$root_dir"/FretMap/*.lproj/Localizable.strings; do
    candidate_keys="$(mktemp)"
    extract_keys "$localization" > "$candidate_keys"
    if ! diff -u "$reference_keys" "$candidate_keys"; then
        echo "Localization keys do not match: $localization" >&2
        exit 1
    fi
    rm -f "$candidate_keys"
    candidate_keys=""
done

echo "Localization keys are consistent."
