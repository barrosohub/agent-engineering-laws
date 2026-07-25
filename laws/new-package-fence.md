---
id: new-package-fence
title: A new package is born without a fence
always: false
---

# A new package is born without a fence — creating a directory triggers a guard

Architecture guards that scan a fixed directory list miss brand-new packages by default.
The gate stays green while the new path is entirely uncovered. The absence of a failure
is not evidence of coverage.

## Mandatory question

Creating a production package, module, or namespace MANDATES asking:
**"which guard covers this?"**

If the answer is "none", ship the fence in the SAME change. Not in a follow-up.

## Fence design

- Prefer guards that **fail on undeclared packages** (enumerate what is allowed, fail on
  anything new) over guards that hardcode a single directory scan.
- The fence must state what the new package may import and what may import it.
- Ship a **red-case** (an illegal import fails the guard) and an **over-match twin**
  (a legitimate import passes).

## Applies to

New services, new adapters, new test-support packages that production can accidentally
import, new top-level namespaces, and any directory that becomes an import root.
