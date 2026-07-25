---
id: debugging
title: Debugging discipline
always: false
---

# Debugging discipline

## Confirm the live executing path

Search for callers. Do not assume which implementation runs. Two functions with the same
name, a shadowed module, a stale build artifact, or an unregistered handler will all make
a correct fix invisible.

**Capability is not reachability.** The existence of a type, builder, class, or function is
not proof that it runs on the live path. Trace the entry gate that would invoke it.

## Matching pitfalls

- Short regex tokens (roughly ≤4 characters) need word boundaries. Without them they match
  inside unrelated words and produce phantom hits.
- Hand-rolled boundary classes MUST be unicode-aware when the input is natural language
  with accents or non-Latin scripts. ASCII-only boundaries silently mis-split.
- Do NOT count matches in logs that echo history — the same event appears once per replay.
  Parse structured fields with a stable identifier instead.

## Reconfirm the repro

Reconfirm the reproduction against **live state** before writing code.

Backlog items are hypotheses about past state. If the repro is gone, the field is now
empty, or the symptom turns out to be by design: **reject with rationale or re-scope**.
Never write code from the hypothesis alone.

## Order of work

1. Reproduce.
2. Localize (instrument, bisect, read the actual data).
3. Name the failed contract (see law `attack-root-class`).
4. Fix at that level.
5. Prove with a red-case that would have caught it.
