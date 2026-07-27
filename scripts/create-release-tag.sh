#!/usr/bin/env bash
# create-release-tag.sh — create an annotated release tag from repository state.
#
# Usage: scripts/create-release-tag.sh [--dry-run] <X.Y.Z>
#
# Preconditions (all mandatory; any failure exits non-zero without creating a tag):
#   1. the working tree is CLEAN — the tag names HEAD, so HEAD is what must be validated;
#      a dirty tree means the gates would prove a tree the tag does not point at
#   2. scripts/check-laws.sh and scripts/selftest-gate.sh both exit 0
#   3. VERSION read from HEAD (git show HEAD:VERSION) equals <X.Y.Z>
#   4. CHANGELOG.md at HEAD has a ## [<X.Y.Z>] heading
#   5. tag v<X.Y.Z> does not exist locally, and not on origin either when the remote is
#      reachable — an unreachable remote is WARNED about explicitly, never skipped silently
#   6. current branch is the distribution branch (main). DISTRIBUTION_BRANCH overrides it
#      from the environment; that escape hatch exists for validating the script off-branch
#      and must never be used for a real release.
#
# The annotated tag message is derived from the changelog entry's Theme (including wrapped
# continuation lines), not from an argument. This script STOPS before pushing, prints the
# push command, and states that publishing is the human's decision — see law git-safety.
# --dry-run validates every precondition and prints the intended tag message, then exits
# without creating a tag.

set -uo pipefail
export LC_ALL=C

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT" || exit 2

DISTRIBUTION_BRANCH=${DISTRIBUTION_BRANCH:-main}
DRY_RUN=0

usage() {
  printf 'Usage: %s [--dry-run] <X.Y.Z>\n' "$(basename "$0")" >&2
  exit 2
}

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi
[ "$#" -eq 1 ] || usage
TARGET=$1
printf '%s\n' "$TARGET" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || {
  printf 'FAIL: target %s is not X.Y.Z\n' "$TARGET" >&2
  exit 2
}

fail_pre() {
  printf 'PRECONDITION FAIL: %s\n' "$1" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || fail_pre "git required"
git rev-parse --git-dir >/dev/null 2>&1 || fail_pre "not a git repository"

branch=$(git branch --show-current 2>/dev/null || true)
[ "$branch" = "$DISTRIBUTION_BRANCH" ] || \
  fail_pre "current branch is '${branch:-detached}', need ${DISTRIBUTION_BRANCH}"

# The tag names HEAD. A dirty tree means every check below (and both gates) would
# validate content the tag does not point at — the exact defect this script exists
# to prevent, found by review before it ever minted a tag.
[ -z "$(git status --porcelain)" ] || \
  fail_pre "working tree is dirty — the tag names HEAD, commit or discard first"

# Read from HEAD, not the working tree: HEAD is the object being tagged.
declared=$(git show HEAD:VERSION 2>/dev/null | tr -d '[:space:]')
[ -n "$declared" ] || fail_pre "VERSION missing at HEAD"
[ "$declared" = "$TARGET" ] || \
  fail_pre "VERSION at HEAD is ${declared}, target is ${TARGET}"

git show HEAD:CHANGELOG.md 2>/dev/null | grep -Eq "^## \\[${TARGET}\\]" || \
  fail_pre "CHANGELOG.md at HEAD has no ## [${TARGET}] heading"

tag="v${TARGET}"
if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null 2>&1; then
  fail_pre "tag ${tag} already exists locally"
fi
# A tag published from another clone is invisible to rev-parse. Check the remote when
# reachable; when it is not, say so out loud instead of passing silently.
if git remote get-url origin >/dev/null 2>&1; then
  if git ls-remote --exit-code --tags origin "refs/tags/${tag}" >/dev/null 2>&1; then
    fail_pre "tag ${tag} already exists on origin"
  elif [ "$?" -ne 2 ]; then
    printf 'WARNING: could not reach origin — remote tags were NOT checked.\n' >&2
  fi
fi

printf 'Running check-laws.sh...\n'
bash scripts/check-laws.sh || fail_pre "check-laws.sh failed"
printf 'Running selftest-gate.sh...\n'
bash scripts/selftest-gate.sh || fail_pre "selftest-gate.sh failed"

# Collect the Theme from HEAD's changelog, including wrapped continuation lines
# (everything until the first blank line), joined into one sentence.
theme=$(git show HEAD:CHANGELOG.md | awk -v ver="$TARGET" '
  $0 ~ "^## \\[" ver "\\]" { insec=1; next }
  insec && /^## \[/ { exit }
  insec && intheme && /^[[:space:]]*$/ { exit }
  insec && intheme { sub(/^[[:space:]]*/, ""); out = out " " $0; next }
  insec && /^Theme:/ { sub(/^Theme:[[:space:]]*/, ""); out = $0; intheme = 1 }
  END { print out }
')
if [ -z "$theme" ]; then
  printf 'WARNING: no Theme line found in the [%s] entry; using a bare fallback.\n' "$TARGET" >&2
  theme="Release ${TARGET}"
fi

message=$(printf 'v%s\n\n%s\n' "$TARGET" "$theme")

if [ "$DRY_RUN" -eq 1 ]; then
  printf '\nDRY-RUN: all preconditions passed. Would create annotated tag %s at %s\n' \
    "$tag" "$(git rev-parse --short HEAD)"
  printf 'Tag message:\n%s\n' "$message"
  printf 'No tag created.\n'
  exit 0
fi

git tag -a "$tag" -m "$message" || fail_pre "git tag -a failed"

printf '\nCreated annotated tag %s at %s\n' "$tag" "$(git rev-parse --short HEAD)"
printf 'Tag message:\n%s\n' "$message"
printf '\nSTOPPED before push. Publishing is the human'\''s decision (law git-safety).\n'
printf 'If and only if an explicit push imperative is given, run:\n'
printf '  git push origin %s\n' "$tag"
exit 0
