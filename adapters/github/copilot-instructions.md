# Copilot instructions

Follow the operating laws in `AGENTS.md` at the repository root. It is the single source of
truth for engineering policy here. This file is a pointer and deliberately duplicates none of
it.

`AGENTS.md` contains an "External law loading" table mapping task types to law files under
`agent-laws/laws/`. When your task matches a row, read that law file before implementing.
Load one law, not the whole corpus.

Irreversible-action rules, restated here because they cannot be undone:

- Never mutate git state (stage, commit, amend, push, reset, rebase, merge, stash, clean,
  delete branches) without an explicit per-operation instruction from the user. A question
  such as "is this ready to commit?" is a request for state, not authorization.
- Never add agent or tool `Co-authored-by:` trailers to commits.
- Never claim a change is validated based on a test that returns before reaching the new
  code path.
