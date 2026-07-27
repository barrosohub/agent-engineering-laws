# Law index

Every law is one file with a stable kebab-case id. Load a law only when the
`when_to_load` condition matches the task in front of you. Do NOT preload all laws.

| id | title | path | when_to_load |
|---|---|---|---|
| `attack-root-class` | Attack the root class, never the symptom | `laws/attack-root-class.md` | Fixing a bug, or adding a keyword/regex/if-branch/allowlist keyed to an observed instance |
| `never-parallel-contract` | Never invent a parallel contract | `laws/never-parallel-contract.md` | Adding a second code path, second writer, wrapper, or test harness over existing behavior |
| `domain-canonical-sources` | Domain content lives in canonical sources | `laws/domain-canonical-sources.md` | Writing domain prose, catalogs, definitions, or prompts that carry domain knowledge |
| `validation-honesty` | Validation honesty | `laws/validation-honesty.md` | Claiming a change is validated, or running a measurement battery |
| `kiss-tests` | KISS applies to test creation | `laws/kiss-tests.md` | Creating or expanding tests |
| `drift-documentation` | Drift documentation discipline | `laws/drift-documentation.md` | Two authoritative surfaces disagree and you do not own the product decision |
| `mechanical-guardrails` | Mechanical guardrails | `laws/mechanical-guardrails.md` | Introducing a durable rule that is searchable or AST-testable |
| `prefer-executable-contract` | Prefer executable contract over new versioned prose | `laws/prefer-executable-contract.md` | About to version new prose to protect a contract |
| `reuse-and-placement` | Reuse before reinvention; place by ownership | `laws/reuse-and-placement.md` | Introducing shared helpers, settings, registries, or primitives; deciding where code lives |
| `scope-discipline` | Scope discipline for spec-driven changes | `laws/scope-discipline.md` | Executing a spec-driven or multi-file change |
| `legacy-state-tolerance` | Strict validation for new data; legacy tolerates | `laws/legacy-state-tolerance.md` | Validating or migrating persisted legacy state |
| `new-package-fence` | A new package is born without a fence | `laws/new-package-fence.md` | Creating a new production package, module, or namespace |
| `multi-axis-invariants` | Single-metric invariants are gameable | `laws/multi-axis-invariants.md` | Protecting a migration or refactor with a numeric invariant |
| `external-boundary` | The external boundary is a different risk class | `laws/external-boundary.md` | Shipping a slice that talks to the external world (chat, email, webhook, UI, public API) |
| `new-legacy-boundary` | A new system declares its own scope | `laws/new-legacy-boundary.md` | Cutting a new system over beside a legacy one |
| `adapter-chain` | New parameters cross the whole adapter chain | `laws/adapter-chain.md` | Adding a parameter across caller, interface, adapter, and core |
| `no-second-model` | No second model over deterministic candidates | `laws/no-second-model.md` | Adding a model stage that reviews, repairs, or reconciles another model's output |
| `git-safety` | Git safety and irreversible action — no exceptions | `laws/git-safety.md` | About to destroy or publish state no committed ref restores — git mutation, PR/release, dropping a store or tree, rotating a credential, a real send |
| `questions-are-not-commands` | Interpretation discipline — questions are not commands | `laws/questions-are-not-commands.md` | Interpreting whether the user authorized an irreversible action |
| `resolve-ambiguity-first` | Resolve ambiguity before the work | `laws/resolve-ambiguity-first.md` | Interpreting a request that admits more than one reading with different deliverables |
| `lifecycle-concurrency` | Lifecycle integrity and shared-state concurrency | `laws/lifecycle-concurrency.md` | Touching lifecycle, background jobs, locks, sessions, or visible progress state |
| `observability-and-routing` | Observability at boundaries; route from canonical evidence | `laws/observability-and-routing.md` | Fixing a pipeline, classifying requests, or emitting identity-bound values |
| `io-boundary` | I/O boundary safety | `laws/io-boundary.md` | Consuming external or untrusted data, especially in last-resort consumers |
| `hermetic-artifacts` | Hermetic versioned artifacts; docs-as-contract | `laws/hermetic-artifacts.md` | Adding versioned inputs, renaming doc contracts, or sanitizing examples |
| `debugging` | Debugging discipline | `laws/debugging.md` | Diagnosing a bug, a regression, or a suspicious match count |
| `pinned-version-websearch` | Idiomatic by pinned version, verified by web search | `laws/pinned-version-websearch.md` | Using third-party APIs or libraries, or asserting a vendor fact |
| `external-failure-messages` | External-failure messages are a contract | `laws/external-failure-messages.md` | Writing user-facing messages about failed external dependencies |
| `operational-evidence` | Operational evidence, closeout, residual risk, green-gate expiry | `laws/operational-evidence.md` | Claiming operational validation, closing work items, or reporting residual risk |
| `reviewer-auto-gate` | Reviewer auto-gate; second reader | `laws/reviewer-auto-gate.md` | Acting as reviewer or second reader, or receiving a reviewer request |
| `verify-live-file` | Verify the live file, not a cached context snapshot | `laws/verify-live-file.md` | Accusing a docs or convention violation, or judging a docs-as-contract question |
| `post-block-reflection` | Post-block reflection checklist | `laws/post-block-reflection.md` | Closing an implementation block as done |
| `rule-authoring` | Rule authoring meta | `laws/rule-authoring.md` | Authoring or editing agent rule files |
| `long-term-memory` | Long-term memory stores universal laws | `laws/long-term-memory.md` | Storing a durable lesson for future sessions |
| `engineering-hygiene` | Everyday engineering hygiene | `laws/engineering-hygiene.md` | Writing comments, deleting code, or claiming backward compatibility |

**34 laws.**

## Stability

Law ids are a contract. Renaming an id is a breaking change and requires a major version
bump plus a `CHANGELOG.md` entry mapping old id to new id.

## Referencing

Laws cite each other by **id**, never by path or filename — the corpus must keep working
when installed under any directory layout. Write ``see law `git-safety` ``, not a filename.
Enforced by the `location-coupling` and `xref-resolves` rules.
