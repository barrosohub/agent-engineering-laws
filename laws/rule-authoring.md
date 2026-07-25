---
id: rule-authoring
title: Rule authoring meta
always: false
---

# Rule authoring meta

## Where a rule goes

- **Cross-tool constraints** → the universal always-on file (`AGENTS.md`).
- **Tool-specific thin wrappers** → that tool's own entry file, pointing at `AGENTS.md`,
  plus path-scoped rules where the tool supports them.
- Never duplicate the corpus across tool files. One source of truth; adapters translate
  only *where to load from*.

## Which mechanism

| Mechanism | Use for |
|---|---|
| Rule | Always-on policy — short, imperative, durable |
| Skill / command | On-demand procedure with steps |
| Hook / CI gate | Deterministic enforcement that cannot be forgotten |

If a rule can be enforced by a gate, prefer the gate (see law `mechanical-guardrails`).

## Scoping

Leave a rule unscoped only for baseline quality and non-negotiable safety. Everything else
is path-scoped to the surface it governs.

## Style

- Keep rules short. Split when cohesion breaks; do NOT duplicate across files.
- Prefer **imperatives over observations**: "Never X", "Do Y", "MUST Z" — not "we tend to".
- Use emphasis markers (MUST, NEVER) for critical constraints only, so they keep meaning.

## Never put in rules

- Step-by-step workflows (those are skills).
- Large third-party API documentation (verify upstream instead —
  see law `pinned-version-websearch`).
- Anything a linter or formatter already enforces.
- Long code dumps.
- Authorial history, changelog gossip, or branch-specific state.
- Aspirational TODOs and "eventually we will" statements.
- Self-evident advice ("write good code").

## Feature-coupling audit

Write rules generically unless they are deliberately owner-scoped. A rule naming one
feature, tenant, or vendor is a short blanket (see law `attack-root-class`).
