#!/usr/bin/env bash
# Usage: bash scripts/tools/run_tests.sh [name-filter]      Runs every tests/test_*.tscn headless and prints PASS/FAIL per file.
# A test FAILS if it exits non-zero, prints a line starting with "FAIL", logs a SCRIPT/Parse error, or times out (TEST_TIMEOUT s, default 90).
# The headless dummy renderer prints `Parameter "m" is null` / mesh_get_surface_count lines; those are filtered as known noise (see DIRECTION).
# Exit code 1 if anything failed, so CI and agents can rely on it.
cd "$(git rev-parse --show-toplevel)" || exit 1
GODOT="$(bash scripts/tools/ensure_godot.sh)" || exit 1
"$GODOT" --headless --path . --import >/dev/null 2>&1
TO="${TEST_TIMEOUT:-90}"; pass=0; fail=0; failed=()
for t in tests/test_*.tscn; do
  [[ -n "$1" && "$t" != *"$1"* ]] && continue
  log="$(mktemp)"; timeout "$TO" "$GODOT" --headless --path . "res://$t" >"$log" 2>&1; code=$?
  clean="$(grep -v -E 'Parameter "m" is null|mesh_get_surface_count|^$' "$log")"
  why=""
  [ $code -eq 124 ] && why="timeout after ${TO}s"
  [ -z "$why" ] && [ $code -ne 0 ] && why="exit code $code"
  [ -z "$why" ] && echo "$clean" | grep -q -E '^FAIL' && why="a check failed"
  [ -z "$why" ] && echo "$clean" | grep -q -E 'SCRIPT ERROR|Parse Error|Failed to load' && why="script error"
  if [ -z "$why" ]; then echo "PASS  $t"; pass=$((pass+1))
  else echo "FAIL  $t  ($why)"; echo "$clean" | grep -E '^FAIL|ERROR|error' | head -5 | sed 's/^/        /'; fail=$((fail+1)); failed+=("$t"); fi
  rm -f "$log"
done
echo "---- $pass passed, $fail failed"
[ $fail -eq 0 ]
