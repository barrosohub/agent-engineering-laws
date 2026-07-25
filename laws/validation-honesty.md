---
id: validation-honesty
title: Validation honesty
always: false
---

# Validation honesty

Validation exists to falsify your change, not to decorate it.

## Rules

1. **Full output, not previews.** Inspect the complete artifact the user will receive.
   Truncated previews hide the failure that matters — the tail, the second page, the
   last section.
2. **Binary contract assertions.** Assert the contract, not the vibe. "Looks correct"
   is not an assertion; `field == expected`, `section present`, `exit code == 0` are.
3. **Include the real trigger.** At least one case MUST use the real user phrasing,
   input, or payload that triggered the work, plus representative synthetic variants.
4. **Short-circuit is not validation.** If a test passes because execution returns
   before reaching the new logic, mark it as a routing or degraded-path test — it is
   NOT validation of the fix. At least one case MUST exercise every new branch.
5. **Prove the path executed.** When in doubt, make the new branch fail loudly on
   purpose once and confirm the test goes red. A test that cannot go red proves
   nothing.

## Measurement batteries

When iterating ad-hoc measurement batteries over time, keep the scoring methodology
stable or version it explicitly. Never compare numbers across a scorer-change boundary
as if the methodology were unchanged. If the scorer changed, re-score the baseline or
state that the comparison is invalid.
