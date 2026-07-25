---
id: kiss-tests
title: KISS applies to test creation
always: false
---

# KISS applies to test creation

Create ONLY the tests strictly necessary to validate real behavior.

## Prefer

- The smallest number of sharp tests.
- One clear test per real contract, exercising the new path.
- A red-case proving the guard/assertion actually fails when the contract is violated.
- An over-match twin whenever the contract involves an open class (matchers, routers,
  regexes, vocabularies) — proving the rule does not fire on legitimate input.
- Minimal fixtures. Build the smallest input that reaches the branch.

## Do not create

- Ornamental tests that assert framework behavior or constructor sanity.
- Duplicated tests that re-assert the same contract with cosmetic variation.
- Narrative tests that read like documentation and assert nothing meaningful.
- Speculative tests for behavior nobody has asked for (YAGNI).
- Snapshot walls that lock in noise and are re-blessed on every failure.

## Minimizing quantity is NOT skipping real risk

These still need coverage even under a "few tests" budget:

- Every exit path of anything that allocates externally-visible state.
- Never-fabricate surfaces (anything that must show absence rather than invent data).
- Any seam that a future change can break silently.

If a test passes without exercising new code, delete it or rewrite it.
