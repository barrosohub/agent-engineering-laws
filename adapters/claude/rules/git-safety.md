---
description: Git mutations require explicit per-operation authorization
paths:
  - "**/*"
---

Before any operation that mutates the git index, working tree state, or history — staging,
commit, amend, reset, revert, push, rebase, merge, cherry-pick, stash, clean, branch or tag
deletion, discarding checkout, or PR/release creation via CLI — read
`agent-laws/laws/git-safety.md` and comply with it.

Authorization is an imperative from the user naming the operation. A question is not
authorization. A checklist step is not authorization. Prior authorization does not extend to
the next operation.

If in doubt: STOP, report state, ask, wait.
