#!/usr/bin/env bash
#
# 3TK-69. Source LOC, computed on demand, implementing L-1 of
# 3tk-staging-plan-030.md: real code under `src/`, not blank lines, not
# comments, not the machinery (`import`, `$include`, `$exec`, `$embed`).
#
# The scanner is `c3_loc.py`, next to this script -- it must carry state
# across lines for `/* */` and `<* *>`, which a per-line startswith test
# cannot do.
#
# Usage:  ./count_src_loc.sh [dir]    dir defaults to this script's own
#                                     directory's parent (the project root)
#
# Prints the number and nothing else, so `$(...)` consumes it without
# parsing. Exit 2 on a bad directory.

set -u

ROOT=${1:-}
[ -n "$ROOT" ] || ROOT=$(dirname "$0")/..
cd "$ROOT" || { echo "no such directory: $ROOT" >&2; exit 2; }
ROOT=$(pwd)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PYTHONPATH="$SCRIPT_DIR" python3 -c "
from c3_loc import count_src_loc
print(count_src_loc('$ROOT/src'))
"
