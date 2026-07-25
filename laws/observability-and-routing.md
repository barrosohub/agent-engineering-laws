---
id: observability-and-routing
title: Observability at boundaries; route from canonical evidence
always: false
---

# Observability at boundaries; route from canonical evidence

## Instrument the boundaries

Before declaring a pipeline fix done, instrument **ingress, transform, and egress** with
stable identifiers: size, shape, key set, correlation id.

Validate the full emission path with prior state present. Isolated producer tests prove
the producer produced; they do NOT prove delivery.

## Route from canonical evidence

- Do NOT classify requests from lossy derivatives (rendered text, truncated summaries,
  display labels) when a canonical payload exists.
- Log and test the **canonical fields** used for decisions, so a routing bug is visible
  in telemetry rather than inferred.

## Identity-bound values

Probabilistic producers that emit identity-bound values (names, ids, prices, quantities,
dates) MUST be reconciled against a deterministic source of truth **before** user
emission. Do not re-pin globally self-sufficient responses to session context: if the
answer stands alone, leave it alone.

## External confirmations

"Saved" on an external service confirms **ingest, not effect**. Note propagation windows
explicitly and re-read from the authoritative surface before claiming the effect.

## Multiple UIs for one intent

Multiple entry points for one intent may have different scopes. Document each one
separately. Do not collapse them into a single description for false simplicity —
that collapse is how a per-surface bug becomes invisible.
