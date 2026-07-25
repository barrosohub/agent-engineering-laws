#!/usr/bin/env sh
# Human fallback installer for agent-engineering-laws.
#
# The primary install path is the paste-ready prompt in INSTALL.md, executed by a coding
# agent inside the target repository. This script exists for humans and CI who want the
# same result without an agent.
#
# Usage:
#   scripts/install.sh --target <path> [--laws-dir agent-laws/laws] [--force]
#
# Behaviour:
#   - writes core/ALWAYS.md to <target>/AGENTS.md
#   - refuses to overwrite an existing AGENTS.md without --force, and prints a diff
#   - copies laws/ to <target>/<laws-dir>
#   - links <target>/CLAUDE.md -> AGENTS.md, or prepends "@AGENTS.md" if linking fails
#   - never creates any other tool-specific instruction file
#   - never touches git

set -eu

SOURCE_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TARGET=""
LAWS_DIR="agent-laws/laws"
FORCE=0

die() { printf 'install.sh: %s\n' "$1" >&2; exit 1; }
info() { printf '  %s\n' "$1"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --target)    TARGET=${2:-}; shift 2 ;;
    --laws-dir)  LAWS_DIR=${2:-}; shift 2 ;;
    --force)     FORCE=1; shift ;;
    -h|--help)   sed -n '2,20p' "$0"; exit 0 ;;
    *)           die "unknown argument: $1" ;;
  esac
done

[ -n "$TARGET" ] || die "missing --target <path>"
[ -d "$TARGET" ] || die "target is not a directory: $TARGET"
[ -f "$SOURCE_DIR/core/ALWAYS.md" ] || die "source corpus not found at $SOURCE_DIR"

TARGET=$(CDPATH='' cd -- "$TARGET" && pwd)
printf 'Installing operating laws\n  source: %s\n  target: %s\n' "$SOURCE_DIR" "$TARGET"

# 1) always-on file -----------------------------------------------------------
AGENTS="$TARGET/AGENTS.md"
if [ -e "$AGENTS" ] && [ "$FORCE" -ne 1 ]; then
  printf '\nAGENTS.md already exists in the target. Refusing to overwrite.\n\n' >&2
  if command -v diff >/dev/null 2>&1; then
    printf 'diff (existing -> source):\n' >&2
    diff -u "$AGENTS" "$SOURCE_DIR/core/ALWAYS.md" >&2 || true
  fi
  printf '\nReview the diff. Re-run with --force to overwrite, or merge by hand and keep\n' >&2
  printf 'your existing "## Project context" section.\n' >&2
  exit 2
fi
cp "$SOURCE_DIR/core/ALWAYS.md" "$AGENTS"
info "wrote AGENTS.md"

# 2) law corpus ---------------------------------------------------------------
mkdir -p "$TARGET/$LAWS_DIR"
cp "$SOURCE_DIR"/laws/*.md "$TARGET/$LAWS_DIR/"
n_laws=$(ls -1 "$SOURCE_DIR"/laws/*.md | grep -cv '/INDEX\.md$')
info "copied $n_laws laws + INDEX.md to $LAWS_DIR/"

# The distributed always-on file addresses laws as agent-laws/laws/<id>.md.
# Rewrite the table if the operator chose a different location.
if [ "$LAWS_DIR" != "agent-laws/laws" ]; then
  ESCAPED=$(printf '%s' "$LAWS_DIR" | sed 's/[\/&]/\\&/g')
  sed "s/agent-laws\/laws\//${ESCAPED}\//g" "$AGENTS" > "$AGENTS.tmp"
  mv "$AGENTS.tmp" "$AGENTS"
  info "rewrote lazy-load paths to $LAWS_DIR/"
fi

# 3) Claude compatibility — @AGENTS.md import is primary (Windows-safe).
#    A pre-existing symlink is left alone; we do not create new symlinks.
CLAUDE="$TARGET/CLAUDE.md"
if [ -L "$CLAUDE" ]; then
  info "CLAUDE.md symlink already present, left as is"
elif [ -f "$CLAUDE" ]; then
  if head -n 1 "$CLAUDE" | grep -q '^@AGENTS\.md[[:space:]]*$'; then
    info "CLAUDE.md already imports AGENTS.md, left as is"
  else
    printf '@AGENTS.md\n\n' > "$CLAUDE.tmp"
    cat "$CLAUDE" >> "$CLAUDE.tmp"
    mv "$CLAUDE.tmp" "$CLAUDE"
    info "prepended @AGENTS.md to existing CLAUDE.md (content preserved)"
  fi
else
  printf '@AGENTS.md\n' > "$CLAUDE"
  info "wrote CLAUDE.md with @AGENTS.md import"
fi

# 4) no other tool-specific instruction file is created. By design.

printf '\nDone. Next steps:\n'
printf '  1. Edit ONLY the "## Project context" section at the bottom of AGENTS.md.\n'
printf '     Verified facts only; leave everything else as TODO.\n'
printf '  2. Optionally copy adapters/ for Cursor, Claude rules, or Copilot.\n'
printf '  3. Restart your agent session.\n'
printf '  4. Review the working tree and commit yourself. This script never touches git.\n'
