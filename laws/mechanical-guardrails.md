---
id: mechanical-guardrails
title: Mechanical guardrails
always: false
---

# Mechanical guardrails

If a durable rule is searchable or AST-testable, enforce it with a guardrail in the
owning suite and wire it into the quality gate. Do NOT rely on reviewers remembering it.

## The green-gate trap

A green gate is consistent with two very different worlds: a correct guard, and a guard
that never fires. Therefore:

- Every guardrail MUST ship with a **red-case**: an input that makes the guard fail.
- Open-class matchers MUST also ship an **over-match twin**: legitimate input that the
  guard must NOT flag.
- The guard MUST scan the class generically, not only the observed instance.
- Validate the guard itself, in the state the commit will actually happen.

## Ordering

A searchable or AST-testable content contract over a large multi-agent corpus MUST ship
with a gate guard **first** — not as prose alone. Prose without a guard is a hope.

## Scope

- Put the guard in the suite that owns the rule, not in a global grab-bag.
- Prefer guards that fail on *undeclared* surfaces over guards that hardcode one path.
- Keep the guard's failure message actionable: what rule, what file, what to do.
- If the guard is expensive, run it in the gate, not on every keystroke — but run it.
