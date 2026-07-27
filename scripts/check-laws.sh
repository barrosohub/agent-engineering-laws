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
# Every rule declared in GATE_RULES must have a red-case in scripts/selftest-gate.sh, and
# case-rules-registered checks the inverse direction. That coverage is itself a rule
# (selftest-coverage), so a rule cannot be deleted from this gate without the deletion
# becoming visible. Run both:
#     scripts/check-laws.sh && scripts/selftest-gate.sh
#
# Dependencies: bash, POSIX coreutils, grep, sed, awk. No network. No package manager.

set -uo pipefail

# Pin C locale so byte-class rules and collation are identical on every runner.
export LC_ALL=C

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT" || exit 2

# --- rule registry ------------------------------------------------------------
# Every id here MUST have a red-case in scripts/selftest-gate.sh, except those listed
# in GATE_RULES_META (rules that verify the gate itself and cannot self-mutate).
# `structure` names the FAIL [structure] early-exit guards (args, layout, unknown
# --rule). They cannot be injected via a normal case_ mutation of the corpus, so they
# sit in META like selftest-coverage — visible to the registry, not invisible plumbing.
# `filter-rule-evaluated` is the RULE_TOUCHED guard: a filtered run that never calls
# ok/fail for the selected rule. It is not META; its red-case deletes its section.
GATE_RULES=(
  index-path-resolves law-indexed front-matter-id law-has-title duplicate-title
  law-size lazy-load-complete lazy-load-resolves xref-resolves location-coupling
  always-on-size banned-coupling temporal-coupling url-in-law claude-pointer
  selftest-coverage case-rules-registered structure filter-rule-evaluated
  llms-txt-complete law-count-consistent rule-count-consistent changelog-version-bound
  no-placeholder-coordinates posix-shell-purity
  readme-groups-complete english-only product-tier-inert unbraced-nonascii
)
GATE_RULES_META=(selftest-coverage structure)

# Optional single-rule execution. Validate before shared corpus setup so a typo can
# never look like a clean filtered run.
ONLY_RULE=
case "${1:-}" in
  --rule)
    if [ "$#" -lt 2 ]; then
      printf 'FAIL [structure] --rule requires a rule id\n' >&2
      exit 2
    fi
    ONLY_RULE=$2
    shift 2
    ;;
  "")
    ;;
  *)
    printf 'FAIL [structure] unknown argument: %s\n' "$1" >&2
    exit 2
    ;;
esac
if [ "$#" -ne 0 ]; then
  printf 'FAIL [structure] unexpected argument: %s\n' "$1" >&2
  exit 2
fi
if [ -n "$ONLY_RULE" ]; then
  _rule_registered=0
  for _rule in "${GATE_RULES[@]}"; do
    [ "$_rule" = "$ONLY_RULE" ] && _rule_registered=1
  done
  if [ "$_rule_registered" -eq 0 ]; then
    printf 'FAIL [structure] unknown rule: %s — not in GATE_RULES\n' "$ONLY_RULE" >&2
    exit 2
  fi
fi
[ -d laws ] && [ -f core/ALWAYS.md ] || { echo "FAIL [structure] repository layout not found" >&2; exit 2; }

MAX_ALWAYS_LINES=250
MIN_LAW_LINES=12
MAX_LAW_LINES=90

FAILURES=0
SECTION_MARK=0
RULE_TOUCHED=0

rule_wanted() { [ -z "$ONLY_RULE" ] || [ "$ONLY_RULE" = "$1" ]; }
section_wanted() {
  [ -z "$ONLY_RULE" ] && return 0
  local _candidate
  for _candidate in "$@"; do
    rule_wanted "$_candidate" && return 0
  done
  return 1
}
fail() {
  if [ -n "$ONLY_RULE" ] && [ "$1" != "$ONLY_RULE" ]; then return 0; fi
  RULE_TOUCHED=1
  printf '  FAIL [%s] %s\n' "$1" "$2"
  FAILURES=$((FAILURES + 1))
}
ok() {
  if [ -n "$ONLY_RULE" ] && [ "$1" != "$ONLY_RULE" ]; then return 0; fi
  RULE_TOUCHED=1
  printf '  ok   [%s] %s\n' "$1" "$2"
}
section() { printf '\n%s\n' "$1"; SECTION_MARK=$FAILURES; }
# A green summary may never sit beside a red finding in the same section.
summary() {
  if [ -n "$ONLY_RULE" ] && [ "$1" != "$ONLY_RULE" ]; then return 0; fi
  [ "$FAILURES" -eq "$SECTION_MARK" ] && ok "$1" "$2"
  return 0
}

# Distributed corpus: the files a consumer installs. These must stay hermetic and
# vendor-neutral. README.md, INSTALL.md, MAINTENANCE.md, CHANGELOG.md and scripts/ are
# excluded by design — they must be able to NAME what is out of scope in order to forbid it.
# Portable load (bash 3.2): no mapfile.
CORPUS=()
_i=0
while IFS= read -r _f; do
  [ -n "$_f" ] || continue
  CORPUS[_i]=$_f
  _i=$((_i + 1))
done <<EOF
$(find laws core templates adapters -type f \( -name '*.md' -o -name '*.mdc' \) 2>/dev/null | sort)
AGENTS.md
EOF
LAW_FILES=()
_i=0
while IFS= read -r _f; do
  [ -n "$_f" ] || continue
  LAW_FILES[_i]=$_f
  _i=$((_i + 1))
done <<EOF
$(find laws -maxdepth 1 -name '*.md' ! -name 'INDEX.md' | sort)
EOF
LAW_COUNT=${#LAW_FILES[@]}

# --- 1. index integrity -------------------------------------------------------
if section_wanted index-path-resolves law-indexed; then
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
fi

# --- 2. law file integrity ----------------------------------------------------
if section_wanted front-matter-id law-has-title law-size duplicate-title; then
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
summary law-size "$LAW_COUNT laws within ${MIN_LAW_LINES}–${MAX_LAW_LINES} lines"

DUPES=$(printf '%s' "$TITLES" | sort | uniq -d)
if [ -n "$DUPES" ]; then
  while IFS= read -r d; do
    [ -n "$d" ] && fail duplicate-title "laws/ — two laws share the title: $d"
  done <<< "$DUPES"
else
  ok duplicate-title "all law titles are distinct"
fi
fi

# --- 3. lazy-load table -------------------------------------------------------
if section_wanted lazy-load-complete lazy-load-resolves; then
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
fi

# --- 4. cross-references and location independence ----------------------------
# Laws reference each other by stable id, never by path or filename: the corpus must
# survive being installed under any directory layout.
if section_wanted xref-resolves location-coupling; then
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
fi

# --- 5. always-on size budget -------------------------------------------------
if section_wanted always-on-size; then
section "always-on size budget (<= $MAX_ALWAYS_LINES lines)"
for f in core/ALWAYS.md AGENTS.md; do
  [ -f "$f" ] || { fail always-on-size "$f — missing"; continue; }
  [ -L "$f" ] && continue
  n=$(wc -l < "$f" | tr -d ' ')
  [ "$n" -gt "$MAX_ALWAYS_LINES" ] && fail always-on-size "$f — $n lines (budget $MAX_ALWAYS_LINES)"
done
summary always-on-size "always-on files within budget ($(wc -l < core/ALWAYS.md | tr -d ' ') / $(wc -l < AGENTS.md | tr -d ' ') lines)"
fi

# --- 6. hermeticity of the distributed corpus ---------------------------------
# Category patterns, never a curated list of product names: a denylist of vendors would
# itself be the name-keyed short blanket that law `attack-root-class` forbids.
if section_wanted banned-coupling temporal-coupling url-in-law; then
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
fi

# --- 7. compatibility layer stays a pointer -----------------------------------
if section_wanted claude-pointer; then
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
fi

# --- 8. the gate cannot be silently weakened ----------------------------------
if section_wanted selftest-coverage case-rules-registered; then
section "gate self-coverage"
SELFTEST=scripts/selftest-gate.sh
if [ ! -f "$SELFTEST" ]; then
  fail selftest-coverage "$SELFTEST — missing; the gate has no red-cases and proves nothing"
  fail case-rules-registered "$SELFTEST — missing; cannot validate case rule names"
else
  uncovered=0
  for rule in "${GATE_RULES[@]}"; do
    case " ${GATE_RULES_META[*]} " in *" $rule "*) continue ;; esac
    grep -qF "case_ $rule " "$SELFTEST" || { fail selftest-coverage "$SELFTEST — no red-case for rule: $rule"; uncovered=1; }
  done
  [ "$uncovered" -eq 0 ] && ok selftest-coverage "${#GATE_RULES[@]} rules declared, all non-meta rules have a red-case"

  unknown_cases=0
  while IFS= read -r case_rule; do
    [ -n "$case_rule" ] || continue
    case_registered=0
    for declared_rule in "${GATE_RULES[@]}"; do
      [ "$declared_rule" = "$case_rule" ] && case_registered=1
    done
    if [ "$case_registered" -eq 0 ]; then
      fail case-rules-registered "$SELFTEST — case_ names a rule not in GATE_RULES: $case_rule"
      unknown_cases=1
    fi
  done <<EOF
$(awk '$1 == "case_" { print ($2 == "" ? "<missing>" : $2) }' "$SELFTEST")
EOF
  [ "$unknown_cases" -eq 0 ] && ok case-rules-registered "every real selftest case names a registered rule"
fi
fi

# --- 8b. filtered runs must evaluate the selected rule ------------------------
# Presence marker for the red-case: deleting this section while leaving the id in
# GATE_RULES makes --rule filter-rule-evaluated exit 2 via RULE_TOUCHED below.
if section_wanted filter-rule-evaluated; then
section "filter rule evaluation"
ok filter-rule-evaluated "a filtered run touches ok or fail for the selected rule"
fi

# --- 9. parallel routing surfaces stay bijective ------------------------------
# laws/INDEX.md is the source of truth. core/ALWAYS.md is guarded above.
# llms.txt is a third writer over the same set of ids — keep the bijection.
if section_wanted llms-txt-complete; then
section "llms.txt routing completeness"
if [ ! -f llms.txt ]; then
  fail llms-txt-complete "llms.txt — missing"
else
  # Law entries look like: - [id](…/laws/id.md): … — not the INDEX/entry-point links.
  LLMS_IDS=$(grep -oE '\[[a-z0-9-]+\]\([^)]*/laws/[a-z0-9-]+\.md\)' llms.txt \
    | sed -E 's/^\[([a-z0-9-]+)\].*/\1/' | sort -u)
  for f in "${LAW_FILES[@]}"; do
    id=$(basename "$f" .md)
    grep -qx "$id" <<< "$LLMS_IDS" || fail llms-txt-complete "llms.txt — law not listed: $id"
  done
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    [ -f "laws/$id.md" ] || fail llms-txt-complete "llms.txt — points at a non-existent law: $id"
  done <<< "$LLMS_IDS"
  summary llms-txt-complete "$LAW_COUNT laws bijective with llms.txt"
fi
fi

# --- 10. live law-count literals stay honest ----------------------------------
# The count is hardcoded on four live surfaces. CHANGELOG.md is excluded: historical
# release notes correctly name past counts and must not be rewritten when the corpus grows.
if section_wanted law-count-consistent; then
section "law count consistency"
COUNT_SURFACES=(laws/INDEX.md README.md AGENTS.md llms.txt)
# Class: an integer asserted as the corpus size — a number, then at most four
# adjective tokens, then the word law/laws. Caps the gap so "60 lines… two laws"
# does not count, while "33 durable engineering laws" still does.
COUNT_NUM_THEN_LAWS='\b([0-9]+)([[:space:]]+[[:alpha:],-]{1,40}){0,4}[[:space:]]+laws?\b'
count_mismatches=0
for f in "${COUNT_SURFACES[@]}"; do
  [ -f "$f" ] || { fail law-count-consistent "$f — missing count surface"; continue; }
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    line=${hit%%:*}; text=${hit#*:}
    asserted=$(printf '%s\n' "$text" | grep -oE "$COUNT_NUM_THEN_LAWS" | head -1 | grep -oE '[0-9]+' | head -1)
    [ -n "$asserted" ] || continue
    if [ "$asserted" -ne "$LAW_COUNT" ]; then
      fail law-count-consistent "$f:$line — asserts $asserted laws; disk has $LAW_COUNT"
      count_mismatches=1
    fi
  done < <(grep -nE "$COUNT_NUM_THEN_LAWS" "$f")
done
[ "$count_mismatches" -eq 0 ] && summary law-count-consistent "live count literals equal disk ($LAW_COUNT)"
fi

# --- 10b. live rule-count literals match the registry -------------------------
# README.md and AGENTS.md assert the registered-rule count in prose. CHANGELOG.md
# is excluded: historical release notes correctly name past counts.
RULE_COUNT=${#GATE_RULES[@]}
if section_wanted rule-count-consistent; then
section "rule count consistency"
RULE_COUNT_SURFACES=(README.md AGENTS.md)
# Class: an integer asserted as the registry size — a number, then at most four
# adjective tokens, then the word rule/rules. Caps the gap so "step 4… a rule"
# and line-budget numbers do not count, while "28 registered rules" still does.
RULE_COUNT_NUM_THEN_RULES='\b([0-9]+)([[:space:]]+[[:alpha:],-]{1,40}){0,4}[[:space:]]+rules?\b'
rule_count_mismatches=0
for f in "${RULE_COUNT_SURFACES[@]}"; do
  [ -f "$f" ] || { fail rule-count-consistent "$f — missing count surface"; continue; }
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    line=${hit%%:*}; text=${hit#*:}
    asserted=$(printf '%s\n' "$text" | grep -oE "$RULE_COUNT_NUM_THEN_RULES" | head -1 | grep -oE '[0-9]+' | head -1)
    [ -n "$asserted" ] || continue
    if [ "$asserted" -ne "$RULE_COUNT" ]; then
      fail rule-count-consistent "$f:$line — asserts $asserted rules; registry has $RULE_COUNT"
      rule_count_mismatches=1
    fi
  done < <(grep -nE "$RULE_COUNT_NUM_THEN_RULES" "$f")
done
[ "$rule_count_mismatches" -eq 0 ] && summary rule-count-consistent "live rule-count literals equal registry ($RULE_COUNT)"
fi

# --- 10c. changelog version headings bound to VERSION ------------------------
# Pure in-tree: highest ## [X.Y.Z] heading equals VERSION; none may exceed it.
# Link definitions and prose version literals are out of scope (see twin).
if section_wanted changelog-version-bound; then
section "changelog version bound"
CHANGELOG=CHANGELOG.md
VERSION_FILE=VERSION
if [ ! -f "$CHANGELOG" ]; then
  fail changelog-version-bound "$CHANGELOG — missing"
elif [ ! -f "$VERSION_FILE" ]; then
  fail changelog-version-bound "$VERSION_FILE — missing"
else
  declared_version=$(tr -d '[:space:]' < "$VERSION_FILE")
  heading_versions=$(grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$CHANGELOG" \
    | sed -E 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/' || true)
  if [ -z "$heading_versions" ]; then
    fail changelog-version-bound "$CHANGELOG — no ## [X.Y.Z] version headings"
  else
    # Numeric field-by-field compare in POSIX awk. sort -V is GNU-only — BusyBox sort
    # lacks it and degrades to lexicographic silently, which would let 1.10.0 hide
    # below 1.9.0. Returns 0 when $1 is strictly greater than $2.
    ver_gt() {
      awk -v a="$1" -v b="$2" 'BEGIN {
        na = split(a, A, "."); nb = split(b, B, ".")
        n = (na > nb) ? na : nb
        for (i = 1; i <= n; i++) {
          x = (i <= na) ? A[i] + 0 : 0; y = (i <= nb) ? B[i] + 0 : 0
          if (x > y) exit 0
          if (x < y) exit 1
        }
        exit 1
      }'
    }
    bound_hits=0
    highest=
    while IFS= read -r hv; do
      [ -n "$hv" ] || continue
      if ver_gt "$hv" "$declared_version"; then
        fail changelog-version-bound "$CHANGELOG — heading [$hv] exceeds VERSION $declared_version"
        bound_hits=1
      fi
      if [ -z "$highest" ] || ver_gt "$hv" "$highest"; then
        highest=$hv
      fi
    done <<EOF
$heading_versions
EOF
    if [ "$bound_hits" -eq 0 ]; then
      if [ "$highest" != "$declared_version" ]; then
        fail changelog-version-bound "$CHANGELOG — highest heading [$highest] != VERSION $declared_version"
      else
        ok changelog-version-bound "highest heading equals VERSION ($declared_version)"
      fi
    fi
  fi
fi
fi

# --- 11. published coordinates are resolved -----------------------------------
# Closed class: the install-path placeholder. The needle is assembled at runtime with
# printf so the gate does not match itself; nothing is excluded on the gate's behalf.
if section_wanted no-placeholder-coordinates; then
section "published coordinates"
PLACEHOLDER=$(printf '%s/%s' OWNER REPO)
placeholder_hits=0
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  fail no-placeholder-coordinates "$hit — unresolved repository-coordinate placeholder"
  placeholder_hits=1
done < <(grep -rnF --exclude-dir=.git --exclude-dir=dist "$PLACEHOLDER" . 2>/dev/null || true)
[ "$placeholder_hits" -eq 0 ] && ok no-placeholder-coordinates "no unresolved install-path placeholder"
fi

# --- 12. tooling shell purity -------------------------------------------------
# Two floors, one rule id:
#   - Scripts whose shebang declares sh must be POSIX (no bashisms).
#   - Every script must stay on bash 3.2 + POSIX utilities (no bash-4-only, no GNU-only).
# The posix over-match twin proves POSIX-legal lookalikes stay silent; the tooling
# twin proves a documented/forbidden name inside a comment stays silent.
if section_wanted posix-shell-purity; then
section "tooling shell purity"
# Bashisms forbidden in sh scripts. Each alternative has a red-case.
POSIX_BASH_ONLY='\$\{[A-Za-z_][A-Za-z0-9_]*//|\[\[([^:]|$)|<<<|\+=\(|\bmapfile\b|\bdeclare -[aA]|\blocal -[aA]'
# Bash 4+ / GNU-only forbidden in EVERY script (tooling tier = bash 3.2 + POSIX).
# sed -i without a backup-suffix argument is GNU; BSD requires sed -i '' or sed -i.bak.
TOOLING_FORBIDDEN='\bmapfile\b|\breadarray\b|\bdeclare -A\b|\$\{[A-Za-z_][A-Za-z0-9_]*\^\^|\$\{[A-Za-z_][A-Za-z0-9_]*,,|\bglobstar\b|\bsed[[:space:]]+-i[[:space:]]+['\''"s/]|\breadlink[[:space:]]+-f\b|\bgrep[[:space:]]+-P\b|\bdate[[:space:]]+-d\b|\bstat[[:space:]]+-c\b'
posix_hits=0
for f in scripts/*.sh; do
  [ -f "$f" ] || continue
  shebang=$(head -n 1 "$f")
  case "$shebang" in
    '#!/usr/bin/env sh'|'#!/bin/sh')
      while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        text=${hit#*:}
        case "$text" in '#'*|[[:space:]]'#'*) continue ;; esac
        fail posix-shell-purity "$f:${hit%%:*} — bash-only construct in an sh script"
        posix_hits=1
      done <<EOF
$(grep -nE "$POSIX_BASH_ONLY" "$f" || true)
EOF
      ;;
  esac
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    text=${hit#*:}
    case "$text" in
      '#'*|[[:space:]]'#'*) continue ;;
      # Pattern registries and selftest case labels must name constructs to forbid them.
      *POSIX_BASH_ONLY=*|*TOOLING_FORBIDDEN=*) continue ;;
      case_\ *|twin_\ *) continue ;;
    esac
    fail posix-shell-purity "$f:${hit%%:*} — bash-4-only or GNU-only construct in tooling"
    posix_hits=1
  done <<EOF
$(grep -nE "$TOOLING_FORBIDDEN" "$f" || true)
EOF
done
[ "$posix_hits" -eq 0 ] && ok posix-shell-purity "tooling scripts stay on bash 3.2 + POSIX utilities"
fi

# --- 13. README group table stays bijective -----------------------------------
# Same second-writer failure class as llms.txt: the group table must list every law
# exactly once, and every listed id must resolve.
if section_wanted readme-groups-complete; then
section "README group table"
if [ ! -f README.md ]; then
  fail readme-groups-complete "README.md — missing"
else
  README_IDS=$(sed -n '/^## The laws$/,/^Full table/p' README.md \
    | grep -oE '`[a-z0-9-]+`' | tr -d '`' || true)
  README_SORTED=$(printf '%s\n' "$README_IDS" | sort)
  README_UNIQ=$(printf '%s\n' "$README_IDS" | sort -u)
  while IFS= read -r dup; do
    [ -n "$dup" ] || continue
    fail readme-groups-complete "README.md — law listed in more than one group: $dup"
  done <<EOF
$(printf '%s\n' "$README_SORTED" | uniq -d)
EOF
  for f in "${LAW_FILES[@]}"; do
    id=$(basename "$f" .md)
    printf '%s\n' "$README_UNIQ" | grep -qx "$id" \
      || fail readme-groups-complete "README.md — law not in the group table: $id"
  done
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    [ -f "laws/$id.md" ] || fail readme-groups-complete "README.md — group table points at a non-existent law: $id"
  done <<EOF
$README_UNIQ
EOF
  summary readme-groups-complete "$LAW_COUNT laws bijective with the README group table"
fi
fi

# --- 14. American English orthography -----------------------------------------
# Catches accented prose the moment it lands (non-ASCII letters). Does NOT catch
# unaccented non-English text — that stays a human-review concern. Do not oversell.
# Typographic characters already in corpus use are allowlisted explicitly:
#   — em dash (prose breaks)    – en dash (numeric ranges)
#   → arrow (flow)              ⇒ implication (ALWAYS.md)
#   … ellipsis                  · middle dot (README group separators)
#   § section sign (cross-refs) ≥ ≤ comparison
#   ─ │ └ ├ box-drawing (README layout diagram)
# Strip allowlisted UTF-8 byte sequences with sed, then detect leftover non-ASCII with
# grep under LC_ALL=C (bytes >= 0x80 are not [[:print:]]). No awk — mawk is not
# multi-byte aware and would make this a dead rule on Ubuntu runners.
if section_wanted english-only; then
section "english-only orthography"
english_hits=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  [ -L "$f" ] && continue
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    fail english-only "$f:$hit — non-ASCII letter; corpus is American English only"
    english_hits=1
  done <<EOF
$(LC_ALL=C sed \
  -e 's/—//g' -e 's/–//g' -e 's/→//g' -e 's/⇒//g' -e 's/…//g' \
  -e 's/·//g' -e 's/§//g' -e 's/≥//g' -e 's/≤//g' \
  -e 's/─//g' -e 's/│//g' -e 's/└//g' -e 's/├//g' \
  "$f" | LC_ALL=C grep -n '[^[:print:][:blank:]]' | sed 's/:.*//')
EOF
done <<EOF
$(find . -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.txt' -o -name '*.sh' -o -name '*.stub.md' \) \
  ! -path './.git/*' ! -path './dist/*' | sort)
EOF
[ "$english_hits" -eq 0 ] && ok english-only "no non-ASCII letters outside the typographic allowlist"
fi

# --- 15. unbraced expansion immediately before a non-ASCII byte ----------------
# Bash 3.2 absorbs a following non-ASCII byte into the parameter name (unbraced
# dollar-VAR then en-dash looks up a different name); bash 4+ stops at the first
# non-ASCII byte. Require braces before any non-ASCII so both agree.
# Detection is byte-exact under LC_ALL=C: map high bytes to ASCII at-signs, then
# find an unbraced dollar-IDENT immediately before an at-sign. Comment lines are
# skipped so documentation may name the construct.
if section_wanted unbraced-nonascii; then
section "unbraced expansion before non-ASCII"
unbraced_hits=0
for f in scripts/*.sh; do
  [ -f "$f" ] || continue
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    line=${hit%%:*}
    text=${hit#*:}
    trimmed=$(printf '%s\n' "$text" | sed 's/^[[:space:]]*//')
    case "$trimmed" in
      '#'*) continue ;;
      case_\ *|twin_\ *) continue ;;
    esac
    fail unbraced-nonascii "$f:$line — unbraced \$VAR immediately before a non-ASCII byte; write \${VAR}"
    unbraced_hits=1
  done <<EOF
$(LC_ALL=C tr '\200-\377' '@' < "$f" | LC_ALL=C grep -nE '\$[A-Za-z_][A-Za-z0-9_]*@' || true)
EOF
done
[ "$unbraced_hits" -eq 0 ] && ok unbraced-nonascii "no unbraced \$VAR sits before a non-ASCII byte"
fi

# --- 16. product tier stays inert ---------------------------------------------
# Contract is about what is COMMITTED, not what a particular filesystem reports.
# Read mode bits from git's index (identical on every platform):
#   100644 regular file, 100755 executable, 120000 symlink.
# git is a tooling-tier dependency for this rule (already required to obtain the repo).
if section_wanted product-tier-inert; then
section "product tier inert"
inert_hits=0
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail product-tier-inert "not a git work tree — this rule reads committed modes from the index"
  inert_hits=1
else
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    mode=${line%% *}
    path=$(printf '%s\n' "$line" | cut -f2-)
    [ -n "$path" ] || continue
    case "$mode" in
      120000)
        fail product-tier-inert "$path — product-tier path must not be a symlink (index mode 120000)"
        inert_hits=1
        ;;
      100755)
        fail product-tier-inert "$path — product-tier file must not be executable (index mode 100755)"
        inert_hits=1
        ;;
    esac
  done <<EOF
$(git ls-files -s -- core laws adapters templates llms.txt 2>/dev/null)
EOF
fi
[ "$inert_hits" -eq 0 ] && ok product-tier-inert "product tier index has no symlinks and no executable bits"
fi

# --- result -------------------------------------------------------------------
printf '\n'
# RULE_TOUCHED: sharpens diagnosis when a registered rule's evaluation section is
# missing under --rule. Without this guard the same defect still surfaces as DEAD RULE
# in the selftest; this exit names the wiring failure directly.
if [ -n "$ONLY_RULE" ] && [ "$RULE_TOUCHED" -eq 0 ]; then
  printf 'FAIL [filter-rule-evaluated] rule %s was not evaluated — filter wiring bug\n' "$ONLY_RULE" >&2
  exit 2
fi
if [ "$FAILURES" -eq 0 ]; then
  if [ -n "$ONLY_RULE" ]; then
    printf 'check-laws: PASS — rule [%s]\n' "$ONLY_RULE"
  else
    printf 'check-laws: PASS — %s laws, %s rules, corpus v%s\n' "$LAW_COUNT" "${#GATE_RULES[@]}" "$(cat VERSION)"
  fi
  exit 0
fi
if [ -n "$ONLY_RULE" ]; then
  printf 'check-laws: FAIL — rule [%s], %s finding(s)\n' "$ONLY_RULE" "$FAILURES"
else
  printf 'check-laws: FAIL — %s finding(s)\n' "$FAILURES"
fi
exit 1
