#!/usr/bin/env bash
# selftest-gate.sh — proves that scripts/check-laws.sh actually fires.
#
# A green gate is consistent with two worlds: a correct gate, and a gate that never fails.
# This script separates them. For every rule declared in check-laws.sh it:
#   1. copies the repository to a scratch directory,
#   2. injects exactly one violation of that rule,
#   3. asserts the gate exits non-zero AND reports that specific rule id (red-case),
# and once, on an unmutated copy:
#   4. asserts the gate passes (over-match twin — the rules must not fire on clean input).
#
# A rule whose red-case does not fire is a rule that does not exist. Deleting a rule from
# check-laws.sh without deleting its case here is caught by the selftest-coverage rule;
# deleting both is a constitutional amendment and must be recorded in CHANGELOG.md.
#
# Exit 0 = every rule proven live. Exit 1 = at least one rule is dead or over-matching.
#
# Usage: scripts/selftest-gate.sh [--keep]   (--keep leaves scratch copies for inspection)

set -uo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

WORK=$(mktemp -d "${TMPDIR:-/tmp}/law-selftest.XXXXXX") || exit 1
trap '[ "$KEEP" -eq 1 ] || rm -rf "$WORK"' EXIT

PASSED=0
FAILED=0

# Copy the repository into a scratch subject, preserving the CLAUDE.md symlink.
subject() {
  local dir="$WORK/$1"
  rm -rf "$dir"; mkdir -p "$dir"
  ( cd "$ROOT" && tar -cf - \
      --exclude='./.git' --exclude='./dist' . ) | ( cd "$dir" && tar -xf - )
  printf '%s' "$dir"
}

# case <rule-id> <description> -- <mutation shell code>
# The mutation runs with the scratch copy as the working directory.
case_() {
  local rule=$1 desc=$2 mutation=$3
  local dir; dir=$(subject "$rule")
  ( cd "$dir" && eval "$mutation" ) >/dev/null 2>&1
  local out rc
  out=$(cd "$dir" && bash scripts/check-laws.sh 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '  DEAD RULE  [%s] gate passed despite: %s\n' "$rule" "$desc"; FAILED=$((FAILED + 1)); return
  fi
  if ! grep -qF "FAIL [$rule]" <<< "$out"; then
    printf '  MISFIRE    [%s] gate failed but did not report this rule: %s\n' "$rule" "$desc"
    printf '%s\n' "$out" | grep 'FAIL \[' | sed 's/^/               /'
    FAILED=$((FAILED + 1)); return
  fi
  printf '  red-case   [%s] %s\n' "$rule" "$desc"; PASSED=$((PASSED + 1))
}

printf 'gate self-test — every rule must fire on its own violation\n\n'

# --- over-match twin: the gate must not fire on a clean corpus ----------------
CLEAN=$(subject clean)
if (cd "$CLEAN" && bash scripts/check-laws.sh >/dev/null 2>&1); then
  printf '  twin       [all] clean corpus passes — no rule over-matches\n'; PASSED=$((PASSED + 1))
else
  printf '  OVER-MATCH [all] clean corpus FAILS the gate:\n'
  (cd "$CLEAN" && bash scripts/check-laws.sh 2>&1 | grep 'FAIL \[' | sed 's/^/               /')
  FAILED=$((FAILED + 1))
fi

# --- red-cases, one per declared rule -----------------------------------------
case_ index-path-resolves "a law listed in the index is deleted" \
  'rm laws/kiss-tests.md'

case_ law-indexed "a law exists but is absent from the index" \
  'grep -v "kiss-tests" laws/INDEX.md > i && mv i laws/INDEX.md'

case_ front-matter-id "a front-matter id stops matching its filename" \
  'sed -i "s/^id: debugging$/id: debuging/" laws/debugging.md'

case_ law-has-title "a law loses its H1 title" \
  'grep -v "^# Debugging discipline" laws/debugging.md > l && mv l laws/debugging.md'

case_ duplicate-title "two laws claim the same title" \
  'sed -i "s/^title: .*/title: Debugging discipline/" laws/io-boundary.md'

case_ law-size "a law is truncated to a stub" \
  'head -6 laws/debugging.md > l && mv l laws/debugging.md'

case_ lazy-load-complete "a law becomes unroutable from the load table" \
  'grep -v "agent-laws/laws/kiss-tests.md" core/ALWAYS.md > c && mv c core/ALWAYS.md'

case_ lazy-load-resolves "the load table points at a law that does not exist" \
  'sed -i "s#agent-laws/laws/debugging.md#agent-laws/laws/debugging-v2.md#" core/ALWAYS.md'

case_ xref-resolves "a law cites a sibling law that does not exist" \
  'printf "\nSee law \`ghost-law\`.\n" >> laws/debugging.md'

case_ location-coupling "a law hardcodes a file path instead of a law id" \
  'printf "\nSee \`laws/git-safety.md\` for detail.\n" >> laws/debugging.md'

case_ always-on-size "the always-on file grows past its budget" \
  'for i in $(seq 1 260); do echo "- filler line"; done >> core/ALWAYS.md'

case_ banned-coupling "a machine-local path enters the corpus" \
  'printf "\nSee /home/someone/notes.txt for detail.\n" >> laws/debugging.md'

case_ temporal-coupling "a law is dated to a specific year" \
  'printf "\nThis reflects practice as of 2031.\n" >> laws/debugging.md'

case_ url-in-law "a law depends on a URL that can rot" \
  'printf "\nSee https://example.invalid/spec for detail.\n" >> laws/debugging.md'

case_ claude-pointer "the compatibility file becomes a copy instead of a pointer" \
  'rm -f CLAUDE.md && cp AGENTS.md CLAUDE.md'

# --- result -------------------------------------------------------------------
printf '\n'
if [ "$FAILED" -eq 0 ]; then
  printf 'selftest-gate: PASS — %s checks, every declared rule fires and none over-match\n' "$PASSED"
  exit 0
fi
printf 'selftest-gate: FAIL — %s dead or over-matching rule(s), %s healthy\n' "$FAILED" "$PASSED"
exit 1
