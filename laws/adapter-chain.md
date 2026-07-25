---
id: adapter-chain
title: New parameters cross the whole adapter chain
always: false
---

# New parameters cross the whole adapter chain

When a parameter enters at the caller and must reach the core, it crosses every layer:
**caller → interface/protocol → wrapper/adapter → core**. The change is complete only
when ALL layers accept AND propagate it.

## Rules

- Enumerate every definition of the signature in the same change — interfaces, abstract
  base classes, protocols, overloads, stubs, fakes, and mocks.
- Add signature-parity guards where the language allows them.
- **Test doubles MUST mirror real signatures.** Permissive mocks that accept any keyword
  argument hide this entire defect class: the call "succeeds" in tests and drops the
  parameter in production.
- A parameter accepted and silently ignored by one layer is worse than a compile error.
  Fail loudly on unknown parameters at boundaries you own.

## When the call is a user-facing send

- Failure is NEVER "just a warning" when a progress surface already promised a result.
  Close the promise on every exit path (see law `lifecycle-concurrency`).
- After any edit on the delivery chain, re-validate end to end. A prior green smoke test
  does not cover a newly added parameter — the smoke ran against the old signature.
