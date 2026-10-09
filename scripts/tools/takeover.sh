#!/usr/bin/env bash
# Usage: scripts/tools/takeover.sh <role>
# Use when a role's account is out of tokens/stalled and YOU are continuing its work. Same as setup_role.sh.
exec "$(dirname "$0")/setup_role.sh" "$@"
