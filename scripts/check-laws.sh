#!/usr/bin/env bash
# check-laws.sh — the blocking quality gate for the law corpus.
#
# Exit 0 = corpus is releasable. Exit 1 = at least one rule failed. Exit 2 = the gate
# could not run (missing repository structure). The gate FAILS CLOSED: an error inside
# a rule is a failure, never a pass.
#
# Machine-readable output. Every finding is one line:
#     FAIL [<rule-id>] <location> — <reason>
# Every satisfied rule prints:
#     ok   [<rule-id>] <summary>
# Parse on the bracketed rule id, never on prose.
#
# Every rule declared in GATE_RULES must have a red-case in scripts/selftest-gate.sh.
# That coverage is itself a rule (selftest-coverage), so a rule cannot be deleted from
# this gate without the deletion becoming visible. Run both:
#     scripts/check-laws.sh && scripts/selftest-gate.sh
#
# Dependencies: bash, POSIX coreutils, grep, sed, awk. No network. No package manager.

set -uo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT" || exit 2
[ -d laws ] && [ -f core/ALWAYS.md ] || { echo "FAIL [structure] repository layout not found" >&2; exit 2; }

# --- rule registry ------------------------------------------------------------
# Every id here MUST have a red-case in scripts/selftest-gate.sh, except those listed
# in GATE_RULES_META (rules that verify the gate itself and cannot self-mutate).
GATE_RULES=(
  index-path-resolves law-indexed front-matter-id law-has-title duplicate-title
  law-size lazy-load-complete lazy-load-resolves xref-resolves location-coupling
  always-on-size banned-coupling temporal-coupling url-in-law claude-pointer
  selftest-coverage
)
GATE_RULES_META=(selftest-coverage)

MAX_ALWAYS_LINES=250
MIN_LAW_LINES=12
MAX_LAW_LINES=90

FAILURES=0
SECTION_MARK=0

fail()    { printf '  FAIL [%s] %s\n' "$1" "$2"; FAILURES=$((FAILURES + 1)); }
ok()      { printf '  ok   [%s] %s\n' "$1" "$2"; }
section() { printf '\n%s\n' "$1"; SECTION_MARK=$FAILURES; }
# A green summary may never sit beside a red finding in the same section.
summary() { [ "$FAILURES" -eq "$SECTION_MARK" ] && ok "$1" "$2"; return 0; }

# Distributed corpus: the files a consumer installs. These must stay hermetic and
# vendor-neutral. README.md, INSTALL.md, MAINTENANCE.md, CHANGELOG.md and scripts/ are
# excluded by design — they must be able to NAME what is out of scope in order to forbid it.
mapfile -t CORPUS < <(
  find laws core templates adapters -type f \( -name '*.md' -o -name '*.mdc' \) 2>/dev/null | sort
  printf 'AGENTS.md\n'
)
mapfile -t LAW_FILES < <(find laws -maxdepth 1 -name '*.md' ! -name 'INDEX.md' | sort)
LAW_COUNT=${#LAW_FILES[@]}

# --- 1. index integrity -------------------------------------------------------
section "index integrity"
INDEX_PATHS=$(grep -oE '`laws/[a-z0-9-]+\.md`' laws/INDEX.md | tr -d '`' | sort -u)
if [ -z "$INDEX_PATHS" ]; then
  fail index-path-resolves "laws/INDEX.md — lists no law paths"
else
  while IFS= read -r p; do
    [ -f "$p" ] || fail index-path-resolves "laws/INDEX.md — indexed path does not exist: $p"
  done <<< "$INDEX_PATHS"
  summary index-path-resolves "$(wc -l <<< "$INDEX_PATHS" | tr -d ' ') indexed paths resolve"
fi

for f in "${LAW_FILES[@]}"; do
  base=${f#laws/}; id=${base%.md}
  grep -qF "\`laws/$base\`" laws/INDEX.md || fail law-indexed "$f — not listed in laws/INDEX.md"
  grep -qF "\`$id\`" laws/INDEX.md        || fail law-indexed "$f — id not listed in laws/INDEX.md"
done
summary law-indexed "$LAW_COUNT laws present in the index"

# --- 2. law file integrity ----------------------------------------------------
section "law files"
TITLES=""
for f in "${LAW_FILES[@]}"; do
  id=$(basename "$f" .md)
  front_id=$(awk 'NR==1&&$0=="---"{i=1;next} i&&/^id:/{print $2;exit} i&&$0=="---"{exit}' "$f")
  if [ -z "$front_id" ]; then
    fail front-matter-id "$f — missing front-matter id"
  elif [ "$front_id" != "$id" ]; then
    fail front-matter-id "$f — front-matter id '$front_id' does not match filename '$id'"
  fi

  grep -qE '^# .' "$f" || fail law-has-title "$f — no H1 title"

  t=$(awk 'NR==1&&$0=="---"{i=1;next} i&&/^title:/{sub(/^title:[[:space:]]*/,"");print;exit} i&&$0=="---"{exit}' "$f")
  [ -n "$t" ] && TITLES="$TITLES$t"$'\n'

  n=$(wc -l < "$f" | tr -d ' ')
  if [ "$n" -lt "$MIN_LAW_LINES" ]; then
    fail law-size "$f — $n lines, below the $MIN_LAW_LINES-line floor (a stub is not a law)"
  elif [ "$n" -gt "$MAX_LAW_LINES" ]; then
    fail law-size "$f — $n lines, over the $MAX_LAW_LINES-line ceiling (split it, do not dilute)"
  fi
done
summary front-matter-id "$LAW_COUNT front-matter ids match their filenames"
summary law-has-title "$LAW_COUNT laws carry an H1 title"
summary law-size "$LAW_COUNT laws within $MIN_LAW_LINES–$MAX_LAW_LINES lines"

DUPES=$(printf '%s' "$TITLES" | sort | uniq -d)
if [ -n "$DUPES" ]; then
  while IFS= read -r d; do
    [ -n "$d" ] && fail duplicate-title "laws/ — two laws share the title: $d"
  done <<< "$DUPES"
else
  ok duplicate-title "all law titles are distinct"
fi

# --- 3. lazy-load table -------------------------------------------------------
section "lazy-load table"
TABLE_IDS=$(grep -oE 'agent-laws/laws/[a-z0-9-]+\.md' core/ALWAYS.md | sed 's#.*/##; s#\.md$##' | sort -u)
for f in "${LAW_FILES[@]}"; do
  id=$(basename "$f" .md)
  grep -qx "$id" <<< "$TABLE_IDS" || fail lazy-load-complete "core/ALWAYS.md — law not routable, missing from the load table: $id"
done
summary lazy-load-complete "$LAW_COUNT laws routable from core/ALWAYS.md"

while IFS= read -r id; do
  [ -n "$id" ] || continue
  [ -f "laws/$id.md" ] || fail lazy-load-resolves "core/ALWAYS.md — load table points at a non-existent law: $id"
done <<< "$TABLE_IDS"
summary lazy-load-resolves "$(wc -l <<< "$TABLE_IDS" | tr -d ' ') load-table rows resolve"

# --- 4. cross-references and location independence ----------------------------
# Laws reference each other by stable id, never by path or filename: the corpus must
# survive being installed under any directory layout.
section "cross-references"
for f in "${LAW_FILES[@]}"; do
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    [ -f "laws/$id.md" ] || fail xref-resolves "$f — references a law that does not exist: $id"
  done < <(grep -ohE 'law `[a-z0-9-]+`' "$f" | sed 's/law `//; s/`//' | sort -u)

  # Forbid referring to a SIBLING LAW by path or filename — that breaks the moment the
  # corpus is installed under a different layout. Naming the canonical instruction files
  # (AGENTS.md, CLAUDE.md) is legitimate: they are the standard's own contract, and law
  # `rule-authoring` must be able to say where a rule belongs.
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    ref=$(sed 's/^[0-9]*://' <<< "$hit")
    stem=$(basename "$ref" .md)
    if [[ "$ref" == *laws/* ]] || [ -f "laws/$stem.md" ]; then
      fail location-coupling "$f:${hit%%:*} — reference a law by id, not by path or filename: $ref"
    fi
  done < <(grep -noE '`[A-Za-z0-9._/-]+\.(md|mdc)`' "$f" | tr -d '`')
done
summary xref-resolves "all law-to-law references resolve"
summary location-coupling "no law hardcodes a file path"

# --- 5. always-on size budget -------------------------------------------------
section "always-on size budget (<= $MAX_ALWAYS_LINES lines)"
for f in core/ALWAYS.md AGENTS.md; do
  [ -f "$f" ] || { fail always-on-size "$f — missing"; continue; }
  [ -L "$f" ] && continue
  n=$(wc -l < "$f" | tr -d ' ')
  [ "$n" -gt "$MAX_ALWAYS_LINES" ] && fail always-on-size "$f — $n lines (budget $MAX_ALWAYS_LINES)"
done
summary always-on-size "always-on files within budget ($(wc -l < core/ALWAYS.md | tr -d ' ') / $(wc -l < AGENTS.md | tr -d ' ') lines)"

# --- 6. hermeticity of the distributed corpus ---------------------------------
# Category patterns, never a curated list of product names: a denylist of vendors would
# itself be the name-keyed short blanket that law `attack-root-class` forbids.
section "hermeticity"
BANNED_COUPLING=(
  'GEMINI\.md@@a tool-specific instruction file that is out of scope'
  '[Ff]irecrawl@@a named crawl or search vendor'
  'ai-memory@@a named memory product'
  '/home/@@a machine-local absolute path'
  '/Users/@@a machine-local absolute path'
  'C:\\\\Users@@a machine-local absolute path'
  '~/@@a per-user home path'
  '^Co-[Aa]uthored-[Bb]y:@@an agent co-author trailer example'
)
for entry in "${BANNED_COUPLING[@]}"; do
  pattern=${entry%%@@*}; reason=${entry#*@@}
  for f in "${CORPUS[@]}"; do
    [ -f "$f" ] || continue
    while IFS= read -r hit; do
      [ -n "$hit" ] && fail banned-coupling "$f:${hit%%:*} — $reason"
    done < <(grep -nE "$pattern" "$f")
  done
done
summary banned-coupling "${#CORPUS[@]} corpus files free of environment coupling"

# Temporal coupling: anything that dates the corpus. Laws outlive the vocabulary of the
# decade that produced them. Relative deixis ("now", "prior", "next") is legitimate and
# is deliberately not matched.
TEMPORAL=(
  '\b(19|20)[0-9]{2}\b@@an absolute year'
  '\bv?[0-9]+\.[0-9]+\.[0-9]+\b@@a version literal'
  '\bnowadays\b@@dated phrasing'
  '\bcurrently\b@@dated phrasing'
  '\bthese days\b@@dated phrasing'
  '\bat the time of writing\b@@dated phrasing'
  '\bstate[ -]of[ -]the[ -]art\b@@dated phrasing'
  '\bcutting[ -]edge\b@@dated phrasing'
  '\bmodern\b@@dated phrasing — name the property, not the era'
  '\b(this|last|next) year\b@@dated phrasing'
)
for entry in "${TEMPORAL[@]}"; do
  pattern=${entry%%@@*}; reason=${entry#*@@}
  for f in "${CORPUS[@]}"; do
    [ -f "$f" ] || continue
    while IFS= read -r hit; do
      [ -n "$hit" ] && fail temporal-coupling "$f:${hit%%:*} — $reason"
    done < <(grep -niE "$pattern" "$f")
  done
done
summary temporal-coupling "${#CORPUS[@]} corpus files free of temporal coupling"

# Links rot. A law that depends on a reachable URL stops working the day that host dies.
for f in "${LAW_FILES[@]}"; do
  while IFS= read -r hit; do
    [ -n "$hit" ] && fail url-in-law "$f:${hit%%:*} — laws must be self-contained; no URLs"
  done < <(grep -nE 'https?://' "$f")
done
summary url-in-law "$LAW_COUNT laws are self-contained"

# --- 7. compatibility layer stays a pointer -----------------------------------
section "compatibility layer"
if [ -L CLAUDE.md ]; then
  ok claude-pointer "CLAUDE.md is a symlink -> $(readlink CLAUDE.md)"
elif [ -f CLAUDE.md ]; then
  if head -n 1 CLAUDE.md | grep -qE '^@AGENTS\.md[[:space:]]*$'; then
    n=$(wc -l < CLAUDE.md | tr -d ' ')
    if [ "$n" -le 20 ]; then ok claude-pointer "CLAUDE.md imports AGENTS.md ($n lines)"
    else fail claude-pointer "CLAUDE.md — $n lines; it must be a pointer, not a copy"; fi
  else
    fail claude-pointer "CLAUDE.md — neither a symlink nor a leading @AGENTS.md import"
  fi
else
  fail claude-pointer "CLAUDE.md — missing"
fi

# --- 8. the gate cannot be silently weakened ----------------------------------
section "gate self-coverage"
SELFTEST=scripts/selftest-gate.sh
if [ ! -f "$SELFTEST" ]; then
  fail selftest-coverage "$SELFTEST — missing; the gate has no red-cases and proves nothing"
else
  uncovered=0
  for rule in "${GATE_RULES[@]}"; do
    case " ${GATE_RULES_META[*]} " in *" $rule "*) continue ;; esac
    grep -qF "case_ $rule " "$SELFTEST" || { fail selftest-coverage "$SELFTEST — no red-case for rule: $rule"; uncovered=1; }
  done
  [ "$uncovered" -eq 0 ] && ok selftest-coverage "${#GATE_RULES[@]} rules declared, all non-meta rules have a red-case"
fi

# --- result -------------------------------------------------------------------
printf '\n'
if [ "$FAILURES" -eq 0 ]; then
  printf 'check-laws: PASS — %s laws, %s rules, corpus v%s\n' "$LAW_COUNT" "${#GATE_RULES[@]}" "$(cat VERSION)"
  exit 0
fi
printf 'check-laws: FAIL — %s finding(s)\n' "$FAILURES"
exit 1
