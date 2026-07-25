# AGENTS.md — working on this blueprint

This repository is a corpus of universal engineering laws for coding agents. It is a
**content product**: the artifact is the wording. Treat prose edits with the same care a
code repository gives to a public API.

If you are here to *use* the laws in another repository, do not read on — follow
`INSTALL.md` inside that repository instead.

**Before changing any law, read `MAINTENANCE.md`.** This file tells you the conventions of
the repository; `MAINTENANCE.md` tells you the protocol for changing the corpus — the
constitution, the admission test for a new law, the retirement test, and the failure modes of
unsupervised maintenance. Assume you are the only maintainer.

## What lives where

| Path | Role |
|---|---|
| `laws/<id>.md` | The canonical corpus. One law, one file, one stable id. |
| `laws/INDEX.md` | `id \| title \| path \| when_to_load` for every law. |
| `core/ALWAYS.md` | The file installed as `AGENTS.md` in consuming repositories. |
| `AGENTS.md` (this file) | Rules for agents editing this blueprint. Not distributed. |
| `MAINTENANCE.md` | The self-maintenance protocol. Read before editing the corpus. |
| `adapters/**` | Pointers to `AGENTS.md`. Never copies of law text. |
| `templates/` | The project-context stub consumers fill in. |
| `scripts/` | Installer, renderer, blocking gate, gate self-test, advisory audit. |

## Hard rules

1. **Keep the always-on file short.** `core/ALWAYS.md` and this file must each stay under
   250 lines; the working target for `core/ALWAYS.md` is ~200. Detail belongs in `laws/`,
   loaded on demand. Never build a thousand-line always-on monolith.
2. **One law, one file, one stable id.** Ids are kebab-case and are a contract. Renaming an
   id is a breaking change: major version bump plus an old→new mapping in `CHANGELOG.md`.
3. **Every corpus change touches the full routing surface.** The law file, `laws/INDEX.md`,
   the lazy-load table in `core/ALWAYS.md`, `llms.txt`, the README group table,
   `CHANGELOG.md`, and every live law-count literal — plus `VERSION` when the release
   warrants it. `llms-txt-complete`, `readme-groups-complete`, and `law-count-consistent`
   enforce the non-index surfaces mechanically. A law absent from any of them is invisible
   or silently wrong.
4. **Do not add a Gemini-specific instruction file.** Out of scope by decision. Gemini users
   point their own configuration at `AGENTS.md`.
5. **Do not couple to vendors.** No proprietary memory products, no crawl or search vendors,
   no per-user home paths, no absolute machine paths, no personal names, no mandatory skill
   packs, no product-specific stacks. Say "long-term memory", not a product name. Say "call
   a WebSearch tool", not a vendor.
6. **`CLAUDE.md` stays a pointer.** Prefer a single `@AGENTS.md` import line (works on every
   OS, including Windows without Developer Mode). A symlink to `AGENTS.md` is an optional
   Unix convenience. Never a copy of the corpus.
7. **Adapters translate location, not content.** A Cursor rule or Copilot instruction file
   says *where to read*, plus at most the irreversible-action rules restated. It never
   inlines law text.
8. **Laws cite laws by id, never by path.** Write ``see law `git-safety` ``, never a filename.
   The corpus must survive being installed under any directory layout.
9. **Nothing in a law may date it.** No years, no version literals, no era words, no URLs.
   Enforced by the `temporal-coupling` and `url-in-law` rules.
10. **American English only.** Every file in this repository is written in American English.
    Enforced for accented prose by `english-only`; unaccented non-English stays a human
    review concern.
11. **Run both gates.** `scripts/check-laws.sh && scripts/selftest-gate.sh` must both exit 0
    before you call anything done. Then read `scripts/audit-corpus.sh`, which is advisory.

## Writing a law

- **English, imperative.** "Never…", "Do…", "MUST…". Not "we tend to", not "it is often
  better to".
- **Self-contained.** A reader must understand the law without reading the rest of the repo.
  Cross-references (`see laws/x.md`) are for depth, never for the core meaning.
- **Universal.** No business domain, no single stack, no one product's vocabulary. If an
  example only makes sense in one industry, generalize it or delete it.
- **Falsifiable.** State what is forbidden and what is accepted. A law nobody could violate
  is decoration.
- **Front matter.** `id` (must equal the filename stem), `title`, `always: false`.
- **Shape.** H1 title, then the rule, then rules/tests/forbidden-vs-accepted sections. Keep
  each law roughly 20–60 lines.

## Adding a law

1. Pick a stable kebab-case id. Check it does not overlap an existing law's territory — two
   laws covering one contract is exactly the parallel-contract smell the corpus forbids.
2. Write `laws/<id>.md`.
3. Add a row to `laws/INDEX.md` with a concrete `when_to_load` condition. The condition must
   describe a task an agent is *about to perform*, not a topic.
4. Add a row to the "External law loading" table in `core/ALWAYS.md`. If the law is
   irreducible, also add one condensed line to the relevant core section — but prefer the
   table.
5. Update `llms.txt`, the README group table, every live law-count literal
   (`laws/INDEX.md` footer, `README.md`, this file, `llms.txt`), and `CHANGELOG.md`.
6. Bump `VERSION`: minor for a new law, patch for clarifications, major for id changes.
7. Run `scripts/check-laws.sh`.

## Editing an existing law

- Sharpening wording is a patch. Changing what the law requires is a minor. Reversing it is
  a major.
- If a law grows past ~60 lines, ask whether it is two laws. Split rather than dilute.
- Never weaken a law to accommodate a single project's convenience. Scope it or drop it.

## The gates

| Script | Role | Blocks |
|---|---|---|
| `scripts/check-laws.sh` | 23 registered rules; findings print as `FAIL [rule-id] location — reason` | yes |
| `scripts/selftest-gate.sh` | Proves each rule fires on its own violation, and none fire on a clean corpus | yes |
| `scripts/audit-corpus.sh` | Advisory signals: overlap, vocabulary drift, imperative decay | no |

Rules cover: index integrity, front-matter ids, H1 titles, duplicate titles, law size floor
and ceiling, load-table completeness and resolution, cross-reference resolution, location
coupling, always-on size budget, environment coupling, temporal coupling, URLs in laws,
compatibility-file shape, gate self-coverage, `llms.txt` bijection, README group-table
bijection, live law-count consistency, unresolved coordinate placeholders, tooling shell
purity (POSIX `sh` + bash 3.2), American-English orthography, and product-tier inertness.

`README.md`, `INSTALL.md`, `MAINTENANCE.md`, `CHANGELOG.md` and `scripts/` are excluded from
the coupling scans on purpose: they must be able to NAME what is out of scope in order to
forbid it.

**A rule cannot be deleted silently.** `selftest-coverage` requires every rule in
`GATE_RULES` to have a matching `case_ <rule>` red-case. Removing a rule means removing its
red-case too, which is a visible act that `MAINTENANCE.md` §1 requires you to record.

If the gate fails, decide which is wrong — the corpus or the gate — and say which in the
change record. Never relocate content to dodge a scan, and never loosen a pattern to make a
finding disappear. An over-matching rule is fixed with a more precise rule plus a twin case.

## Compatibility tiers

This repository has two tiers with different contracts:

- **Product tier** (`core/`, `laws/`, `adapters/`, `templates/`, `llms.txt`, and the
  installed `AGENTS.md` / `CLAUDE.md` pointers): executes nothing. It therefore works on
  every OS and terminal, including Windows cmd and PowerShell. Enforced by
  `product-tier-inert` and by documenting `@AGENTS.md` as the primary Claude pointer.
- **Tooling tier** (`scripts/`): one implementation targeting bash 3.2 plus POSIX utilities
  (Linux, macOS, WSL, BusyBox, Git Bash). Never a second per-platform implementation of the
  same gate — that would be a parallel contract. Enforced by `posix-shell-purity`.

## Git

The laws in this repository apply to work on this repository. In particular
`laws/git-safety.md`: never stage, commit, amend, push, rebase, merge, stash, or create a
pull request without an explicit per-operation imperative from the owner. A question about
readiness is not authorization.

## Project context

- **What this repository is:** a vendor-neutral corpus of 33 universal engineering laws for
  coding agents, distributed as an always-on file plus lazy-loaded law files.
- **Stack:** Markdown and shell. Product tier executes nothing. Tooling tier requires bash
  3.2+, POSIX coreutils, grep, sed, awk. No build, no dependencies, no lockfiles, no network.
- **Quality gate:** `scripts/check-laws.sh && scripts/selftest-gate.sh`
- **Advisory audit:** `scripts/audit-corpus.sh` (never blocks)
- **Render distribution file:** `scripts/render-core.sh` (writes `dist/`, ignored)
- **Install into a target repo:** `scripts/install.sh --target <path>`
- **Locked decisions:** canonical file is `AGENTS.md`; Claude compatibility is a pointer
  (prefer `@AGENTS.md` import); no Gemini instruction file; no vendor coupling; American
  English only; laws cite each other by id; laws carry no dates and no URLs; tooling is
  never duplicated per platform.
- **Non-goals:** tool-specific rule dialects beyond thin pointers; auto-generated laws;
  project-specific or domain-specific guidance; any dependency that must be installed;
  a second per-platform implementation of the tooling tier.
