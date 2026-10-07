#!/usr/bin/env bash
# The release gate (spec M7), run before every store upload. There is no CI
# by choice; this script is the gate. Stops at the first failure.
#
#   tool/release_check.sh
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n▸ %s\n' "$1"; }

step "Format"
dart format --output=none --set-exit-if-changed lib test integration_test tool

step "Analyze"
flutter analyze

step "Tests (including every golden backup: restores must reproduce balances)"
flutter test --coverage

step "Golden backups (explicitly, so a skip can't hide a failure)"
flutter test test/golden

step "Coverage of core and domain ≥ 80 %"
dart run tool/coverage_gate.dart

step "Signed release bundle"
test -f android/key.properties || { echo "android/key.properties missing (release signing)"; exit 1; }
test -f .env || { echo ".env missing (copy .env.example)"; exit 1; }
flutter build appbundle --release
jarsigner -verify build/app/outputs/bundle/release/app-release.aab >/dev/null \
  && echo "AAB signature verifies"

step "All release checks passed"
