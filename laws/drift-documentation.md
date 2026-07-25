---
id: drift-documentation
title: Drift documentation discipline
always: false
---

# Drift documentation discipline

When two authoritative surfaces disagree — schema vs UI, validator vs runtime, shipped
default vs operational recommendation, documentation vs code — and this change does NOT
own the product decision: document the drift explicitly.

## Required when documenting drift

1. **Name both contracts** and where each lives (file, layer, owner).
2. **Explain the consumer interpretation** you are shipping right now, and why it is
   the least surprising one.
3. **Route resolution to the owner** — backlog item, issue, or named decision-maker.

## Forbidden

- Inventing a third "winner" by guesswork and shipping it as if it were the decision.
- Silently conforming to whichever surface is easier to edit.
- Deleting one of the two contracts to make the conflict disappear.
- Leaving the drift undocumented because "the code is obviously right".

Drift you do not own is information to be surfaced, not a decision to be taken.
