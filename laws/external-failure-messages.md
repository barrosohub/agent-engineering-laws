---
id: external-failure-messages
title: External-failure messages are a contract
always: false
---

# External-failure messages are a contract

Every user-facing message about a failed external dependency MUST:

1. **Name what failed with a concrete discriminator** — the service plus `host:port`, a
   resource id, or an endpoint name. "Something went wrong" names nothing.
2. **State the failure class in human language, plus the effort made** — "could not reach
   it after 3 attempts over 12 seconds". NEVER exception class names.
3. **Offer at least one actionable next step**, including product fallbacks that already
   exist ("you can still do X", "retry in a minute", "check credentials at Y").
4. **Differ by failure mode.** Missing input, service down, authentication rejected, and
   network/proxy blocked are four different messages. One generic string for all four is a
   defect.

## Banned from user surfaces

Implementation-flow vocabulary: *transient, retry, handler, payload, upstream, exception,
traceback, null, timeout exceeded in coroutine*. These describe your code, not their
problem.

## Make it testable

- Assert message content per failure mode in tests.
- Fix the whole class of messages, not the one instance the user reported
  (see law `attack-root-class`).
- Silence is the worst message. Never fail silently on a surface where the user is waiting.
