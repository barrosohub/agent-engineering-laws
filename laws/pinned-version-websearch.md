---
id: pinned-version-websearch
title: Idiomatic by pinned version, verified by web search
always: false
---

# Idiomatic by pinned version, verified by web search

## Pinned version first

Write the idiomatic, recommended usage for the version **pinned in this repository**.

- Check lockfiles, manifests, and vendored metadata. **Never assume** the version.
- The newest documented API is irrelevant if the repository pins an older one.

## Training knowledge is a hypothesis

For third-party API facts — signatures, limits, quotas, defaults, deprecations, error
codes, pricing, model names — model training knowledge is a **hypothesis**, not a fact.

When the fact is unknown, load-bearing, or likely to have changed: **call a WebSearch tool**
and verify against official versioned documentation, changelogs, or upstream source.

When materializing a vendor fact into code, tests, comments, or documentation, **cite the
source and the verification date**.

## Hard rules

- NEVER trust a hardcoded constant in this repository as the source of truth for an
  external API limit. Verify upstream.
- Test doubles MUST mirror real vendor signatures (see law `adapter-chain`).
- **Version upgrades are an owner decision.** Never bump a dependency as a side effect of
  "using the new way". Report the mismatch and let the owner decide.
