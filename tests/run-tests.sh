#!/usr/bin/env bash
# Integration tests for the scriptr Quarto filter.
#
# For each fixture <name>.qmd at the repo root, renders it in an isolated
# temp directory and diffs the extracted scripts/ tree against
# tests/expected/<name>/. Run all fixtures with no arguments, or a subset by
# passing their names, e.g.: tests/run-tests.sh test
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

FIXTURES=(test multi-language)
if [ "$#" -gt 0 ]; then
  FIXTURES=("$@")
fi

overall_status=0

for name in "${FIXTURES[@]}"; do
  qmd="$ROOT_DIR/$name.qmd"
  expected="$SCRIPT_DIR/expected/$name"

  if [ ! -f "$qmd" ]; then
    echo "FAIL $name: fixture not found at $qmd"
    overall_status=1
    continue
  fi
  if [ ! -d "$expected" ]; then
    echo "FAIL $name: no expected output at $expected"
    overall_status=1
    continue
  fi

  work="$(mktemp -d)"
  cp -r "$ROOT_DIR/_extensions" "$work/"
  cp "$ROOT_DIR/_quarto.yml" "$work/"
  cp "$qmd" "$work/"

  if ! (cd "$work" && quarto render "$name.qmd" --to html) > "$work/render.log" 2>&1; then
    echo "FAIL $name: quarto render failed"
    sed 's/^/    /' "$work/render.log"
    overall_status=1
    rm -rf "$work"
    continue
  fi

  if [ ! -d "$work/scripts" ]; then
    echo "FAIL $name: no scripts/ directory was extracted"
    overall_status=1
    rm -rf "$work"
    continue
  fi

  if diff -r "$expected" "$work/scripts" > "$work/diff.log" 2>&1; then
    echo "PASS $name"
  else
    echo "FAIL $name: extracted output differs from tests/expected/$name"
    sed 's/^/    /' "$work/diff.log"
    overall_status=1
  fi

  rm -rf "$work"
done

exit $overall_status
