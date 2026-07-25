---
id: external-boundary
title: The external boundary is a different risk class
always: false
---

# The external boundary is a different risk class

Internal slices produce **contract defects**, which unit tests and red-cases catch.

Delivery slices that talk to the world — chat, email, webhooks, UI, public API — produce
**behavior-parity defects**, which a green gate will not catch. Treat them as a distinct
risk class with distinct obligations.

## When shipping an external-boundary slice

1. **Adversarial review on separate axes is mandatory.** Run Standards (principles and
   smells) and Spec (fidelity to the request) as independent passes, not one blended read.
2. **Inventory ALL event shapes of the boundary** — not only the one you implemented.
   Enumerate every message type, callback, status, and error the boundary can deliver, and
   state what happens for each.
3. **Recover the product contracts the user already has**, without learning legacy
   vocabulary (see law `new-legacy-boundary`). At minimum: do not speak unprompted; answer
   in the right place; never be silent on failure.
4. **Write canary criteria BEFORE enabling** if no human has used it yet: what counts as
   success, what counts as abort, who watches, for how long.

## Not acceptable as readiness evidence

- "All unit tests pass."
- "The happy path worked once, manually."
- "The provider says the webhook was accepted." Acceptance is ingest, not effect.
