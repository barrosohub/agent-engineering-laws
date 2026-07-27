# MAINTENANCE.md — the self-maintenance protocol

**Audience: the autonomous maintainer.** You may be the only maintainer. Assume no human
will review your work, answer a question, or notice a mistake. Everything below is written
so that a competent agent, arriving with no context and no one to ask, can keep this corpus
correct and current indefinitely.

Read this before changing anything in `laws/`, `core/`, or `scripts/`.

---

## 0. Prime directive

**Keep the laws true, universal, and enforceable — and keep them few.**

Every other instruction here serves that sentence. When two instructions appear to conflict,
the prime directive decides. A corpus that grows without bound is a corpus nobody loads; a
corpus that drifts toward one era's tooling is a corpus that expires.

The corpus is not trying to be complete. It is trying to be **irreducible**.

---

## 1. Constitution

These invariants outrank any future improvement. Violating one is not a trade-off; it is a
defect. Each is mechanically enforced where enforcement is possible.

| # | Invariant | Enforced by |
|---|---|---|
| C1 | One law, one file, one stable kebab-case id. | `front-matter-id`, `law-indexed` |
| C2 | A law is understandable alone, cites no URL, and names no file path. | `url-in-law`, `location-coupling` |
| C3 | Laws reference each other by id only. | `xref-resolves`, `location-coupling` |
| C4 | No law names a vendor, product, language, framework, company, or person. | `banned-coupling` + §7 audit |
| C5 | No law is dated: no years, no version literals, no era words. | `temporal-coupling` |
| C6 | The always-on file stays within its line budget; detail lives in `laws/`. | `always-on-size` |
| C7 | Every law is reachable from both the index and the load table. | `law-indexed`, `lazy-load-complete` |
| C8 | Every gate rule has a red-case that proves it fires, and every real selftest case names a registered rule. | `selftest-coverage`, `case-rules-registered`, `selftest-gate.sh` |
| C9 | Compatibility files are pointers, never copies of the corpus. | `claude-pointer` |
| C10 | The repository runs from a clean clone with no network and no package manager. | §8 recovery drill |
| C11 | Product tier executes nothing (committed modes: no symlink, no executable bit under product paths). | `product-tier-inert` |
| C12 | Tooling targets bash 3.2 + POSIX utilities + git where the index is read; never a second per-platform implementation. | `posix-shell-purity` |
| C13 | The corpus is American English; accented non-ASCII letters are rejected. | `english-only` |
| C14 | Shell scripts brace `$VAR` before any non-ASCII byte (bash 3.2 identifier trap). | `unbraced-nonascii` |

**Amending the constitution.** An invariant may be changed only by a change that (a) states
which invariant, (b) states what evidence forced it, (c) updates the enforcing rule *and* its
red-case, and (d) records all of it in `CHANGELOG.md` as a major version. An amendment that
merely *removes* enforcement is not an amendment — it is erosion. Reject it.

### Branch contract

`main` is the **distribution branch**. Every published raw URL and the installer resolve
against `main`. Promoting work to `main` is therefore a release act, not routine housekeeping:
the always-on file, law corpus, and install paths consumers fetch are whatever `main` has.
Validate work on `develop`, where CI runs across all three operating systems. Promote to
`main` only when that validation is green: `main` is distribution through raw URLs, the
installer, and GitHub Pages, and must never serve a red commit.

---

## 2. The maintenance cycle

Run this loop. Each pass is independent; an interrupted pass leaves the repository valid.

```text
OBSERVE → ADMIT → VERIFY → APPLY → RECORD
```

### OBSERVE — gather candidate changes

Sources, in descending order of trust:

1. **Failures the corpus did not prevent.** The strongest signal available. A defect class
   that recurred despite the laws means a law is missing, too weak, or unloadable.
2. **Corpus health.** Run `scripts/audit-corpus.sh`. It reports overlap, drift, and decay
   signals that no blocking gate can judge.
3. **External convention change.** The canonical instruction-file convention, tool
   ecosystems, and protocol standards evolve. Call a WebSearch tool and verify against
   primary sources — the convention's own specification, not commentary. Record what you
   verified and when, in `CHANGELOG.md`.
4. **Terminology drift.** See §5.

Do NOT treat as a source: novelty, a single anecdote, an eloquent argument with no failure
behind it, or the desire to make the corpus look more complete.

### ADMIT — apply the admission test (§3) or the retirement test (§4)

Most candidates die here. That is the point.

### VERIFY — before touching the corpus

- Read the live files. Never edit from a remembered version.
- Search the whole corpus for the contract you think is missing. If any existing law already
  owns it, **extend that law** — a second law over one contract is the parallel-contract
  failure the corpus itself forbids.
- If the change is mechanizable, write the gate rule and its red-case **first**.

### APPLY — the complete change

A corpus change is complete only when all of these are true:

1. `laws/<id>.md` written or edited.
2. `laws/INDEX.md` row added, edited, or removed.
3. The load table in `core/ALWAYS.md` updated — a law absent from it is unreachable.
4. `llms.txt` law entry added, edited, or removed — bijection with the index, enforced by
   `llms-txt-complete`.
5. The README group table updated when the law's group membership changes — enforced by
   `readme-groups-complete` (exactly once per id).
6. Every live law-count literal updated (`laws/INDEX.md` footer, `README.md`, `AGENTS.md`,
   `llms.txt`) — enforced by `law-count-consistent`. Historical `CHANGELOG.md` counts of
   past releases are not rewritten. Every live rule-count literal updated (`README.md`,
   `AGENTS.md`) — enforced by `rule-count-consistent`.
7. Any new gate rule added to `GATE_RULES` in `scripts/check-laws.sh` **with** a matching
   `case_ <rule>` in `scripts/selftest-gate.sh`.
8. `VERSION` bumped per §6.
9. `CHANGELOG.md` entry written.

### RECORD — provenance

The `CHANGELOG.md` entry states **what changed, what forced it, and what was verified how**.
An entry that says "improved wording" records nothing. An entry that says "law X did not
prevent defect class Y observed in Z; tightened clause 3; red-case added" is a fact a future
maintainer can audit.

Then run both gates:

```sh
scripts/check-laws.sh && scripts/selftest-gate.sh
```

Both must exit 0. A failing gate is never "worked around" — see §8.

---

## 3. Admission test for a new law

A candidate becomes a law only if it passes **all ten** questions. One "no" is a rejection.
Record rejections in `CHANGELOG.md` when the candidate is likely to recur; a rejected idea
that keeps returning is cheaper to refute once, in writing.

1. **Failure-backed** — does a real, observed failure class motivate it? (Not a hypothetical.)
2. **Timeless** — would it have been true before the current generation of tools existed, and
   will it still be true after they are gone? Strip every proper noun; does it survive?
3. **Universal** — does it hold in any language, any stack, any domain, any repository size?
4. **Non-overlapping** — does no existing law already own this contract? Name the closest one
   and say why extending it is worse.
5. **Falsifiable** — can you state the concrete action it forbids, and the one it requires?
   A law nobody could violate is decoration.
6. **Actionable at decision time** — does it change what an agent does *before* the mistake,
   not just how it apologizes after?
7. **Load-conditioned** — can you write a `when_to_load` line describing a task an agent is
   *about to perform*? A law with no trigger is never read.
8. **Mechanizable or explicitly not** — if it is searchable or AST-testable, are you shipping
   the gate rule with it? If it is not mechanizable, say so in the change record.
9. **Irreducible** — does removing it lose something the rest of the corpus does not cover?
10. **Within budget** — does it fit the law size limits, and does the load table stay usable?
    If the corpus has grown past comfortable routing, the correct move is a **merge or a
    retirement**, not another row.

**Bias to reject.** The cost of a missing law is one recurring defect class. The cost of a
bloated corpus is that agents stop loading any of it. The second cost is larger and silent.

---

## 4. Retirement test

Laws may die. A corpus that only grows is a corpus decaying at a constant rate.

Retire a law when **any** is true:

- Its contract is now enforced universally by tooling, languages, or platforms, so no agent
  can violate it.
- It was written against a technology assumption that no longer holds, and the generalized
  version is already covered elsewhere.
- It has been absorbed by another law and now only restates it.
- It is unfalsifiable in practice — no observable action would violate it.

**Retirement procedure.** Delete the file; remove its index row, load-table row, and
`llms.txt` entry; update the README group table and every live law-count literal; bump
**major**; record the id in `CHANGELOG.md` under a `Retired` heading with the reason. Never
silently reuse a retired id for a different rule — ids are permanent identifiers, and a
consumer's tooling may still reference the old one.

**Merging two laws** is a retirement plus an edit: the surviving id absorbs the content, the
absorbed id is retired with a pointer to the survivor.

---

## 5. Terminology drift protocol

The corpus is written in the vocabulary of one era and must be read in another. Words like
*agent*, *repository*, *commit*, *test*, *model*, *package* may narrow, widen, or disappear.

When a term in the corpus no longer means what it meant:

1. **Do not rename the concept away.** First ask what invariant the word was pointing at.
   `git-safety` is really *"irreversible shared-state mutation requires per-operation
   authorization"*. That survives the death of any particular version-control system.
2. **Generalize the wording; keep the id.** Ids are a contract (C1). A law may be reworded to
   speak about the general mechanism while keeping its id, with the change recorded as a
   minor version. This is the normal, expected evolution.
3. **Retire only if the invariant itself died**, not the word for it.
4. **Never rename the repository or the canonical instruction filename** casually. Those are
   addresses other systems resolve. Changing an address breaks consumers who cannot ask why.

When a *new* mechanism appears that the corpus has no word for, prefer describing it by its
**contract** (what promise it makes, what breaks when it fails) rather than by its brand.

---

## 6. Version policy

| Bump | When |
|---|---|
| major | A law id is renamed, retired, or reverses its guidance. A constitutional invariant changes. |
| minor | A law is added, or an existing law materially changes what it requires. A gate rule is added. Any change to the set of rule ids the gate can emit (ids are a parsed contract). |
| patch | Wording, clarification, index or formatting fixes that change no requirement. |

Every major release carries an old-id → new-id mapping table in `CHANGELOG.md`.

---

## 7. Failure modes of autonomous maintenance

These are the ways an unsupervised maintainer degrades a corpus. Each has a counter. Check
yourself against this list before applying any change.

| Failure mode | Symptom | Counter |
|---|---|---|
| **Corpus bloat** | Law count only rises; every review adds, none remove. | §3 Q9–Q10 and the bias to reject. Run §4 on the whole corpus periodically. |
| **Recency bias** | Laws start describing the tooling generation the maintainer was trained in. | §3 Q2. Strip proper nouns and re-read. |
| **Stack capture** | Examples quietly assume one language's idioms. | `audit-corpus.sh` proper-noun report; C4. |
| **Law inflation** | Ordinary advice is promoted to MUST, so MUST stops meaning anything. | Reserve emphasis for irreversible or silent-failure classes. |
| **Semantic reversal** | A "clarification" inverts a requirement without a major bump. | Diff the imperative verbs, not the prose. Any change to a MUST/NEVER is at least minor. |
| **Gate erosion** | Rules are relaxed to make a change pass. | C8 plus `selftest-coverage`. Relaxing a rule requires deleting its red-case, which is visible. |
| **Self-citation loop** | The corpus justifies a new law by quoting itself. | §3 Q1: only an observed failure admits a law. |
| **Cargo-culting a standard** | An external convention is adopted because it is popular, not because it serves the prime directive. | Verify against the primary specification, state what problem adopting it solves. |
| **Silent scope creep** | The repository grows features (tooling, integrations) beyond a corpus and its installer. | The non-goals in `AGENTS.md` are binding. |
| **Fabricated provenance** | Change records assert verification that never happened. | Record only what you actually ran or read, with what you observed. |

---

## 8. Resilience: what the gates can and cannot do

**Honest statement: no gate is infallible.** A gate can only enforce what is mechanically
decidable. What *is* achievable — and what this repository implements — is a gate that
**fails closed**, **tests itself**, and **cannot be weakened silently**:

- `scripts/check-laws.sh` blocks. It exits non-zero on any finding, exits 2 if it cannot run,
  and treats an internal error as a failure — never as a pass.
- `scripts/selftest-gate.sh` proves every declared rule fires on its own violation
  (red-case) and that no rule fires on a clean corpus (over-match twin). A rule that stops
  working is reported as a **dead rule**.
- The `selftest-coverage` and `case-rules-registered` rules link the registry and cases in
  both directions: a rule cannot be deleted from the gate without also deleting its red-case,
  and an unregistered real case cannot hide in the selftest.
- `scripts/audit-corpus.sh` is **advisory, never blocking**. It reports judgement-dependent
  signals — overlap, vocabulary drift, structural decay. Blocking on a heuristic would teach
  maintainers to fight the gate; that is how gates die.

The split is deliberate: **block on the mechanically certain, report on the judgement-bound.**

### When the gate itself is wrong

A failing gate has two possible causes, and you must decide which before acting:

1. **The corpus is wrong** → fix the corpus.
2. **The gate is wrong** → fix the gate, and say so explicitly in the change record.

**Never** move content to a location the gate does not scan, delete the offending law, or
loosen a pattern to make a finding disappear. If a rule over-matches, the fix is a more
precise rule *plus* a twin case proving the legitimate input now passes.

### Recovery drills

Run these periodically. Each is a claim that must be re-earned, not remembered.

- **Clean-clone drill** — copy the repository to an empty directory with no network and run
  both gates. Anything that fails was depending on ambient state (C10).
- **Install drill** — `scripts/install.sh --target <empty dir>`, then confirm every path in
  the produced load table resolves, and that a second run refuses to overwrite.
- **Dead-rule drill** — `scripts/selftest-gate.sh`. Any `DEAD RULE` line means the corpus has
  been running unprotected on that axis.
- **Corruption recovery** — if the corpus is damaged and no history is available, the corpus
  is reconstructible from `laws/INDEX.md` (ids, titles, load conditions) plus `core/ALWAYS.md`
  (the condensed statement of every law). Keep both intact; they are the redundancy.

---

## 9. What must never be automated away

- **The admission decision.** Generating a plausible law is easy; deciding it is irreducible
  is the whole job.
- **The judgement of whether an external standard should be adopted.**
- **The wording.** This is a content product. The artifact is the sentence.

Automate the checking. Do not automate the deciding.
