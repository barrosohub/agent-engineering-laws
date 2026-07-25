---
id: reviewer-auto-gate
title: Reviewer auto-gate; second reader
always: false
---

# Reviewer auto-gate; second reader

The executor has a reviewer. **The reviewer has no external gate.** A bad reviewer request
becomes a bad change with an approval attached. So the reviewer gates itself.

## Before requesting anything, the reviewer MUST

1. Read the existing policy, decision records, documentation, guards, and owner decisions.
2. Ask: **what already covers this?**
3. Ask: **root or instance?** If fulfilling the request requires enumerating observed names
   in code or configuration, the request is wrong.
4. Ask: does this contaminate the new system with legacy vocabulary?
5. Ask: does this contradict an owner-locked decision?
6. Ask: is this the minimum? KISS applies to the request itself.
7. Ask: does this inflate a shared surface?
8. Ask: is the ruler gameable? (see law `multi-axis-invariants`)
9. If a new directory appeared: **which guard covers it?** (see law `new-package-fence`)
10. Verify against the **live file**, and run the gate in the state the commit will
    actually happen in (see law `verify-live-file`).
11. Only the reviewer closes risk items, and only with evidence.
12. **Recommend; do not catalogue** when the owner asked for a recommendation.

## Every reviewer request carries this clause

> If fulfilling this requires enumerating names, inflating a shared file, touching critical
> configuration, or contradicting a locked decision — STOP and say so. The request is
> probably wrong.

**Executors have a duty to block bad reviewer requests.** "The reviewer told me to" is not
a justification.

## Second reader

Before declaring ready on any diff touching lifecycle, concurrency, or security, open a
second-reader pass.

## Two-axis review

When reviewing non-trivial changes, run **Standards** (principles and smells) and **Spec**
(fidelity to the request) as independent passes. Verify severe findings against live files
before relaying them.
