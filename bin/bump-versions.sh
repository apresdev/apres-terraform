#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <module_path> <major|minor|patch> <changelog_message>" >&2
  echo "Example: $0 aws/alerting minor \"Add support for SNS topic filtering\"" >&2
  exit 1
fi

MODULE_PATH="$1"
BUMP_TYPE="$2"
CHANGELOG_MESSAGE="$3"

if [[ "$BUMP_TYPE" != "major" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "patch" ]]; then
  echo "Error: bump type must be major, minor, or patch" >&2
  exit 1
fi

MODULE_NAME="${MODULE_PATH##*/}"
MODULE_DIRECTORY="modules/${MODULE_PATH}"

if [[ ! -d "$MODULE_DIRECTORY" ]]; then
  echo "Error: module directory '$MODULE_DIRECTORY' does not exist" >&2
  exit 1
fi

PREV_VERSION=$(git tag -l "rel/${MODULE_NAME}/*" | sort -V | tail -1 | sed "s|rel/${MODULE_NAME}/||")
PREV_VERSION="${PREV_VERSION:-0.0.0}"
echo "Previous version: $PREV_VERSION"

IFS='.' read -r MAJOR MINOR PATCH <<< "$PREV_VERSION"
case "$BUMP_TYPE" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "New version: $NEW_VERSION"

printf '# This file is auto-generated\nlocals {\n  module_version = "%s"\n}\n' "$NEW_VERSION" \
  > "${MODULE_DIRECTORY}/module_version.tf"

CHANGELOG_FILE="${MODULE_DIRECTORY}/CHANGELOG.md"
TODAY=$(date +%Y-%m-%d)

if [[ -f "$CHANGELOG_FILE" ]]; then
  TMP_FILE=$(mktemp)
  INSERTED=false
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^## && "$INSERTED" == false ]]; then
      printf '## %s - %s\n\n%s\n\n' "$NEW_VERSION" "$TODAY" "$CHANGELOG_MESSAGE" >> "$TMP_FILE"
      INSERTED=true
    fi
    echo "$line" >> "$TMP_FILE"
  done < "$CHANGELOG_FILE"
  if [[ "$INSERTED" == false ]]; then
    printf '\n## %s - %s\n\n%s\n' "$NEW_VERSION" "$TODAY" "$CHANGELOG_MESSAGE" >> "$TMP_FILE"
  fi
  mv "$TMP_FILE" "$CHANGELOG_FILE"
else
  printf '# Changelog\n\nThis change log is automatically generated.\n\n## %s - %s\n\n%s\n' \
    "$NEW_VERSION" "$TODAY" "$CHANGELOG_MESSAGE" > "$CHANGELOG_FILE"
fi

git add "${MODULE_DIRECTORY}/module_version.tf" "${MODULE_DIRECTORY}/CHANGELOG.md"
git commit -m "Update ${MODULE_NAME} CHANGELOG"

TAG_NAME="rel/${MODULE_NAME}/${NEW_VERSION}"
git tag "$TAG_NAME"
echo "Created tag: $TAG_NAME"
echo "Done. Push with: git push && git push --tags"
