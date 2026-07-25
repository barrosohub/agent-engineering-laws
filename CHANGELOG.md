# Changelog

All notable changes to the law corpus are recorded here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the corpus
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Versioning policy for laws

- **major** — a law id is renamed or removed, or a law reverses its guidance.
  Breaking for any consumer whose lazy-load table or tooling references the id.
  A major release MUST include an old-id → new-id mapping table.
- **minor** — a new law is added, or an existing law is materially extended.
- **patch** — clarifications, wording, typos, index and formatting fixes.

Law ids are a contract. Do not rename one without a major bump and a mapping entry.

## [Unreleased]

## [1.1.0] - 2026-07-25

Theme: make the corpus survivable without a human maintainer, and make the gate prove itself.

### Added

- `MAINTENANCE.md` — the self-maintenance protocol for an autonomous maintainer: a ten-point
  constitution with the rule that enforces each invariant, a five-step maintenance cycle
  (observe → admit → verify → apply → record), a ten-question admission test for a new law, a
  retirement test, a terminology-drift protocol for when the words themselves age, a version
  policy, a table of ten failure modes of unsupervised maintenance with counters, an honest
  statement of what gates can and cannot do, and recovery drills.
- `scripts/selftest-gate.sh` — proves every rule declared in the gate fires on its own
  violation (red-case), and that no rule fires on a clean corpus (over-match twin). Reports a
  rule that stopped working as a `DEAD RULE`.
- `scripts/audit-corpus.sh` — advisory, never blocking: size distribution, routing usability,
  law-overlap signal from shared distinctive vocabulary, brand-shaped-token and
  upper-case-only-acronym drift, imperative density against a self-calibrating threshold,
  structural decay, provenance.
- Gate rules, from 8 checks to a registry of 16: `duplicate-title`, `law-size` (floor and
  ceiling), `xref-resolves`, `location-coupling`, `temporal-coupling`, `url-in-law`,
  `selftest-coverage`.
- `selftest-coverage` links the gate to its own red-cases: a rule cannot be removed from
  `GATE_RULES` without also removing its case in the self-test, making erosion visible.
- `scripts/render-core.sh` now also emits `dist/laws.json`, a generated routing manifest for
  tooling that prefers structured input. Generated, never versioned — `laws/INDEX.md` remains
  the single source of truth, so no second writer exists to drift.

### Changed

- **Laws now cite laws by stable id** (``see law `git-safety` ``) instead of by filename.
  Filename references broke as soon as a consumer installed the corpus under a different
  layout. Enforced by `location-coupling`; 17 cross-references converted.
- Gate output is machine-readable: `FAIL [<rule-id>] <location> — <reason>`, with the rule
  registry as the parseable contract. Section summaries can no longer print `ok` beside a
  finding in the same section.
- The gate now fails closed with a distinct exit 2 when the repository layout is absent, so a
  gate that cannot run is never mistaken for a gate that passed.
- `README.md` rewritten: an agent-orientation block first, the failure classes the corpus
  exists to prevent, the three-layer loading model, law groups with sample text, the gate
  table with an explicit statement that no gate is infallible, and layout.
- `llms.txt` rewritten to the conventional format, with a reading protocol that tells an agent
  to fetch the core first and individual laws on demand, plus all 33 laws with load conditions.
- `AGENTS.md` gained the id-citation rule, the no-dating rule, the two-gate requirement, the
  gate table, and the rule against dodging a scan instead of fixing the finding.
- Removed the word "modern" from the tagline and prose. An era word is exactly what the
  `temporal-coupling` rule now forbids inside the corpus.
- `laws/reuse-and-placement` — "≥2 real consumers today" reworded to "that exist now";
  `AGENTS.md` — "2000-line monolith" reworded, both to satisfy `temporal-coupling`.

### Verified

- `scripts/check-laws.sh`: 16 rules, 33 laws, exit 0.
- `scripts/selftest-gate.sh`: 16 checks, every declared rule fires on its own violation and the
  clean corpus passes — no dead rules, no over-match.
- `scripts/install.sh`: clean-target install, overwrite refusal with diff (exit 2), custom
  `--laws-dir` rewrite with all 34 table paths resolving, and the prepend branch preserving
  pre-existing compatibility-file content.
- `dist/laws.json` parses and carries a title and load condition for all 33 laws.
- Two rules were caught over-matching during development and made precise instead of relaxed:
  `location-coupling` (was flagging legitimate mentions of the canonical instruction
  filenames) and the imperative-density signal (a fixed threshold flagged 21 of 33 healthy
  laws; it now calibrates against the corpus mean).

## [1.0.0] - 2026-07-25

### Added

- Initial corpus of 33 universal laws under `laws/`, one law per file with a stable
  kebab-case id.
- `core/ALWAYS.md` — the installable always-on file (~180 lines): operating core, mandatory
  lazy-load table, project-context stub.
- `laws/INDEX.md` — `id | title | path | when_to_load` for every law.
- `INSTALL.md` — paste-ready installer prompt for any coding agent, plus `curl`,
  `scripts/install.sh`, git subtree, and git submodule fallbacks.
- `README.md`, `llms.txt`, `LICENSE` (MIT), `VERSION`.
- Adapters as pointers only: Cursor (`.mdc` rules), Claude (`.claude/rules`), GitHub Copilot
  (`copilot-instructions.md`).
- `templates/project-context.stub.md`.
- `scripts/install.sh` — non-agent fallback installer; refuses to overwrite without
  `--force` and prints a diff first.
- `scripts/render-core.sh` — renders a distribution `AGENTS.md` from `core/ALWAYS.md`.
- `scripts/check-laws.sh` — fails on broken index paths, oversized always-on files, missing
  law metadata, and banned couplings.
- `AGENTS.md` / `CLAUDE.md` for agents working on this blueprint itself.

### Decisions locked in this release

- Canonical instruction file is `AGENTS.md`.
- Claude compatibility is a thin pointer (`CLAUDE.md` symlink or `@AGENTS.md`), never a copy.
- No Gemini-specific instruction file is versioned; it is out of scope by design.
- No coupling to proprietary memory products, crawl or search vendors, per-user absolute
  paths, personal names, mandatory skill packs, or any specific product stack.
- Laws are written in English, as imperatives, and must be understandable without reading
  the rest of the repository.

[Unreleased]: https://github.com/OWNER/REPO/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/OWNER/REPO/releases/tag/v1.1.0
[1.0.0]: https://github.com/OWNER/REPO/releases/tag/v1.0.0
