---
id: reuse-and-placement
title: Reuse before reinvention; place by ownership
always: false
---

# Reuse before reinvention; place by ownership

## Reuse

Before introducing a new setting, registry, helper, client, or cross-cutting primitive,
audit existing modules for an equivalent. Parallel implementations are a primary source
of drift.

- Name shared primitives by **role**, not by first consumer.
- When an existing name is wrong, prefer adding an alias over a hard rename.
- A shared change that adds per-consumer behavior MUST be opt-in. The default MUST
  preserve prior global behavior for every existing caller.
- Dead code that is defined but never called usually means **abandoned wiring**, not
  dead weight. Search cancel, error, retry, and cleanup paths before deleting it.

## Placement by ownership

- One consumer → the code lives in that owner's package.
- A shared home requires **≥2 real, distinct consumers that exist now**, or genuine framework
  use. Do not generalize for a hypothetical second consumer (YAGNI).
- Moving code into a shared surface inflates the blast radius of every future edit.
  Justify it explicitly.

## Guards are contracts too

If a guard fails, first ask whether the guard is the failed contract.

- If the guard is wrong → fix the guard, and say why in the same change.
- If the guard is right → fix the code. **Never move code to a different directory to
  evade a guard.**
- Guard documentation and guard implementation must match. A guard that documents rule A
  and enforces rule B is a defect.
