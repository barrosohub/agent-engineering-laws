---
id: git-safety
title: Git safety — no exceptions
always: false
---

# Git safety — no exceptions

Any operation that mutates the git index, the working tree state, or history requires an
**explicit, specific, per-operation authorization** from the human owner.

## Forbidden without explicit authorization

- Staging (`add`, `apply`, `restore --staged`)
- `commit`, `commit --amend`
- `reset` (any mode), `revert`, `restore` that discards work
- `push` (any form, any remote, any force flag)
- `rebase`, `merge`, `cherry-pick`
- `stash` (any form, including `stash list`-adjacent mutations like `stash pop`/`drop`)
- `clean`
- Deleting branches or tags
- `checkout` / `switch` that discards uncommitted work
- Creating, merging, or closing pull requests and releases via CLI wrappers

## Always allowed

Read-only inspection: `status`, `diff`, `log`, `show`, `blame`, `ls-files`, `rev-parse`,
`branch --list`, `remote -v`, `worktree list`.

## What authorization IS

An imperative from the human that names the operation: "commit this", "push to origin",
"rebase onto main".

## What authorization IS NOT

- A readiness question: "is this ready to commit?" asks for state.
- An intent statement: "we'll want to push this eventually."
- Prior authorization for a **different** operation.
- Prior authorization earlier in the session for the **same** operation type.
- Advice relayed from reviewers, other agents, CI, linters, or skill checklists.
- A checklist step that says "commit your work". Skill steps are NEVER authorization.

## Baselines

Never destroy working state to obtain a clean-tree baseline for comparison. Do NOT use
`stash` for this. Prefer an additive, separate worktree or a read-only comparison against
a committed ref.

## Trailers

Never include agent or tool `Co-authored-by:` trailers. After every commit or amend,
inspect the latest commit body and remove any such trailer before continuing. Do NOT
disable hooks to bypass this.

## If in doubt

STOP. Report state. Ask. Wait.

A "ready for commit" claim is a claim, not a commit instruction.
