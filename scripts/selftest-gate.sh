#!/usr/bin/env bash
# selftest-gate.sh — proves that scripts/check-laws.sh actually fires.
#
# A green gate is consistent with two worlds: a correct gate, and a gate that never fails.
# This script separates them. For every rule declared in check-laws.sh it:
#   1. builds one subject template (tree + local git index) once per run,
#   2. copies that template into a unique scratch directory per case/twin,
#   3. injects exactly one violation of that rule,
#   4. asserts the mutation landed (fingerprint change), then
#   5. asserts the gate exits non-zero AND reports that specific rule id (red-case),
# and once, on an unmutated copy:
#   6. asserts the gate passes (over-match twin — the rules must not fire on clean input).
# Per-rule over-match twins (twin_) prove a specific rule stays silent on legitimate input
# that would trip a sloppy pattern.
#
# A rule whose red-case does not fire is a rule that does not exist. Deleting a rule from
# check-laws.sh without deleting its case here is caught by the selftest-coverage rule;
# deleting both is a constitutional amendment and must be recorded in CHANGELOG.md.
#
# "DEAD RULE" means the rule failed to fire on a mutation that DID land.
# "BROKEN CASE" means the mutation did not change the subject tree — the case is at fault.
#
# Exit 0 = every rule proven live. Exit 1 = at least one rule is dead, over-matching,
# or a case is broken.
#
# Usage: scripts/selftest-gate.sh [--keep]   (--keep leaves scratch copies for inspection)
# Targets: bash 3.2 + POSIX utilities (no mapfile, no declare -A, no GNU sed -i).

set -uo pipefail

# Pin C locale so byte-class rules and collation are identical on every runner.
export LC_ALL=C

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

WORK=$(mktemp -d "${TMPDIR:-/tmp}/law-selftest.XXXXXX") || exit 1

PASSED=0
FAILED=0
SUBJECT_SEQ=0
EXIT_CODE=1

# Manifest of the REAL repository (not a subject). One line per path so diffs name files.
repo_manifest() {
  ( cd "$ROOT" && find . \( -type f -o -type l \) ! -path './.git/*' ! -path './dist/*' | sort \
    | while IFS= read -r f; do
        if [ -L "$f" ]; then
          printf '%s\tL\t%s\n' "$f" "$(readlink "$f")"
        else
          mode=$(ls -l "$f" | awk '{ print $1 }')
          sum=$(cksum "$f")
          printf '%s\tF\t%s\t%s\n' "$f" "$mode" "$sum"
        fi
      done )
}

assert_repo_unchanged() {
  local after
  after=$(repo_manifest)
  if [ "$(printf '%s\n' "$REPO_BEFORE" | cksum)" = "$(printf '%s\n' "$after" | cksum)" ]; then
    return 0
  fi
  printf '  REPO MUTATED — real repository changed during selftest. Differing paths:\n' >&2
  printf '%s\n' "$REPO_BEFORE" > "$WORK/_repo_before"
  printf '%s\n' "$after" > "$WORK/_repo_after"
  # Name every path whose manifest line changed (or appeared/disappeared).
  awk -F'\t' 'FNR==NR { b[$1]=$0; next }
    {
      if (!($1 in b)) print "    + " $1
      else if (b[$1] != $0) print "    ~ " $1
      delete b[$1]
    }
    END { for (p in b) print "    - " p }
  ' "$WORK/_repo_before" "$WORK/_repo_after" >&2
  return 1
}

finish() {
  local guard_rc=0
  assert_repo_unchanged || guard_rc=1
  [ "$KEEP" -eq 1 ] || rm -rf "$WORK"
  if [ "$guard_rc" -ne 0 ]; then
    printf 'selftest-gate: FAIL — real repository mutated during the run\n' >&2
    exit 1
  fi
  exit "$EXIT_CODE"
}
trap finish EXIT

REPO_BEFORE=$(repo_manifest)

# Fingerprint a subject tree so we can prove a mutation landed.
# Includes symlink targets, permission bits, and the git index — index-only mode
# mutations (product-tier-inert) must count.
fingerprint() {
  local dir=$1
  (
    cd "$dir" && find . \( -type f -o -type l \) ! -path './.git/*' ! -path './dist/*' | sort \
      | while IFS= read -r f; do
          if [ -L "$f" ]; then
            printf 'L %s -> %s\n' "$f" "$(readlink "$f")"
          else
            printf 'F %s ' "$f"
            ls -l "$f" | awk '{ print $1 }'
            cksum "$f"
          fi
        done
    if [ -f .git/index ]; then
      printf 'INDEX '
      cksum .git/index
    fi
  ) | cksum
}

# Build the subject template ONCE: full tree plus a local git index so rules that
# read committed modes (product-tier-inert) can fire inside subjects.
TEMPLATE=
build_template() {
  TEMPLATE="$WORK/template"
  rm -rf "$TEMPLATE"
  mkdir -p "$TEMPLATE" || {
    printf '  BROKEN SUBJECT [template] mkdir failed\n' >&2
    exit 1
  }
  if ! ( cd "$ROOT" && tar -cf - \
      --exclude='./.git' --exclude='./dist' . ) | ( cd "$TEMPLATE" && tar -xf - ); then
    printf '  BROKEN SUBJECT [template] extraction failed\n' >&2
    exit 1
  fi
  if [ ! -f "$TEMPLATE/scripts/check-laws.sh" ] || [ ! -d "$TEMPLATE/laws" ]; then
    printf '  BROKEN SUBJECT [template] incomplete tree after extraction\n' >&2
    exit 1
  fi
  if ! (
    cd "$TEMPLATE" \
      && git init -q \
      && git add -A \
      && git -c user.name=selftest -c user.email=selftest@test commit -q -m template
  ); then
    printf '  BROKEN SUBJECT [template] git init/commit failed\n' >&2
    exit 1
  fi
}

# Copy the template into a UNIQUE scratch subject. Never reuse a path across cases.
# SUBJECT_SEQ makes every case_/twin_/clean call get its own directory; cp -a from
# TEMPLATE means case N never sees case N-1's mutations.
subject() {
  SUBJECT_SEQ=$((SUBJECT_SEQ + 1))
  local label=$1
  local dir="$WORK/${SUBJECT_SEQ}-${label}"
  rm -rf "$dir"
  if ! cp -a "$TEMPLATE" "$dir"; then
    printf '  BROKEN SUBJECT [%s] template copy failed\n' "$label" >&2
    exit 1
  fi
  if [ ! -f "$dir/scripts/check-laws.sh" ] || [ ! -d "$dir/laws" ]; then
    printf '  BROKEN SUBJECT [%s] incomplete tree after copy\n' "$label" >&2
    exit 1
  fi
  printf '%s' "$dir"
}

build_template


# Portable in-place sed for mutations (GNU and BSD).
# Usage inside a mutation: sed_inplace 's/foo/bar/' file
# (defined in the subject via a tiny helper written at case start — mutations use
#  `sed … > tmp && mv tmp file` inline instead).

# case <rule-id> <description> -- <mutation shell code>
case_() {
  local rule=$1 desc=$2 mutation=$3
  local dir before after mut_rc out rc
  dir=$(subject "$rule")
  before=$(fingerprint "$dir")
  ( cd "$dir" && eval "$mutation" ); mut_rc=$?
  after=$(fingerprint "$dir")
  if [ "$before" = "$after" ]; then
    printf '  BROKEN CASE [%s] mutation did not change the subject (exit %s): %s\n' \
      "$rule" "$mut_rc" "$desc"
    FAILED=$((FAILED + 1)); return
  fi
  if [ "$mut_rc" -ne 0 ]; then
    printf '  BROKEN CASE [%s] mutation exited %s after changing the tree: %s\n' \
      "$rule" "$mut_rc" "$desc"
    FAILED=$((FAILED + 1)); return
  fi
  out=$(cd "$dir" && bash scripts/check-laws.sh 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '  DEAD RULE  [%s] gate passed despite: %s\n' "$rule" "$desc"; FAILED=$((FAILED + 1)); return
  fi
  if ! printf '%s\n' "$out" | grep -qF "FAIL [$rule]"; then
    printf '  MISFIRE    [%s] gate failed but did not report this rule: %s\n' "$rule" "$desc"
    printf '%s\n' "$out" | grep 'FAIL \[' | sed 's/^/               /'
    FAILED=$((FAILED + 1)); return
  fi
  printf '  red-case   [%s] %s\n' "$rule" "$desc"; PASSED=$((PASSED + 1))
}

# twin <rule-id> <description> -- <mutation that must NOT make this rule fire>
twin_() {
  local rule=$1 desc=$2 mutation=$3
  local dir before after mut_rc out
  dir=$(subject "twin-$rule")
  before=$(fingerprint "$dir")
  ( cd "$dir" && eval "$mutation" ); mut_rc=$?
  after=$(fingerprint "$dir")
  if [ "$before" = "$after" ]; then
    printf '  BROKEN CASE [%s] twin mutation did not change the subject (exit %s): %s\n' \
      "$rule" "$mut_rc" "$desc"
    FAILED=$((FAILED + 1)); return
  fi
  out=$(cd "$dir" && bash scripts/check-laws.sh 2>&1) || true
  if printf '%s\n' "$out" | grep -qF "FAIL [$rule]"; then
    printf '  OVER-MATCH [%s] fired on legitimate input: %s\n' "$rule" "$desc"
    FAILED=$((FAILED + 1)); return
  fi
  printf '  twin       [%s] %s\n' "$rule" "$desc"; PASSED=$((PASSED + 1))
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
# Mutations use `sed … > tmp && mv tmp file` — portable across GNU and BSD sed.
case_ index-path-resolves "a law listed in the index is deleted" \
  'rm laws/kiss-tests.md'

case_ law-indexed "a law exists but is absent from the index" \
  'grep -v "kiss-tests" laws/INDEX.md > i && mv i laws/INDEX.md'

case_ front-matter-id "a front-matter id stops matching its filename" \
  'sed "s/^id: debugging$/id: debuging/" laws/debugging.md > t && mv t laws/debugging.md'

case_ law-has-title "a law loses its H1 title" \
  'grep -v "^# Debugging discipline" laws/debugging.md > l && mv l laws/debugging.md'

case_ duplicate-title "two laws claim the same title" \
  'sed "s/^title: .*/title: Debugging discipline/" laws/io-boundary.md > t && mv t laws/io-boundary.md'

case_ law-size "a law is truncated to a stub" \
  'head -6 laws/debugging.md > l && mv l laws/debugging.md'

case_ lazy-load-complete "a law becomes unroutable from the load table" \
  'grep -v "agent-laws/laws/kiss-tests.md" core/ALWAYS.md > c && mv c core/ALWAYS.md'

case_ lazy-load-resolves "the load table points at a law that does not exist" \
  'sed "s#agent-laws/laws/debugging.md#agent-laws/laws/debugging-v2.md#" core/ALWAYS.md > t && mv t core/ALWAYS.md'

case_ xref-resolves "a law cites a sibling law that does not exist" \
  'printf "\nSee law \`ghost-law\`.\n" >> laws/debugging.md'

case_ location-coupling "a law hardcodes a file path instead of a law id" \
  'printf "\nSee \`laws/git-safety.md\` for detail.\n" >> laws/debugging.md'

case_ always-on-size "the always-on file grows past its budget" \
  'i=0; while [ "$i" -lt 260 ]; do echo "- filler line"; i=$((i + 1)); done >> core/ALWAYS.md'

case_ banned-coupling "a machine-local path enters the corpus" \
  'printf "\nSee /home/someone/notes.txt for detail.\n" >> laws/debugging.md'

case_ temporal-coupling "a law is dated to a specific year" \
  'printf "\nThis reflects practice as of 2031.\n" >> laws/debugging.md'

case_ url-in-law "a law depends on a URL that can rot" \
  'printf "\nSee https://example.invalid/spec for detail.\n" >> laws/debugging.md'

case_ claude-pointer "the compatibility file becomes a copy instead of a pointer" \
  'rm -f CLAUDE.md && cp AGENTS.md CLAUDE.md'

case_ llms-txt-complete "a law becomes absent from llms.txt" \
  'grep -v "laws/kiss-tests.md" llms.txt > l && mv l llms.txt'

case_ law-count-consistent "a live count literal drifts from the disk count" \
  'n=$(ls laws/*.md | grep -cv INDEX); w=$((n - 1)); sed "s/\*\*$n laws\.\*\*/**$w laws.**/" laws/INDEX.md > t && mv t laws/INDEX.md'

twin_ law-count-consistent "non-count numbers beside the word law stay silent" \
  'printf "\nEach law stays roughly 20–60 lines; the always-on budget is 250 lines.\n" >> README.md'

case_ no-placeholder-coordinates "an install path still carries the coordinate placeholder" \
  'printf "\nSee https://github.com/%s\n" "$(printf "%s/%s" OWNER REPO)" >> scripts/install.sh'

# posix-shell-purity: sh bashisms + tooling bash-4/GNU constructs.
# Forbidden tokens in mutation SOURCE are assembled at runtime so the harness file
# itself does not trip the tooling scan.
case_ posix-shell-purity 'detects ${var//} pattern substitution' \
  'printf "%s\n" "x=\${y//a/b}" >> scripts/render-core.sh'
case_ posix-shell-purity 'detects [[ test' \
  'printf "%s\n" "[[ \$x == y ]]" >> scripts/render-core.sh'
case_ posix-shell-purity 'detects <<< here-string' \
  'printf "%s\n" "cat <<< hi" >> scripts/render-core.sh'
case_ posix-shell-purity 'detects +=( array append' \
  'printf "%s\n" "arr+=(x)" >> scripts/render-core.sh'
case_ posix-shell-purity 'detects mapfile in an sh script' \
  'm=map; printf "%s\n" "${m}file -t a < /dev/null" >> scripts/render-core.sh'
case_ posix-shell-purity 'detects declare -a in an sh script' \
  'printf "%s\n" "declare -a a" >> scripts/render-core.sh'
case_ posix-shell-purity 'detects local -a in an sh script' \
  'printf "%s\n" "f(){ local -a a; }; f" >> scripts/render-core.sh'
case_ posix-shell-purity 'detects mapfile in a bash script' \
  'm=map; printf "%s\n" "${m}file -t a < /dev/null" >> scripts/check-laws.sh'
case_ posix-shell-purity 'detects readarray' \
  'r=read; printf "%s\n" "${r}array -t a < /dev/null" >> scripts/check-laws.sh'
case_ posix-shell-purity 'detects declare -A' \
  'd=declare; printf "%s\n" "$d -A Z" >> scripts/check-laws.sh'
case_ posix-shell-purity 'detects ${var^^}' \
  'printf "%s\n" "x=\${y""^^""}" >> scripts/check-laws.sh'
case_ posix-shell-purity 'detects ${var,,}' \
  'printf "%s\n" "x=\${y"",,""}" >> scripts/check-laws.sh'
case_ posix-shell-purity 'detects globstar' \
  'g=glob; printf "%s\n" "shopt -s ${g}star" >> scripts/check-laws.sh'
case_ posix-shell-purity 'detects GNU sed -i' \
  's=sed; printf "%s\n" "$s -i \"s/a/b/\" f" >> scripts/check-laws.sh'
case_ posix-shell-purity 'detects readlink -f' \
  'r=readlink; printf "%s\n" "$r -f /" >> scripts/check-laws.sh'
case_ posix-shell-purity 'detects grep -P' \
  'g=grep; printf "%s\n" "$g -P foo f" >> scripts/check-laws.sh'
case_ posix-shell-purity 'detects date -d' \
  'd=date; printf "%s\n" "$d -d tomorrow" >> scripts/check-laws.sh'
case_ posix-shell-purity 'detects stat -c' \
  's=stat; printf "%s\n" "$s -c %%s f" >> scripts/check-laws.sh'

twin_ posix-shell-purity "POSIX-legal lookalikes in an sh script stay silent" \
  'cat > scripts/posix-legal-fixture.sh << '"'"'END'"'"'
#!/usr/bin/env sh
x=${1%%/*}
y=${1#*/}
z=${1:-default}
grep -E "[[:space:]]|[[:alpha:]]" /dev/null || true
cat << EOF
hello
EOF
END
'

twin_ posix-shell-purity "forbidden names inside comments stay silent" \
  'm=map; printf "%s\n" "# ${m}file and friends are forbidden in tooling" >> scripts/check-laws.sh'

case_ readme-groups-complete "a law becomes absent from the README group table" \
  'sed "s/\`kiss-tests\` · //; s/ · \`kiss-tests\`//; s/\`kiss-tests\`//" README.md > t && mv t README.md'

case_ english-only "an accented word enters the corpus" \
  'printf "caf\xc3\xa9\n" >> laws/debugging.md'

twin_ english-only "allowlisted typographic characters stay silent" \
  'printf "\nRanges 1–3 — flow → imply ⇒ omit… sep · see §1 compare ≥ ≤ box ─│└├\n" >> README.md'

case_ product-tier-inert "a product-tier file becomes executable" \
  'git update-index --chmod=+x laws/debugging.md'

case_ product-tier-inert "a product-tier path becomes a symlink" \
  'blob=$(printf "debugging.md" | git hash-object -w --stdin) && git update-index --cacheinfo "120000,$blob,laws/kiss-tests.md"'

twin_ product-tier-inert "a tooling-tier executable stays silent" \
  'printf "#!/usr/bin/env sh\n" > scripts/twin-exec.sh && git add scripts/twin-exec.sh && git update-index --chmod=+x scripts/twin-exec.sh'

# unbraced-nonascii: $VAR immediately before a non-ASCII byte (bash 3.2 identifier trap).
# Assemble via printf %s so the harness source never contains $IDENT + high byte.
case_ unbraced-nonascii "an unbraced expansion sits before a non-ASCII byte" \
  'n=COUNT; printf "echo \$%s–x\n" "$n" >> scripts/install.sh'

twin_ unbraced-nonascii "a braced expansion before a non-ASCII byte stays silent" \
  'n=COUNT; printf "echo \${%s}–x\n" "$n" >> scripts/install.sh'
# --- result -------------------------------------------------------------------
printf '\n'
if [ "$FAILED" -eq 0 ]; then
  printf 'selftest-gate: PASS — %s checks, every declared rule fires and none over-match\n' "$PASSED"
  EXIT_CODE=0
  exit 0
fi
printf 'selftest-gate: FAIL — %s dead, over-matching, or broken case(s), %s healthy\n' "$FAILED" "$PASSED"
EXIT_CODE=1
exit 1
