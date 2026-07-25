#!/usr/bin/env sh
# Render a distribution AGENTS.md from core/ALWAYS.md.
#
# core/ALWAYS.md is already the distributable file. This script exists to stamp it with
# provenance (version + law count) so an installed copy can be identified and diffed
# against the upstream release it came from.
#
# Usage:
#   scripts/render-core.sh [--out <path>] [--laws-dir agent-laws/laws]
#
# Default output: dist/AGENTS.md

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/dist/AGENTS.md"
LAWS_DIR="agent-laws/laws"

while [ $# -gt 0 ]; do
  case "$1" in
    --out)      OUT=${2:-}; shift 2 ;;
    --laws-dir) LAWS_DIR=${2:-}; shift 2 ;;
    -h|--help)  sed -n '2,12p' "$0"; exit 0 ;;
    *)          printf 'render-core.sh: unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
done

VERSION=$(cat "$ROOT/VERSION")
LAW_COUNT=$(ls -1 "$ROOT"/laws/*.md | grep -cv '/INDEX\.md$')

mkdir -p "$(dirname -- "$OUT")"

{
  printf '<!-- agent-engineering-laws v%s | %s laws | laws at %s/ -->\n' \
    "$VERSION" "$LAW_COUNT" "$LAWS_DIR"
  printf '<!-- Edit ONLY the "## Project context" section below. -->\n'
  if [ "$LAWS_DIR" = "agent-laws/laws" ]; then
    cat "$ROOT/core/ALWAYS.md"
  else
    ESCAPED=$(printf '%s' "$LAWS_DIR" | sed 's/[\/&]/\\&/g')
    sed "s/agent-laws\/laws\//${ESCAPED}\//g" "$ROOT/core/ALWAYS.md"
  fi
} > "$OUT"

printf 'rendered %s (v%s, %s laws, %s lines)\n' \
  "$OUT" "$VERSION" "$LAW_COUNT" "$(wc -l < "$OUT" | tr -d ' ')"

# Machine-readable routing manifest, for agents and tooling that prefer structured input.
# GENERATED, never versioned: laws/INDEX.md stays the single source of truth, so there is no
# second writer to drift (see law `never-parallel-contract`).
MANIFEST="$(dirname -- "$OUT")/laws.json"
{
  printf '{\n  "version": "%s",\n  "laws_dir": "%s",\n  "count": %s,\n  "laws": [\n' \
    "$VERSION" "$LAWS_DIR" "$LAW_COUNT"
  first=1
  for f in "$ROOT"/laws/*.md; do
    id=$(basename "$f" .md); [ "$id" = "INDEX" ] && continue
    title=$(awk 'NR==1&&$0=="---"{i=1;next} i&&/^title:/{sub(/^title:[[:space:]]*/,"");print;exit} i&&$0=="---"{exit}' "$f")
    when=$(grep -F "\`laws/$id.md\`" "$ROOT/laws/INDEX.md" | head -1 | awk -F' \\| ' '{gsub(/^[[:space:]]+|[[:space:]]+\|?$/,"",$4); print $4}')
    [ "$first" -eq 1 ] || printf ',\n'
    first=0
    printf '    {"id": "%s", "title": "%s", "path": "%s/%s.md", "when_to_load": "%s"}' \
      "$id" "${title//\"/\\\"}" "$LAWS_DIR" "$id" "${when//\"/\\\"}"
  done
  printf '\n  ]\n}\n'
} > "$MANIFEST"

printf 'rendered %s (%s laws)\n' "$MANIFEST" "$LAW_COUNT"
