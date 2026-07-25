---
id: hermetic-artifacts
title: Hermetic versioned artifacts; docs-as-contract
always: false
---

# Hermetic versioned artifacts; docs-as-contract

## Hermeticity

Versioned inputs MUST work from a clean clone.

- Reference only other versioned files, or explicit external services.
- NEVER reference as a required input: an ignored local directory, a temporary directory,
  an absolute per-user path, or a generated output.
- Separate inputs from outputs. Generated outputs stay local and stay ignored; quality
  gates must not require an ignored artifact to pass.
- The **fresh-clone test decides**: clone into an empty directory, run the gate, and see.
- Add machine guards for forbidden local path patterns whenever they are searchable.

## Docs-as-contract

Versioned Markdown may be a parsed contract — read by tools, gates, or agents.

- Before renaming a heading, column, status value, anchor, or id, **search consumers**.
- Prefer stable tokens plus an explanation over expressive names that change.
- After a docs-as-contract edit, run the narrow consumer test FIRST, then the owning gate.

## Sanitization keeps signal

When sanitizing examples, logs, or reproductions for a versioned artifact:

- **Keep**: ports, relative paths, metric names, status codes, exception classes, timings,
  sizes, error shapes.
- **Remove**: secrets, tokens, hostnames, usernames, absolute machine paths, personal data.

Redaction that removes the diagnostic signal has destroyed the artifact's only purpose.
