---
id: legacy-state-tolerance
title: Strict validation for new data; legacy tolerates
always: false
---

# Strict validation for new data; legacy tolerates

Strict validators apply ONLY to newly written data.

Persisted legacy state gets one of three treatments:

1. **Tolerance** — accept the older shape and read it correctly.
2. **Self-heal on read** — normalize on load and write back the current shape.
3. **Explicit migration** — a versioned, reversible, evidenced migration.

Never retroactively fail-closed on states that an older contract legitimately wrote.
Data written under a contract that was valid at the time is not corrupt data.

## Degrade the unit, not the artifact

- When one unit inside an artifact fails validation, degrade THAT unit. Never reject the
  entire artifact, document, batch, or page because one element is malformed.
- Never let a secondary write or a secondary validation failure erase an already computed
  primary result. Persist the primary result first, then attempt the secondary work, and
  report secondary failure as secondary.

## Test

Ask: *"if I deploy this validator, does yesterday's legitimate data stop loading?"*
If yes, you have shipped a data outage, not a validation improvement.
