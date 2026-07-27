---
id: attack-root-class
title: Attack the root class, never the symptom
always: false
---

# Attack the root class, never the symptom

Every fix MUST attack the root class of the problem, never the observed instance.
Situational rules and short blankets are forbidden.

## Before ANY fix

1. **Name the failed contract.** Say out loud which generic contract failed —
   routing, parsing, retrieval, rendering, lifecycle, or state — and strengthen or
   remove THAT contract. Do NOT add a branch, regex, keyword, or list keyed to the
   observed term, tenant, URL, metric, file, prompt, tool, or configuration of one
   consumer.

2. **Domain value is not control flow.** Specific vocabulary belongs in versioned
   data on a generic path, or is derived name-agnostically from the artifact, or is
   deferred to a model. It never becomes a fixed list in code.
   Test: *"does this break if the next consumer uses different vocabulary?"*
   If yes, it is not a root fix.

3. **Open class means mechanical guarantee.** Any matcher, router, regex, or
   vocabulary applied over free text MUST become a searchable or AST-testable
   guardrail with a red-case AND an over-match twin, wired into the quality gate.
   Memory and promises alone do not prevent relapse.

4. **Configuration is also control flow.** Ignore-files, gate presets, manifests,
   CI allowlists, route maps, and feature flags that enumerate one instance by name
   are the same short-blanket failure. If versioning, releasing, or routing one item
   requires naming that item in critical configuration, the rule is wrong — make it
   generic by category, or drop the need.

   **Fence, not exemption.** One enumeration is required, not forbidden: a fail-closed
   declaration of a unit's OWN scope, where anything undeclared is refused or handed
   off untouched. Ask whose names the list holds — the declaring unit's own, or
   foreign ones borrowed from siblings, tenants, or legacy — and what an instance
   nobody listed gets: refused, or quietly granted. Own names plus refusal is a fence,
   and a new unit MUST be declared there in the same change (see law
   `new-package-fence` and law `new-legacy-boundary`). Foreign names, a quiet grant,
   or an entry that also carries a route, threshold, or feature state is the
   exemption this law forbids.

## Rejected shapes

- `if term == "<observed word>"` and its regex equivalents.
- A per-tenant/per-file/per-metric special case added because one report mentioned it.
- A fail-open list that must grow every time a sibling instance appears.
- "We will remember to handle the next one" with no gate guard.

## Accepted shapes

- A generic classifier fed by versioned data.
- A contract removed because it was never load-bearing.
- A parser fixed at the boundary where the shape was misread.
- A guard that fails the build for the whole class, not the one instance.
- A fail-closed fence: any unit it does not declare fails the build.
