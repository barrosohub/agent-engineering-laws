# Operating laws

Universal engineering laws for coding agents. This file is always loaded. Detail lives in
`agent-laws/laws/*.md` and is loaded on demand via the table below.

## Principles

- Clean Code, DRY, KISS, YAGNI. Prefer boring, obvious solutions.
- Strong typing. Prefer specific types over permissive catch-alls.
- Single responsibility per unit.
- Fix at the right abstraction level: the root class, never the observed instance.
- Versioned artifacts are hermetic — they work from a clean clone.
- Sanitize without destroying diagnostic signal.
- Docs-as-contract: grep consumers before renaming a heading, column, status, or id.
- Generated outputs stay local. Quality gates MUST NOT require ignored artifacts.
- Durable instruction hygiene: no branch gossip or session state in always-loaded rules.
- Comments are facts. No ticket archaeology, no aspirational "eventually".

## Attack the root class

- Name the failed contract — routing, parsing, retrieval, lifecycle, rendering, state —
  and strengthen or remove THAT contract.
- Domain value is not control flow. Specific vocabulary goes in versioned data on a
  generic path, is derived name-agnostically, or is deferred to a model.
- Open class ⇒ mechanical guardrail with a red-case AND an over-match twin.
- Configuration is also control flow. Never add a name-keyed exemption for one instance;
  a default-deny list that fails on anything unlisted is the accepted shape.

## Never invent a parallel contract

No duplicate code paths, no second writer over one artifact, no wrapper without a contract
boundary, no test harness that re-implements production dispatch. Dual paths are bugs.

## Domain content in canonical sources

Domain prose (products, tenants, metrics, business rules) belongs in versioned data.
System prose (busy/retry/degraded/error text, labels, validation messages) may live in code.

## Validation honesty

- Inspect full output, not previews. Assert binary contracts.
- Include the real user phrasing or payload that triggered the work.
- A test that short-circuits before the new logic is a routing test, NOT validation.
  At least one case MUST exercise every new branch.

## KISS for tests

Minimal sharp tests, one per real contract, each with a red-case. No ornamental,
duplicated, or speculative tests. Minimizing quantity is NOT skipping real risk.

## Mechanical guardrails

If a rule is searchable or AST-testable, ship a gate guard. A green gate is consistent with
a broken guard — every guard needs a red-case, and open classes need an over-match twin.

## Prefer executable contract over new prose

Guard or test > extend an existing doc > new doc. No seasonal contracts as permanent law.

## Reuse before reinvention

- Audit existing primitives before adding a setting, registry, helper, or client.
- Shared changes are opt-in; the default preserves prior global behavior.
- Code defined but never called is usually abandoned wiring — check cancel, error, and
  cleanup paths before deleting.

## Placement by ownership

- One consumer ⇒ that owner's package. A shared home needs ≥2 real consumers.
- If a guard fails, ask whether the guard is the failed contract. Fix the guard or fix the
  code — NEVER move code to evade a guard.
- Creating a new production package ⇒ ship its fence in the same change.

## Scope discipline

- Owner-named surfaces are the anchor. Everything outside is tolerance only.
- Sweep inventories are tolerance lists, never feature lists.
- Non-goals are hard. Owner scope beats abstract "completeness".
- Wide blast (roughly >20 files) ⇒ scope manifest + mechanical guard before "ready".
- Strict validation applies to new data only. Legacy state is tolerated, self-healed, or
  migrated — never retroactively rejected.
- Degrade the failing unit, not the whole artifact.

## Git safety and irreversible action

- Any act you cannot undo alone needs an explicit, per-operation imperative from the human:
  git mutation, publish, release, drop, delete, credential rotation, real send.
- Questions are not authorization. Skill checklists are not authorization.
- Never destroy live state to fake a clean baseline; "ready" is a claim, not an instruction.
- NEVER add agent `Co-authored-by:` trailers; inspect the commit body after commit/amend.
- If in doubt: STOP, report state, ask, wait.

## Interpretation

Questions ask for state; imperatives authorize. Prior authorization does not extend to the
next irreversible operation. If you acted without authorization, stop the chain, surface it,
propose reversible remediation, wait.

## Lifecycle and concurrency

- Externally-visible state is released or transitioned on EVERY exit path.
- Key shared state by fine id; compare-and-swap on cleanup; cancellation needs real handles.
- After restart, never claim in-memory work resumed. Start clean and say so.
- Degraded UX: a partial you cannot describe fails whole and generically; a marked unit
  omission ships the rest. Absence over fabrication.

## Debugging

- Confirm which path actually executes. Capability is not reachability.
- Short regex tokens need boundaries; boundaries must be unicode-aware for accented text.
- Reconfirm the live repro before writing code. Backlog items are hypotheses.

## External integrations

- Verify vendor facts by calling a WebSearch tool against the docs for the PINNED version.
  Cite source and date. Never trust a local constant as the truth for an external limit.
- Test doubles mirror real vendor signatures.
- External failure messages are a contract: concrete discriminator, human failure class plus
  effort made, at least one next step, and different text per failure mode. No
  implementation jargon on user surfaces.

## Post-block reflection

- Reflect on the real diff, the tests actually run, and observed behavior — not memory.
- Residual risk MUST have a destination.
- A green gate expires on the next versioned edit in scope.
- Operational evidence needs actor and timestamp.
- Lifecycle, concurrency, and security diffs get a second reader before "ready".

## External law loading (mandatory)

When a task matches a row below, use your Read tool to load THAT file before implementing.
Do not preload all laws.

| When you are about to… | Read |
|---|---|
| Fix a bug / add a keyword/regex/if-branch keyed to an observed instance | `agent-laws/laws/attack-root-class.md` |
| Add a second code path, writer, wrapper, or harness over existing behavior | `agent-laws/laws/never-parallel-contract.md` |
| Write domain prose, catalogs, or knowledge-carrying prompts | `agent-laws/laws/domain-canonical-sources.md` |
| Claim a change is validated, or run a measurement battery | `agent-laws/laws/validation-honesty.md` |
| Create or expand tests | `agent-laws/laws/kiss-tests.md` |
| Find two authoritative surfaces disagreeing | `agent-laws/laws/drift-documentation.md` |
| Introduce a durable rule that is searchable or AST-testable | `agent-laws/laws/mechanical-guardrails.md` |
| Version new prose to protect a contract | `agent-laws/laws/prefer-executable-contract.md` |
| Introduce shared helpers/settings/primitives, or decide where code lives | `agent-laws/laws/reuse-and-placement.md` |
| Execute a spec-driven / multi-file change | `agent-laws/laws/scope-discipline.md` |
| Validate or migrate persisted legacy state | `agent-laws/laws/legacy-state-tolerance.md` |
| Add a second model stage over another model | `agent-laws/laws/no-second-model.md` |
| Create a new production package/namespace | `agent-laws/laws/new-package-fence.md` |
| Protect a migration with a numeric invariant | `agent-laws/laws/multi-axis-invariants.md` |
| Ship a slice that talks to the external world | `agent-laws/laws/external-boundary.md` |
| Cut a new system over beside legacy | `agent-laws/laws/new-legacy-boundary.md` |
| Add a parameter across caller/adapter/core | `agent-laws/laws/adapter-chain.md` |
| Destroy or publish state no committed ref restores (git mutation, PR/release, drop, credential, real send) | `agent-laws/laws/git-safety.md` |
| Judge whether the user authorized an irreversible action | `agent-laws/laws/questions-are-not-commands.md` |
| Interpret a request that admits more than one reading with different deliverables | `agent-laws/laws/resolve-ambiguity-first.md` |
| Touch lifecycle, jobs, locks, visible progress | `agent-laws/laws/lifecycle-concurrency.md` |
| Fix a pipeline, classify requests, or emit identity-bound values | `agent-laws/laws/observability-and-routing.md` |
| Consume external or untrusted data | `agent-laws/laws/io-boundary.md` |
| Add versioned inputs, rename a doc contract, or sanitize examples | `agent-laws/laws/hermetic-artifacts.md` |
| Diagnose a bug, regression, or suspicious match count | `agent-laws/laws/debugging.md` |
| Use third-party APIs / libraries | `agent-laws/laws/pinned-version-websearch.md` |
| Write user-facing external failure messages | `agent-laws/laws/external-failure-messages.md` |
| Claim operational validation, close work items, report residual risk | `agent-laws/laws/operational-evidence.md` |
| Act as reviewer / second reader | `agent-laws/laws/reviewer-auto-gate.md` |
| Accuse a docs/convention violation | `agent-laws/laws/verify-live-file.md` |
| Close a block as "done" | `agent-laws/laws/post-block-reflection.md` |
| Author or edit agent rule files | `agent-laws/laws/rule-authoring.md` |
| Store durable lessons | `agent-laws/laws/long-term-memory.md` |
| Write comments, delete code, or claim backward compatibility | `agent-laws/laws/engineering-hygiene.md` |

## Project context

<!-- The ONLY section a consuming repository edits. Fill in verifiable facts only.
     Everything unknown stays TODO. Do not invent stack, commands, or owners. -->

- **What this repository is:** TODO
- **Stack and pinned versions (from lockfiles):** TODO
- **Install:** TODO
- **Run:** TODO
- **Test / quality gate command:** TODO
- **Lint / format command:** TODO
- **Directory ownership map:** TODO
- **Locked decisions (do not reopen):** TODO
- **Non-goals:** TODO
