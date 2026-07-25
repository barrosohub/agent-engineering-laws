---
id: post-block-reflection
title: Post-block reflection checklist
always: false
---

# Post-block reflection checklist

Before claiming an implementation block complete, reflect on **the real diff**, **the tests
actually executed**, and **the observed behavior**. Mental memory is not evidence — read the
diff.

## Required questions

1. **Principles** — Clean Code, DRY, KISS, YAGNI, strong typing, single responsibility?
2. **Reuse before reinvention** — did an equivalent primitive already exist?
3. **No parallel contract** — no duplicate path, second writer, or contract-free wrapper?
4. **Lifecycle integrity** — is visible state closed on every exit path?
5. **Validation proportional to risk** — and did the cases actually exercise the new path,
   or did they short-circuit before it?
6. **Honest degraded surface** — does failure read as failure, with no fabricated values?
7. **Artifact hermeticity** — does this work from a clean clone?
8. **Contract stability** — for every rename, were consumers searched and updated?
9. **Operational evidence** — actor, timestamp, running version, authoritative artifact?
10. **Residual risk** — does every open risk have a real destination?

## Residue sweep

- Post-refactor residue: orphan local variables, unused imports, dead branches left behind
  by the deletion — remove them in the same change.
- Wrappers with no contract boundary must be folded into their callers.
- Data-shape parity across sinks: if two sinks emit the same logical record, they build it
  through **one canonical builder**, not two hand-written shapes.

## Closing rules

- Residual risk needs a destination (see law `operational-evidence`).
- A green gate expires on the next versioned edit in scope.
- Operational claims need actor and timestamp.
- Lifecycle, concurrency, and security diffs need a second reader before "ready".
