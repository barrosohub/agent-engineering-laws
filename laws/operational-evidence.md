---
id: operational-evidence
title: Operational evidence, closeout, residual risk, green-gate expiry
always: false
---

# Operational evidence, closeout, residual risk, green-gate expiry

## Operational evidence

Operational validation requires ALL of:

- **Actor** — who or what ran it.
- **Timestamp** — when.
- **Observed process/version** — the build, commit, or version actually running.
- **Readiness signal** — proof the process was serving before the check.
- **Authoritative result artifact** — the log, response, or record, not a paraphrase.

"Server restarted" or "fresh run" alone is NOT evidence.

## Closeout

- Measure the closeout inventory from the **real tracker or file** — never from memory.
- Every acceptance criterion needs one of: evidence, an explicit deferment, or a rejection
  rationale.
- When consolidating work items, sync their status to real state. A closed item whose work
  is not done is a lie in the tracker.

## Residual risk

Residual risk MUST have a **destination**: a backlog item, an issue, a named follow-up, an
explicit rejection, or acceptance recorded with an owner.

"Documented as residual risk" is NOT terminal — documentation is the description, not the
destination.

Intentional, documented contracts are not residual risks. Do not inflate the risk list
with decisions that were made on purpose.

## Green-gate expiry

A green gate **expires on the next versioned edit in scope**. After any such edit, rerun
the narrow tests and then the owning gate before saying "still safe".

## Long-running processes

Runtime-loaded edits require an explicit **RESTART REQUIRED** note before any
process-backed smoke test. Failures observed against a stale process are evidence about
the process, not about the product behavior.
