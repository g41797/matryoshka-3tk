#!/usr/bin/env bash
#
# 3TK-69. Substitutes `[[LOC]]` (L-5) in `src/*.c3` with the count
# `count_src_loc.sh` computes. A separate program from the counter (L-3):
# its failure modes, flags and consumers are different.
#
# Usage:  ./inject_src_loc.sh [--write] [--strict] [dir]
#
#   --write   perform the substitution. Without it, this is a dry run: it
#             reports what would change and touches nothing (L-7). CI passes
#             this flag; a person does not unless they mean it.
#   --strict  a missing `[[LOC]]` is an error, exit 1 (L-10). CI passes
#             this. Without it, a missing token is a report, exit 0 -- a
#             person may be running this against a tree that has not grown
#             the token yet.
#   dir       defaults to this script's own directory's parent (the
#             project root). Exit 2 on a bad directory.
#
# Every occurrence is replaced and the count is printed, so a second use
# site is never half-substituted.

set -u

WRITE=0
STRICT=0
ARGS=()
for a in "$@"; do
    case "$a" in
        --write)  WRITE=1 ;;
        --strict) STRICT=1 ;;
        *)        ARGS+=("$a") ;;
    esac
done

ROOT=${ARGS[0]:-}
[ -n "$ROOT" ] || ROOT=$(dirname "$0")/..
cd "$ROOT" || { echo "no such directory: $ROOT" >&2; exit 2; }
ROOT=$(pwd)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

LOC=$("$SCRIPT_DIR/count_src_loc.sh" "$ROOT") || exit 2

FILES=()
for f in "$ROOT"/src/*.c3; do
    [ -f "$f" ] || continue
    grep -q '\[\[LOC\]\]' "$f" && FILES+=("$f")
done

if [ "${#FILES[@]}" -eq 0 ]; then
    if [ "$STRICT" -eq 1 ]; then
        echo "no [[LOC]] token found under $ROOT/src" >&2
        exit 1
    fi
    echo "no [[LOC]] token found under $ROOT/src"
    exit 0
fi

TOTAL=0
for f in "${FILES[@]}"; do
    n=$(grep -o '\[\[LOC\]\]' "$f" | wc -l)
    TOTAL=$((TOTAL + n))
done

if [ "$WRITE" -eq 0 ]; then
    echo "dry run: $TOTAL occurrence(s) of [[LOC]] would become $LOC in ${#FILES[@]} file(s):"
    printf '  %s\n' "${FILES[@]}"
    exit 0
fi

for f in "${FILES[@]}"; do
    sed -i "s/\[\[LOC\]\]/$LOC/g" "$f"
done
echo "replaced $TOTAL occurrence(s) of [[LOC]] with $LOC in ${#FILES[@]} file(s)"
