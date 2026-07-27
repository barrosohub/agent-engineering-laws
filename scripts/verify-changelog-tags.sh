#!/usr/bin/env bash
# verify-changelog-tags.sh — every CHANGELOG link definition has a matching annotated tag.
#
# NOT a check-laws rule. Selftest subjects are single-commit trees with no tags; putting
# this in the gate would fail every red-case and twin subject. Keep it outside the gate and
# run it on the real repository (CI with tags fetched, or a maintainer clone).
#
# For each footer line `[X.Y.Z]: ...` (not Unreleased), require:
#   - annotated tag vX.Y.Z exists
#   - `git show vX.Y.Z:VERSION` equals X.Y.Z (whitespace-trimmed)
#
# For each `## [X.Y.Z]` HEADING, require the same tag — the reverse direction, so a
# released entry cannot sit in the record with neither link nor tag. Two derived
# exemptions, neither keyed to a name:
#   - X.Y.Z equal to the tree's VERSION: the in-flight release; its tag comes later
#     in the release sequence, and its link is added only after the tag exists.
#   - X.Y.Z older than the VERSION at the root commit: predates this repository's
#     history and can never be tagged (derived from the root commit, not hardcoded).
#
# The [Unreleased] compare base must also name an existing tag — it is the one line
# the post-release bookkeeping step mutates, and a typo there rots silently.
#
# Exit 0 on success, 1 on mismatch, 2 if git/changelog unavailable.

set -uo pipefail
export LC_ALL=C

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT" || exit 2

CHANGELOG=CHANGELOG.md
[ -f "$CHANGELOG" ] || { printf 'FAIL: %s missing\n' "$CHANGELOG" >&2; exit 2; }
command -v git >/dev/null 2>&1 || { printf 'FAIL: git required\n' >&2; exit 2; }
git rev-parse --git-dir >/dev/null 2>&1 || { printf 'FAIL: not a git repository\n' >&2; exit 2; }

failures=0
checked=0
seen_ok=" "

# ver_lt A B — true when A sorts strictly below B, numeric field by field. POSIX awk;
# sort -V is GNU and BusyBox lacks it.
ver_lt() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    na = split(a, A, "."); nb = split(b, B, ".")
    n = (na > nb) ? na : nb
    for (i = 1; i <= n; i++) {
      x = (i <= na) ? A[i] + 0 : 0; y = (i <= nb) ? B[i] + 0 : 0
      if (x < y) exit 0
      if (x > y) exit 1
    }
    exit 1
  }'
}

# check_tag <ver> <label> — the shared per-version proof: tag exists, is annotated,
# and its committed VERSION matches. One implementation for both directions.
check_tag() {
  ver=$1; label=$2; tag="v${ver}"
  case "$seen_ok" in *" $ver "*) return 0 ;; esac
  checked=$((checked + 1))

  if ! git rev-parse -q --verify "refs/tags/${tag}" >/dev/null 2>&1; then
    printf 'FAIL: %s [%s] has no tag %s\n' "$label" "$ver" "$tag" >&2
    failures=$((failures + 1)); return 1
  fi
  # Annotated tags only: the ref must point at a tag object, not directly at a commit.
  obj_type=$(git cat-file -t "refs/tags/${tag}" 2>/dev/null || true)
  if [ "$obj_type" != "tag" ]; then
    printf 'FAIL: tag %s exists but is not an annotated tag (type=%s)\n' "$tag" "${obj_type:-missing}" >&2
    failures=$((failures + 1)); return 1
  fi
  tagged_version=$(git show "${tag}:VERSION" 2>/dev/null | tr -d '[:space:]' || true)
  if [ -z "$tagged_version" ]; then
    printf 'FAIL: tag %s has no VERSION file\n' "$tag" >&2
    failures=$((failures + 1)); return 1
  fi
  if [ "$tagged_version" != "$ver" ]; then
    printf 'FAIL: tag %s has VERSION=%s, %s says %s\n' "$tag" "$tagged_version" "$label" "$ver" >&2
    failures=$((failures + 1)); return 1
  fi
  printf 'ok: %s [%s] -> %s (VERSION=%s)\n' "$label" "$ver" "$tag" "$tagged_version"
  seen_ok="${seen_ok}${ver} "
  return 0
}

# Direction 1: every link definition resolves to its tag.
while IFS= read -r line; do
  [ -n "$line" ] || continue
  ver=$(printf '%s\n' "$line" | sed -nE 's/^\[([0-9]+\.[0-9]+\.[0-9]+)\]:.*/\1/p')
  [ -n "$ver" ] || continue
  check_tag "$ver" "link" || true
done <<EOF
$(grep -E '^\[[0-9]+\.[0-9]+\.[0-9]+\]:' "$CHANGELOG" || true)
EOF

if [ "$checked" -eq 0 ]; then
  printf 'FAIL: no [X.Y.Z] link definitions in %s — vacuous pass refused\n' "$CHANGELOG" >&2
  exit 1
fi

# Direction 2: every released heading has its tag, minus the two derived exemptions.
tree_version=$(tr -d '[:space:]' < VERSION 2>/dev/null || true)
root_commit=$(git rev-list --max-parents=0 HEAD 2>/dev/null | head -n 1)
root_version=$(git show "${root_commit}:VERSION" 2>/dev/null | tr -d '[:space:]' || true)

while IFS= read -r line; do
  [ -n "$line" ] || continue
  ver=$(printf '%s\n' "$line" | sed -nE 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p')
  [ -n "$ver" ] || continue
  if [ -n "$tree_version" ] && [ "$ver" = "$tree_version" ]; then
    printf 'skip: heading [%s] is the in-flight release (tree VERSION)\n' "$ver"
    continue
  fi
  if [ -n "$root_version" ] && ver_lt "$ver" "$root_version"; then
    printf 'skip: heading [%s] predates the root commit (VERSION=%s at root)\n' "$ver" "$root_version"
    continue
  fi
  check_tag "$ver" "heading" || true
done <<EOF
$(grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$CHANGELOG" || true)
EOF

# The [Unreleased] compare base is the one line post-release bookkeeping edits.
unreleased_base=$(sed -nE 's/^\[Unreleased\]:.*compare\/(v[0-9]+\.[0-9]+\.[0-9]+)\.\.\..*/\1/p' "$CHANGELOG" | head -n 1)
if [ -n "$unreleased_base" ]; then
  if git rev-parse -q --verify "refs/tags/${unreleased_base}" >/dev/null 2>&1; then
    printf 'ok: [Unreleased] compares from existing tag %s\n' "$unreleased_base"
  else
    printf 'FAIL: [Unreleased] compares from %s, which is not a tag\n' "$unreleased_base" >&2
    failures=$((failures + 1))
  fi
fi

if [ "$failures" -ne 0 ]; then
  printf 'verify-changelog-tags: FAIL — %s mismatch(es) across %s link(s)\n' "$failures" "$checked" >&2
  exit 1
fi

printf 'verify-changelog-tags: PASS — %s link definition(s) match annotated tags\n' "$checked"
exit 0
