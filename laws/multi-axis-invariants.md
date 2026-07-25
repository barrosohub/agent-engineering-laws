---
id: multi-axis-invariants
title: Single-metric invariants are gameable
always: false
---

# Single-metric invariants are gameable

Before accepting an invariant of the form *"metric X may only decrease"*, ask:
**can X be satisfied while worsening exactly what X exists to protect?**

If yes, the ruler is incomplete and the invariant will be satisfied by the wrong change.

## Examples of incomplete rulers

- "Total line count may only decrease" — satisfied by moving code into a shared surface
  that nobody owns.
- "Number of violations may only decrease" — satisfied by moving the violation to a
  directory the scanner does not visit.
- "Test count may only increase" — satisfied by ornamental tests.

## Prefer multi-axis invariants

Include **direction and placement** — where the code lives, which layer owns it, which
package imports which — not only counts.

## When someone says "the metric passed"

Check the axis the metric does not cover. State that axis explicitly in the report.
A passing ruler is evidence about the ruler's axis and nothing else.
