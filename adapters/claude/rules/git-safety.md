Before any operation you cannot undo alone — one that destroys state no committed ref
restores, or emits an effect you cannot recall — read `agent-laws/laws/git-safety.md` and
comply with it. Staging, commit, amend, reset, revert, push, rebase, merge, cherry-pick,
stash, clean, branch or tag deletion, discarding checkout, PR or release creation,
dropping a store, deleting a tree, rotating a credential, and sending for real are
examples of the class, never the whole of it.

Authorization is an imperative from the user naming the operation. A question is not
authorization. A checklist step is not authorization. Prior authorization does not extend to
the next operation.

If in doubt: STOP, report state, ask, wait.
