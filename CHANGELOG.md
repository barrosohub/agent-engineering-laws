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

## [1.3.0] - 2026-07-26

Theme: CI on real runners found two environment-dependent gate bugs local green never saw.

### Fixed

- Unbraced `$MIN_LAW_LINES–$MAX_LAW_LINES` in `scripts/check-laws.sh` crashed bash 3.2 under
  `set -u` (the en dash was absorbed into the identifier). Braced to `${MIN_LAW_LINES}–${MAX_LAW_LINES}`.
  Forced by: macOS CI `/bin/bash` 3.2.57, not by inspection. Verified how: braces land; new
  rule `unbraced-nonascii` catches the old form.
- `english-only` no longer uses awk. Ubuntu runners ship mawk (not multi-byte aware), so the
  rule was a DEAD RULE there while GNU awk on the development machine stayed green. Strip
  allowlisted UTF-8 with sed and detect leftovers with grep under `LC_ALL=C`. Forced by:
  Ubuntu CI selftest. Verified how: red-case (accented letter) and twin (allowlisted
  typography) still live; line numbers still refer to the real file.
- Gate scripts pin `LC_ALL=C` once at the top so byte-class rules do not depend on the
  caller's locale. Forced by: the awk/locale class of environment dependence.
- Workflow: `fail-fast: false` on both matrices so one red platform cannot hide the others;
  `push` is limited to branches (tags no longer re-run gates that already passed on that
  commit). Forced by: macOS fail cancelled Windows before `product-tier-inert` was observed;
  three tag pushes burned three full runs.
- CHANGELOG: 1.0.0 has no matching `VERSION` in this repository's git history — the release
  link is removed and the entry states that 1.0.0 predates tracked history. Do not invent a tag.
- `MAINTENANCE.md`: `main` is the distribution branch; promoting to `main` is a release act.
- `README.md` / `llms.txt`: GitHub Pages serves `llms.txt` at
  `https://barrosohub.github.io/agent-engineering-laws/llms.txt`.

### Added

- Gate rule `unbraced-nonascii` (23 → 24): fails when an unbraced `$VAR` is immediately
  followed by a non-ASCII byte in any `scripts/*.sh`. Red-case reintroduces the unbraced
  form; twin proves `${VAR}–` stays silent. Detects exactly the former law-size summary line
  when that form is restored.

### Verified

- Local: `check-laws` and `selftest-gate` exit 0 (24 rules); five consecutive identical
  summaries on a frozen tree; `actionlint` clean.
- bash 3.2 crash and mawk dead-rule: found by executing on real CI runners. Local machine
  has GNU awk and bash 5.x — neither failure mode is fully reproducible here unless a 3.2
  binary or mawk is installed (reported in the change report).

## [1.2.1] - 2026-07-25

Theme: prove the tooling contract in CI, read product-tier modes from git, and stop
compatibility tables from rotting.

### Fixed

- `product-tier-inert` no longer trusts filesystem symlink/executable bits (unreliable on
  Windows / Git Bash). It reads committed modes from the git index (`100644` / `100755` /
  `120000`) and fails clearly outside a git work tree. Forced by: false PASS/FAIL risk on
  Windows. Verified how: harness red-cases stage `100755` and `120000` under `laws/` via
  index operations; tooling-tier executable twin stays silent; clean corpus passes.
- Selftest product-tier cases that previously mixed filesystem mutations with index reads
  now operate only at the index layer the rule inspects: executable via
  `update-index --chmod=+x` only (no filesystem `chmod`); symlink via `hash-object` +
  `update-index --cacheinfo 120000` (Git Bash `ln -s` copies and would leave a dead case);
  tooling twin via `git update-index --chmod=+x` (Windows `core.fileMode=false` would make
  a `chmod`+`git add` twin vacuous). Forced by: scheduled Windows selftest must prove the
  rule, not the host filesystem.
- `README.md` compatibility table replaced with mechanism groups so product renames cannot
  silently rot the docs. Forced by: at least one listed tool already renamed. Verified how:
  facts checked against vendor docs for Claude Code, VS Code `chat.useAgentsMdFile`, Gemini
  `context.fileName`, and Copilot agent-vs-chat split.
- `INSTALL.md`: detect pre-existing root rules files that can shadow `AGENTS.md` on
  first-match-wins resolvers; do not overwrite — same posture as a pre-existing `AGENTS.md`.
  Forced by: `.github/copilot-instructions.md` preceding `AGENTS.md` in at least one editor.
- Workflow trigger key restored to unquoted `on:`. It was briefly quoted only to satisfy
  PyYAML (YAML 1.1 maps bare `on` to a boolean); that is the wrong validator — GitHub's
  parser and every documented example use the bare form, and a wrong key fails silently
  (workflow never runs). Do not re-quote it for a linter. Validated with throwaway
  `actionlint` under `/tmp`. Also: concurrency groups by workflow + event + ref so a push
  cannot cancel the weekly scheduled three-OS selftest (the only bash 3.2 proof); Ubuntu
  selftest skips same-repo `pull_request` when `push` already covers the head (a skipped
  required check would block merges — documented in the workflow comment).

### Added

- `.github/workflows/gates.yml` — checkout@v7; unquoted `on:`; `check-laws` on
  Ubuntu/macOS/Windows every push/PR; `selftest` on Ubuntu only per push (fork PRs still
  covered; same-repo PRs skip by design); full three-OS selftest on a weekly schedule
  (macOS `/bin/bash` is the bash 3.2 proof without macOS minutes on every push);
  concurrency keyed by event so scheduled runs are never cancelled by a push.
  Advisory audit is non-blocking. `GATE_BASH` is set once per job. Forced by: `bash --posix`
  does not remove bash-4 builtins, so prior "posix" runs proved nothing about 3.2.

### Changed

- Selftest subject construction: build a template once (tree + local `git init`/`commit`),
  then `cp -a` per case. **Neutral, not an optimization.** Solo baseline on this host:
  117s for 46 subjects (~2.5s/subject). One `cp -a` measured at 26ms, so all copying is
  ~1% of the run; the cost is running the full 23-rule gate once per case, by design.
  Isolation unchanged (`SUBJECT_SEQ` unique dirs; leak probe passed).
- `AGENTS.md` / `MAINTENANCE.md`: git is a stated tooling dependency for index-mode rules;
  Gemini locked decision points at the one-line settings form in INSTALL/README.
- Patch bump: no law text changed, no gate rule id added, no requirement reversed —
  reimplementation + infrastructure + docs (see versioning policy: patch).

### Verified

- `scripts/check-laws.sh` exit 0 on this host (Linux, bash 5.x).
- `scripts/selftest-gate.sh` exit 0; five consecutive identical summaries on the frozen tree.
- Workflow validated with throwaway `actionlint` under `/tmp` (not PyYAML). Unquoted `on:`
  retained for GitHub's parser.
- macOS/Windows CI legs unproven until the first Actions run — predictions recorded before
  that run (including Windows: symlink red-case fires via cacheinfo; twin is index-meaningful).
- bash 3.2: enforced by `posix-shell-purity`; executed only where a 3.2 binary exists
  (scheduled CI macOS `/bin/bash` — not available on this Linux host).

## [1.2.0] - 2026-07-25

Theme: close the unguarded parallel writers and make the published coordinates real.

### Fixed

- Claude adapter rules under `adapters/claude/rules/` no longer carry a `paths: ["**/*"]`
  frontmatter block. With `paths` set, Claude Code treated them as path-conditional and only
  loaded them after a matching file read — so the git-safety pointer was absent at session
  start. Frontmatter removed; body unchanged. Cursor `.mdc` frontmatter left alone.
- `scripts/render-core.sh` no longer uses bash-only `${var//…}` while declaring `sh`.
  JSON escaping is POSIX `sed`. Verified under busybox `sh`.
- Selftest harness nondeterminism: `subject()` keyed scratch dirs by rule id alone, so seven
  posix cases shared one path and raced `rm -rf`/re-extract; mutations discarded exit status,
  so a no-op mutation looked like a dead rule. Each case/twin now gets a unique scratch dir;
  fingerprints before/after prove the mutation landed; unchanged trees report `BROKEN CASE`,
  not `DEAD RULE`; extraction failure aborts loudly.
- Gate-rule holes closed: per-construct posix red-cases; real over-match twins; 
  `no-placeholder-coordinates` scans `scripts/` (needle assembled at runtime);
  `law-count-consistent` uses number-then-`laws` adjacency; README group table guarded.
- Tooling portability: replaced `mapfile` and `declare -A` with bash-3.2-portable loops;
  replaced GNU `sed -i` in selftest mutations with `sed … > tmp && mv`; extended
  `posix-shell-purity` to forbid bash-4-only and GNU-only constructs in every script.
- Product tier on Windows: `@AGENTS.md` is the primary Claude pointer; this repo's
  `CLAUDE.md` converted from symlink to import; `INSTALL.md` demotes `ln -s` and labels
  shell-specific fallbacks; `scripts/install.sh` writes the import by default.
- Removed the Portuguese blockquote from `README.md` (American English only).

### Added

- Gate rules, 16 → 23:
  - `llms-txt-complete`, `law-count-consistent`, `no-placeholder-coordinates`,
    `posix-shell-purity` (extended), `readme-groups-complete`
  - `english-only` — no non-ASCII letters outside an explicit typographic allowlist
    (em/en dash, arrows, ellipsis, middle dot, section sign, comparisons, box-drawing).
    Catches accented prose; does not catch unaccented non-English.
  - `product-tier-inert` — no symlinks and no executable bits under product-tier paths.
- `.gitattributes` normalizing the working tree to LF (CRLF breaks shell scripts and
  EOL-anchored gate patterns).

### Changed

- Published coordinates resolved to `barrosohub/agent-engineering-laws`.
- `AGENTS.md` / `MAINTENANCE.md` record the two-tier compatibility contract and locked
  decision: no second per-platform tooling implementation.
- `llms.txt`: "Do not fetch all 33" → "Do not fetch all 33 laws".

### Verified

- `scripts/check-laws.sh`: 23 rules, 33 laws, exit 0.
- `scripts/selftest-gate.sh`: five consecutive identical PASS runs; broken-case path proven.
- `scripts/render-core.sh` under busybox `sh`: exit 0.
- `git check-attr text eol` reports LF for scripts and docs.
- Product-tier inert and english-only red-cases and twins live.

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

Initial public corpus. This version predates this repository's git history — there is no
commit with `VERSION` 1.0.0 and no release tag to link. The entry is kept as the narrative
start of the corpus; do not invent a tag.

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

[Unreleased]: https://github.com/barrosohub/agent-engineering-laws/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/barrosohub/agent-engineering-laws/releases/tag/v1.3.0
[1.2.1]: https://github.com/barrosohub/agent-engineering-laws/releases/tag/v1.2.1
[1.2.0]: https://github.com/barrosohub/agent-engineering-laws/releases/tag/v1.2.0
[1.1.0]: https://github.com/barrosohub/agent-engineering-laws/releases/tag/v1.1.0
