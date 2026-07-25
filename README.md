# agent-engineering-laws

**Universal operating laws for coding agents.**

A curated corpus of **33 durable engineering laws** — written as imperatives, free of any
product, vendor, language, or era — that a coding agent loads into whatever repository it is
working in. Install once, and the agent stops making a specific, well-known class of
mistakes.

---

## Start here (agent)

You are an agent and you landed in this repository. Six facts:

1. **What this is:** a corpus of engineering laws, plus an installer that puts them into a
   *different* repository. Nothing here builds, runs, or ships software.
2. **Canonical file:** `AGENTS.md`. Everything else points at it. Never copy it.
3. **To install the laws somewhere:** open the target repository and follow `INSTALL.md`.
4. **To edit the corpus:** read `AGENTS.md` (rules for this repo), then `MAINTENANCE.md`
   (the protocol for changing laws). Both are short.
5. **To verify anything:** `scripts/check-laws.sh && scripts/selftest-gate.sh`. Exit 0 or it
   is not done.
6. **Never** run a git mutation here without an explicit per-operation instruction.

## Start here (human)

Open your coding agent **inside the repository you want to protect** and paste the prompt in
[`INSTALL.md`](INSTALL.md). That is the whole installation.

No agent? Same result:

```sh
git clone --depth 1 https://github.com/barrosohub/agent-engineering-laws /tmp/laws
/tmp/laws/scripts/install.sh --target .
```

Both paths write `./AGENTS.md`, copy `laws/` into `./agent-laws/laws/`, create `CLAUDE.md`
as an `@AGENTS.md` import (or a symlink on Unix), and stop before touching git. Nothing is
committed on your behalf.

---

## Why this exists

Coding agents are good at producing code and weak at *not* producing the wrong code. The
failure classes are stable and recognizable:

- the fix keyed to the one observed instance, instead of the contract that failed;
- the parallel code path added because the existing one was awkward to reach;
- the commit nobody authorized, because a question was read as an instruction;
- the "validated" claim, backed by a test that returned before reaching the new branch;
- the progress indicator left spinning forever on the exception path.

None of these are model failures you can prompt away with encouragement. They are **contract
failures**, and contracts are what laws are for.

## Why `AGENTS.md`

`AGENTS.md` is the open, cross-tool convention for agent instructions
(<https://agents.md/>), stewarded under the Agentic AI Foundation at the Linux Foundation.
One file, read by many tools, instead of one file per tool drifting apart.

Everything else in this repository is a **pointer** to that file, never a copy of it.

---

## How it works

The always-on file is deliberately small. The detail is lazy-loaded.

```text
AGENTS.md  (~180 lines, in context every session)
│
├── Operating core      imperative summary of the irreducible laws
├── Load table          "when you are about to X → read laws/y.md"
└── Project context     the only section a consuming repo edits
```

An agent reads the always-on file every session and reads a law file **only when the task in
front of it matches a row in the table**. Permanent context cost stays near-constant while
the corpus can grow. Each law is self-contained: no URLs, no file paths, no assumed reading
order.

---

## The laws

| Group | Laws |
|---|---|
| **Root-cause discipline** | `attack-root-class` · `never-parallel-contract` · `no-second-model` · `multi-axis-invariants` |
| **Scope & placement** | `scope-discipline` · `reuse-and-placement` · `new-package-fence` · `domain-canonical-sources` |
| **Validation & guards** | `validation-honesty` · `kiss-tests` · `mechanical-guardrails` · `prefer-executable-contract` |
| **Runtime correctness** | `lifecycle-concurrency` · `io-boundary` · `observability-and-routing` · `legacy-state-tolerance` |
| **Boundaries** | `external-boundary` · `new-legacy-boundary` · `adapter-chain` · `external-failure-messages` |
| **Safety** | `git-safety` · `questions-are-not-commands` |
| **Process honesty** | `operational-evidence` · `post-block-reflection` · `reviewer-auto-gate` · `verify-live-file` · `drift-documentation` |
| **Craft** | `debugging` · `pinned-version-websearch` · `hermetic-artifacts` · `engineering-hygiene` · `rule-authoring` · `long-term-memory` |

Full table with load conditions: [`laws/INDEX.md`](laws/INDEX.md).

A sample, so you know the register:

> **Attack the root class** — Name which generic contract failed and strengthen or remove
> THAT contract. Do NOT add a branch keyed to the observed term, tenant, or file. Test: *does
> this break if the next consumer uses different vocabulary?* If yes, it is not a root fix.

> **Git safety** — Authorization IS an imperative naming the operation. Authorization IS NOT
> a readiness question, an intent statement, prior authorization for a different operation,
> or a checklist step that says "commit your work".

---

## Design principles

- **One law, one file, one stable id.** Ids are a contract; renaming one is a major version.
- **Short always-on, detail on demand.** A rule nobody loads protects nothing.
- **One source of truth.** Adapters translate *where to read*, never *what it says*.
- **Imperatives, not observations.** "Never…", "Do…", "MUST…".
- **Timeless by construction.** No years, no version literals, no era words, no vendor names,
  no machine paths, no URLs inside laws. Mechanically enforced, not merely intended.
- **Location-independent.** Laws cite each other by id, so the corpus survives being
  installed under any directory layout.
- **Human-curated beats auto-generated.** The artifact is the sentence.

---

## Compatibility

| Tool | Reads | Status |
|---|---|---|
| Any `AGENTS.md`-aware agent | `AGENTS.md` | native |
| Claude Code | `CLAUDE.md` → `AGENTS.md`, optional `.claude/rules/` | pointer adapter |
| Cursor | `.cursor/rules/*.mdc` → `AGENTS.md` | pointer adapter |
| GitHub Copilot | `.github/copilot-instructions.md` → `AGENTS.md` | pointer adapter |
| OpenCode | `AGENTS.md` | native |
| Any other agent with a custom instructions path | point it at `AGENTS.md` | supported |
| Gemini CLI | point its own configuration at `AGENTS.md` | out of scope, no adapter versioned |

The corpus assumes only that an agent can **read a file** and **follow an instruction**. That
is the entire integration contract, and it is why this survives tool churn.

---

## Self-maintenance

This repository is designed to be maintained by agents, indefinitely, with no human in the
loop. That design is written down, not implied: **[`MAINTENANCE.md`](MAINTENANCE.md)**.

It defines a ten-point constitution, a five-step maintenance cycle, a ten-question admission
test for new laws, a retirement test (laws may die), a terminology-drift protocol for when the
words themselves age, and a catalogue of the ways an unsupervised maintainer degrades a
corpus — each with its counter.

### The gates

| Script | Role | Blocks? |
|---|---|---|
| `scripts/check-laws.sh` | 23 rules over index integrity, routing, hermeticity, temporal coupling, size budgets | **yes** |
| `scripts/selftest-gate.sh` | Proves every rule fires on its own violation, and that none fire on a clean corpus | **yes** |
| `scripts/audit-corpus.sh` | Advisory signals: overlap, vocabulary drift, imperative decay | no |

No gate is infallible — a gate enforces only what is mechanically decidable. What *is*
achievable, and what is implemented here, is a gate that **fails closed**, **tests itself**,
and **cannot be weakened silently**: every rule is registered, every registered rule must have
a red-case, and deleting a rule requires deleting its red-case in the same visible act.

Findings are machine-readable — `FAIL [<rule-id>] <location> — <reason>`. Parse the bracketed
id, never the prose.

```sh
scripts/check-laws.sh && scripts/selftest-gate.sh   # must both exit 0
scripts/audit-corpus.sh                             # read, then judge
```

---

## Repository layout

```text
README.md                     this file
INSTALL.md                    paste-ready installer prompt + fallbacks
MAINTENANCE.md                the self-maintenance protocol
AGENTS.md                     rules for agents editing this repository
CLAUDE.md                     → AGENTS.md
llms.txt                      machine-readable entry points
VERSION / CHANGELOG.md        semver of the corpus, and why each change happened
core/ALWAYS.md                the file installed as AGENTS.md in consumers
laws/INDEX.md                 id | title | path | when_to_load
laws/<id>.md                  one law per file
adapters/                     pointers for Cursor, Claude, Copilot
templates/                    the project-context stub
scripts/                      install · render · check · selftest · audit
```

## Versioning

**major** — a law id is renamed, retired, or reverses its guidance; a constitutional
invariant changes. **minor** — a law is added or materially changed; a gate rule is added.
**patch** — wording and clarifications that change no requirement.

Every major release carries an old-id → new-id mapping in [`CHANGELOG.md`](CHANGELOG.md).

## Contributing

1. Read [`AGENTS.md`](AGENTS.md), then [`MAINTENANCE.md`](MAINTENANCE.md) §3.
2. One law per file, English, imperative, self-contained.
3. Update `laws/INDEX.md`, the load table in `core/ALWAYS.md`, `VERSION`, `CHANGELOG.md`.
4. `scripts/check-laws.sh && scripts/selftest-gate.sh`.

The bar for a new law is deliberately high: a missing law costs one recurring defect class, a
bloated corpus costs every agent's willingness to load any of it.

## Design sources

Informed by, not copied from: <https://agents.md/> ·
<https://cursor.com/docs/rules> · <https://code.claude.com/docs/en/claude-directory> ·
<https://opencode.ai/docs/rules/>

## License

MIT — see [`LICENSE`](LICENSE).

