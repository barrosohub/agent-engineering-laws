---
id: domain-canonical-sources
title: Domain content lives in canonical sources
always: false
---

# Domain content lives in canonical sources

**Domain prose** — definitions, explanations, comparisons, recipes, and rules about
products, runtimes, tenants, tools, metrics, or business policy — belongs in versioned
canonical sources (data files, content stores, documentation under version control).
It does NOT belong in multi-paragraph string literals inside executable code.

**System prose** — busy/retry/degraded/error text, vocatives, severity labels, UI
state, validation messages — MAY live in code. It is part of the program's behavior,
not of the domain.

## Rules

- If a module owns a domain retriever or catalog, add a guardrail against long
  structured domain prose being embedded in that module's source. Scan the class
  (any long literal with domain structure), not the one paragraph you just found.
- Domain content changes must be reviewable by domain owners without reading code.
- A domain fact duplicated in code and in a canonical source is already drifting.
  Delete the copy in code and read from the canonical source.
- Prompts that carry domain knowledge are domain content. Version them as data.
- When a domain fact must be inlined for bootstrapping, mark it explicitly as a
  bootstrap value and point to the canonical source in the same place.

## Test

Ask: *"if the domain owner wants to correct this sentence, do they need a code
release?"* If yes, it is in the wrong place.
