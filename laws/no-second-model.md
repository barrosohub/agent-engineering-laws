---
id: no-second-model
title: No second model over deterministic candidates
always: false
---

# No second model over deterministic candidates

Before adding a second model stage — reviewer, repairer, reconciler, judge — over another
model's output, **compute the legal decision space**.

If deterministic validation already restricts acceptable output to **one candidate or
fewer per finding**, a model call is the wrong tool. Use a pure function.

## Triage the defect first

1. **Your own boundary bug** (encoding, parsing, transport, truncation) → fix it at the
   boundary. Keep downstream detectors as **noisy tripwires**, never as silent patchers.
   A silent patcher hides the boundary bug forever.
2. **Deterministic correction** (exactly one legal repair exists) → pure function, zero
   model calls, red-case tested.
3. **Probabilistic producer defect** where the root cause is unreachable → validate the
   output, then either retry the **same** producer with explicit feedback (bounded), or
   fail open with telemetry. Measure incidence BEFORE building anything (YAGNI).

## Why not a second writer

A second model writing over the same artifact is a parallel, drifting contract
(see law `never-parallel-contract`). It adds latency, cost, and a new failure mode whose
output nobody validates — and it makes the original defect statistically invisible.
