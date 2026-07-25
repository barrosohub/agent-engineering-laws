---
id: io-boundary
title: I/O boundary safety
always: false
---

# I/O boundary safety

Consumers of external or untrusted data MUST NOT throw past the caller — especially
last-resort consumers (loggers, formatters, serializers, renderers, notifiers). A crash in
the reporting path destroys the diagnostic value of the original failure.

## Rules

- Wrap the boundary. On failure, return the raw input unchanged and log the exception
  class plus a stable identifier.
- Treat these as **expected inputs**, not exceptional ones: wrong encoding, unexpected
  types, `null` where an object was promised, truncation mid-sequence, malformed nesting,
  unexpectedly huge payloads.
- UTF-8 encode boundaries MUST scrub lone surrogates and invalid sequences before writing.
- Prefer a **visible replacement character** over a silent drop. Silent drops turn a data
  bug into a mystery.
- Use one shared boundary utility. Every ad-hoc `try/except` around encoding is a future
  inconsistency (see law `never-parallel-contract`).

## Sanitization

Sanitize without destroying diagnostic signal — see law `hermetic-artifacts`.
