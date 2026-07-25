---
id: long-term-memory
title: Long-term memory stores universal laws
always: false
---

# Long-term memory stores universal laws

Durable lessons belong in long-term memory as **standing rules**, not as session trivia.
Prefer universal, reusable wording that will still make sense in a different repository on a
different machine.

## Do NOT store as required operating law

- Machine-local paths, per-user directories, or environment-specific commands.
- One-off incident dumps and raw logs.
- Product gossip, personnel notes, or branch state.
- Near-singleton subsystem trivia promoted to a global rule.

## Scope matters

When a lesson is concentrated in one subsystem, keep it scoped to that subsystem. A global
rule that only ever applies in one directory is noise for every other task.

## Rewrite before storing

Turn the incident into the law:

- Incident: "the retry loop double-sent a message on timeout."
- Law: "close visible state on every exit path, including timeout."

## Process discipline

- If the environment provides structured engineering skills — plan grilling, TDD, two-axis
  review, domain modeling, diagnostics — use them idiomatically when installed. Do NOT
  invent a competing bespoke process alongside them.
- Keep process depth proportional to risk.
- Mechanize recurring lapse classes into guardrails rather than storing more reminders
  (see law `mechanical-guardrails`).
