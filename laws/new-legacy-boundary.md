---
id: new-legacy-boundary
title: A new system declares its own scope; it never learns legacy vocabulary
always: false
---

# A new system declares its own scope; it never learns legacy vocabulary

When a new system coexists with a legacy one, the boundary between them MUST be an
**allowlist of the NEW system's own scope** — never a denylist of legacy vocabulary.
Anything outside the new system's declared scope falls back to legacy **without
interpreting legacy identifiers**.

## The kill test

When legacy dies, the fallback branch disappears and **nothing else in the new system
changes**.

If killing legacy would require editing the new system's routing, matching, or naming,
the boundary was drawn wrong. Redraw it.

This allowlist is a fence, not the exemption law `attack-root-class` forbids: it holds
only the new system's own scope, and anything outside it is refused interpretation
rather than granted a quiet pass.

## Forbidden

- Legacy command names, legacy field names, legacy tenant ids, or legacy error codes
  appearing as identifiers or literals inside new packages.
- "Parity with legacy" as an acceptance criterion. Acceptance criteria come from the new
  product's own contracts.
- A denylist that must grow every time someone finds another legacy behavior.

## Mechanize it

Ship a guard that fails if new packages contain legacy vocabulary identifiers, with a
red-case and an over-match twin for the legitimate fallback tokens at the seam (the one
place where the handoff is allowed to name legacy).
