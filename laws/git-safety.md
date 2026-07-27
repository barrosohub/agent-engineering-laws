---
id: git-safety
title: Git safety and irreversible action — no exceptions
always: false
---

# Git safety and irreversible action — no exceptions

Any operation you cannot undo alone requires an **explicit, specific, per-operation
authorization** from the human owner. Git mutation is the highest-frequency member of
that class, never its boundary. Apply both tests to the operation in front of you; if
either fires, it needs its own authorization, whether or not it appears below:

1. **It destroys state that no committed ref restores** — uncommitted work, recorded
   history, a record, a table, a schema, a file tree, a credential, a live process.
2. **It emits an effect you cannot recall** — a push, a publish, a release, a real
   message, a charge, an access grant or revocation.

The lists below are a floor, not a ceiling. Every listed operation needs authorization
even if you judge it reversible, and every unlisted operation that passes either test
needs it too. A missed case is never fixed by growing the list (see law
`attack-root-class`).

## Forbidden without explicit authorization — version control

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

## Forbidden without explicit authorization — the rest of the class

- Publishing, deploying, or promoting an artifact anywhere a consumer can fetch it.
- Migrating a schema, or bulk-writing or bulk-deleting persistent state others read.
- Dropping or truncating a table, a schema, a store, a bucket, or a directory tree.
- Sending a real message, notification, or charge — a test run included.
- Granting, revoking, or rotating a credential, access grant, or automation config.
- Stopping or restarting a live process others depend on.

## Always allowed

Read-only inspection: `status`, `diff`, `log`, `show`, `blame`, `ls-files`, `rev-parse`,
`branch --list`, `remote -v`, `worktree list` — and the equivalent listing or describing
operation in any other store. Run that first and report what the mutation would touch.

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

Never destroy live state to obtain a clean baseline for comparison. Do NOT use `stash`
for this. Prefer an additive, separate worktree, a copy forward, or a read-only
comparison against a committed ref.

## Trailers

Never include agent or tool `Co-authored-by:` trailers. After every commit or amend,
inspect the latest commit body and remove any such trailer before continuing. Do NOT
disable hooks to bypass this.

## If in doubt

STOP. Report state. Ask. Wait.

A "ready for commit" claim is a claim, not a commit instruction.
