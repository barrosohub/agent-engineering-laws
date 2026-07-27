---
id: scope-discipline
title: Scope discipline for spec-driven changes
always: false
---

# Scope discipline for spec-driven changes

## The anchor

The owner's request defines the scope anchor: the named output surfaces and named
capabilities. Everything else you touch is a **consumer**, not a target.

## Tolerance vs feature

- Outside the anchor, your obligation is **tolerance only**: the consumer must not break,
  and must not render orphaned legacy fields.
- Adding new sections, new capabilities, or new renders in a consumer is a scope
  violation, however small and however tempting.
- Sweep inventories (lists of everything that touches X) are **tolerance lists, never
  feature lists**. Finding 14 call sites does not authorize 14 improvements.
- Escalating scope requires explicit owner sign-off, obtained before the work.

## Non-goals are hard

- Spec non-goals are binding constraints, not suggestions.
- When an abstract principle ("completeness", "consistency") conflicts with the owner's
  stated scope, **owner scope wins**. Report the tension; do not resolve it by expanding.

## Wide blast radius

A change touching roughly more than 20 files MUST ship, before any "ready" claim:

1. A **scope manifest** listing the files intended to change and why.
2. A **mechanical guard** comparing actually-changed files against the manifest, with its
   own self-test red-case.

## Verification cadence

Never stack an unverified change on top of another unverified change: run the available
check between them. A green result expires on the next edit in scope — law
`operational-evidence` owns the claim-time counterpart of this rule.

## Review

Reviewer endorsement does not replace crossing the diff against the owner's original
request. A reviewer who approves out-of-scope work has not authorized it.
