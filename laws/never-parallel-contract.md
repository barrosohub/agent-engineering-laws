---
id: never-parallel-contract
title: Never invent a parallel contract
always: false
---

# Never invent a parallel contract

Strengthen the existing contract. Do NOT add:

- a duplicate code path that answers the same question a different way;
- a second writer over the same artifact, store, or field;
- a public wrapper with an identical signature and no validation, transform,
  side-effect, or stability role;
- a test harness that re-implements production dispatch instead of calling it.

## Why

A green harness over a stale copy is false confidence: it proves the copy works, not
the product. Two writers over one artifact drift silently and the drift surfaces as an
unreproducible bug months later. Dual paths are bugs, not options.

## Rules

- If the existing path is wrong, fix the existing path.
- If the existing path is unreachable from your call site, fix the wiring — do not
  clone the logic closer to yourself.
- A wrapper is legitimate only when it owns a boundary: validation, type narrowing,
  transformation, side-effect ordering, or API stability. State which one in the code.
- Tests call the real entry point. If the real entry point is untestable, that is the
  defect to fix.
- When you find an existing parallel contract, do not add a third. Report it, pick the
  canonical one, and route the others through it.
