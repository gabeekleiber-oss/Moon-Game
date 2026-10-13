#!/usr/bin/env bash
# Import assets, then fail closed unless each exact license is recorded and approved.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
python3 scripts/tools/assets.py import
python3 scripts/tools/check_asset_licenses.py
python3 scripts/tools/assets.py verify
