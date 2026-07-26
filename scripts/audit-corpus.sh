#!/usr/bin/env bash
# audit-corpus.sh — ADVISORY corpus health report. Never blocks.
#
# scripts/check-laws.sh blocks on what is mechanically certain. This reports what needs
# judgement: overlap, vocabulary drift, structural decay, routing usability. Blocking on a
# heuristic teaches maintainers to fight the gate, and that is how gates die.
#
# Every signal below is a QUESTION for the maintainer, not a verdict. Read
# MAINTENANCE.md §3 (admission), §4 (retirement) and §7 (failure modes) before acting.
#
# Usage: scripts/audit-corpus.sh
# Always exits 0. If you want a failure, use check-laws.sh.
# Targets: bash 3.2 + POSIX utilities (no mapfile, no declare -A).

set -uo pipefail

# Pin C locale so byte-class rules and collation are identical on every runner.
export LC_ALL=C

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT" || exit 0

LAWS=()
_i=0
while IFS= read -r _f; do
  [ -n "$_f" ] || continue
  LAWS[_i]=$_f
  _i=$((_i + 1))
done <<EOF
$(find laws -maxdepth 1 -name '*.md' ! -name 'INDEX.md' | sort)
EOF
N=${#LAWS[@]}

hdr() { printf '\n== %s ==\n' "$1"; }
sig() { printf '  ? %s\n' "$1"; }
inf() { printf '    %s\n' "$1"; }

printf 'corpus audit — advisory signals, no verdicts (v%s, %s laws)\n' "$(cat VERSION)" "$N"

# --- size distribution --------------------------------------------------------
hdr "size distribution"
TOTAL=$(cat "${LAWS[@]}" | wc -l | tr -d ' ')
inf "$N laws, $TOTAL lines total, $((TOTAL / N)) lines mean"
inf "always-on: core/ALWAYS.md $(wc -l < core/ALWAYS.md | tr -d ' ') lines"
printf '  largest:\n'
wc -l "${LAWS[@]}" | sort -rn | grep -v total | head -3 | sed 's/^/    /'
for f in "${LAWS[@]}"; do
  n=$(wc -l < "$f" | tr -d ' ')
  [ "$n" -gt 70 ] && sig "$f is $n lines — is it two laws? (MAINTENANCE.md §4 merge/split)"
done

# --- routing usability --------------------------------------------------------
hdr "routing usability"
ROWS=$(grep -cE '^\| .* \| `agent-laws/laws/' core/ALWAYS.md)
inf "$ROWS routable rows in the load table"
[ "$ROWS" -gt 40 ] && sig "load table has $ROWS rows — routing degrades with length; consider merging laws (§4)"
DUP_TRIGGER=$(grep -oE '^\| [^|]+ \|' core/ALWAYS.md | sort | uniq -d)
[ -n "$DUP_TRIGGER" ] && sig "two rows share a trigger phrase — an agent cannot route deterministically:" && printf '%s\n' "$DUP_TRIGGER" | sed 's/^/      /'

# --- overlap signal -----------------------------------------------------------
hdr "possible overlap (shared distinctive vocabulary)"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
for f in "${LAWS[@]}"; do
  id=$(basename "$f" .md)
  tr '[:upper:]' '[:lower:]' < "$f" | grep -oE '[a-z][a-z-]{6,}' | sort -u > "$tmp/$id"
done
found=0
for a in "$tmp"/*; do
  for b in "$tmp"/*; do
    [ "$a" \< "$b" ] || continue
    shared=$(comm -12 "$a" "$b" | wc -l | tr -d ' ')
    if [ "$shared" -gt 22 ]; then
      sig "$(basename "$a") ~ $(basename "$b") share $shared distinctive terms — do they own one contract? (§3 Q4)"
      found=1
    fi
  done
done
[ "$found" -eq 0 ] && inf "no pair exceeds the overlap threshold"

# --- vocabulary drift ---------------------------------------------------------
hdr "vocabulary drift (brand-shaped tokens)"
BRANDS=$(grep -ohE '\b[A-Z][a-z]+[A-Z][A-Za-z]+\b' "${LAWS[@]}" | sort | uniq -c | sort -rn)
if [ -n "$BRANDS" ]; then
  printf '%s\n' "$BRANDS" | head -8 | sed 's/^/    /'
  sig "confirm each is a generic mechanism, not a product name (constitution C4)"
else
  inf "no brand-shaped tokens found"
fi
LOWER=$(cat "${LAWS[@]}" | tr '[:upper:]' '[:lower:]' | grep -oE '\b[a-z]{3,}\b' | sort -u)
ACRONYM=$(for t in $(grep -ohE '\b[A-Z]{3,}\b' "${LAWS[@]}" | sort -u); do
            low=$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')
            printf '%s\n' "$LOWER" | grep -qx "$low" || printf '%s ' "$t"
          done)
if [ -n "$ACRONYM" ]; then
  sig "acronyms that appear only in upper case — will these read in another era?"
  inf "  $ACRONYM"
fi

# --- imperative density -------------------------------------------------------
# Density stored as path=pct lines (no declare -A — bash 4 only).
hdr "imperative density (share of prose lines carrying a directive)"
density_file=$tmp/density
: > "$density_file"
total_pct=0
for f in "${LAWS[@]}"; do
  prose=$(grep -cvE '^\s*$|^#|^---|^[a-z_]+:|^\|' "$f")
  [ "$prose" -gt 0 ] || continue
  imp=$(grep -cE '\b(MUST|NEVER|SHOULD|Never|Always|Do NOT|Prefer|Use|Keep|Fix|Add|Ship|Assert|Verify|Report|Stop|Wait|Delete|Avoid|Treat|Name|State|Include|Run|Read|Write|Reject|forbidden|required|do not|never|always|prefer)\b' "$f")
  pct=$((imp * 100 / prose))
  printf '%s\t%s\n' "$f" "$pct" >> "$density_file"
  total_pct=$((total_pct + pct))
done
MEAN=$((total_pct / N)); FLOOR=$((MEAN / 2))
inf "corpus mean ${MEAN}% — flagging outliers below ${FLOOR}%"
soft=0
for f in "${LAWS[@]}"; do
  pct=$(awk -F'\t' -v f="$f" '$1 == f { print $2; exit }' "$density_file")
  pct=${pct:-100}
  if [ "$pct" -lt "$FLOOR" ]; then
    sig "$f — ${pct}% directive, far below the corpus; is it still a law or now an essay?"
    soft=1
  fi
done
[ "$soft" -eq 0 ] && inf "no law is an outlier"

# --- structural decay ---------------------------------------------------------
hdr "structural decay"
orphan=0
for f in "${LAWS[@]}"; do
  id=$(basename "$f" .md)
  refs=$(grep -l "law \`$id\`" "${LAWS[@]}" 2>/dev/null | grep -vc "^$f$")
  [ "$refs" -eq 0 ] && orphan=$((orphan + 1))
done
inf "$orphan of $N laws are referenced by no sibling law (isolation is fine; clustering is the signal)"
inf "$(grep -c 'TODO' core/ALWAYS.md) TODO markers in the project-context stub (expected: the stub itself)"

# --- provenance ---------------------------------------------------------------
hdr "provenance"
if grep -qE '^## \[Unreleased\]' CHANGELOG.md; then
  pending=$(awk '/^## \[Unreleased\]/{f=1;next} /^## \[/{f=0} f' CHANGELOG.md | grep -c '^- ')
  inf "$pending unreleased entries recorded"
fi
inf "declared gate rules: $(grep -c 'case_ [a-z-]* ' scripts/selftest-gate.sh) red-cases in the self-test"

printf '\naudit-corpus: advisory only — nothing here blocks a release.\n'
printf 'Act on a signal only after applying the admission or retirement test in MAINTENANCE.md.\n'
exit 0
