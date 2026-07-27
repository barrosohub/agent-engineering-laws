---
id: lifecycle-concurrency
title: Lifecycle integrity and shared-state concurrency
always: false
---

# Lifecycle integrity and shared-state concurrency

## Lifecycle integrity

Any function that allocates externally-visible state — progress UI, database
transactions, locks, background tasks, notifications, sessions, reservations, typing
indicators, temporary files — MUST release or transition that state on **EVERY** exit
path: success, expected failure, unexpected exception, early return, cancellation, and
timeout.

- Co-locate cleanup with allocation (context managers, `defer`, `finally`, RAII).
- For functions with more than three exit points, add a source-level guard that fails
  when allocation is not paired with co-located cleanup.

## User-visible jobs

- The terminal boundary is the **full user promise**, not the first internal worker's
  completion. Do not mark done when stage one finished.
- After a process restart, NEVER claim that old in-memory work resumed. Start clean from
  persisted input and say so explicitly to the user.
- The **last writer of a visible message owns its final state**. If you replace a
  message, you own closing it.

## Shared mutable state

- Key by **fine identifiers** (request id, job id, transaction id), not only by coarse
  ones (chat id, user id, tenant id).
- Use compare-and-swap on cleanup: only clear the slot if it still holds *your* handle.
- "Last wins" is only correct if it explicitly cancels or replaces the earlier visible
  handle. Otherwise it leaks two visible states.
- Cancellation requires ownership of a real handle. A flag nobody reads is not
  cancellation.
- Do NOT reinvent cross-request busy locks with local session flags when the problem is
  serialization across concurrent requests. Prefer one durable busy-lock primitive.

## Degraded UX

- A partial you **cannot** describe is not a result. When a process was interrupted,
  timed out, canceled, or has not reached its terminal boundary, fail the whole surface
  with one clear, generic message. Never emit the half-rendered partial.
- A partial you **can** describe is different: when one unit fails validation, ship the
  rest and mark that unit's omission on the surface — do not fail the whole (see law
  `legacy-state-tolerance`). If the surface cannot carry that mark, fail the whole and
  name the unit that forced it; never trade a stated omission for an unstated one.
- When severities differ across components, prefer **absence over fabrication**. Showing
  nothing is honest; inventing a value is not.
