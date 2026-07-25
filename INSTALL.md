# Install

## How to use this file

Open the coding agent of your choice **inside the repository you want to install the laws
into**, and paste the prompt below verbatim. Any modern coding agent with file read/write
and a shell can execute it.

If your agent has no network access, clone this repository next to the target repository
first and tell the agent to copy from that local path instead of fetching.

---

## Paste this into your agent

```text
You are installing a set of universal engineering laws into THIS repository.
Source repository: https://github.com/OWNER/REPO  (raw base:
https://raw.githubusercontent.com/OWNER/REPO/main/)

Execute these steps in order. Report what you did at the end. Do not skip step 8.

1) INSTALL THE ALWAYS-ON FILE
   - Read the source file `core/ALWAYS.md`.
   - If `./AGENTS.md` does NOT exist: write `core/ALWAYS.md` to `./AGENTS.md`.
   - If `./AGENTS.md` DOES exist: do NOT overwrite it. Show me a diff between the
     existing file and the source, tell me what would be lost, and STOP. Wait for my
     instruction.

2) INSTALL THE LAW CORPUS
   - Copy the whole source `laws/` directory (all `*.md`, including `INDEX.md`) to
     `./agent-laws/laws/`.
   - Open `./AGENTS.md` and make every path in the "External law loading" table point at
     the real local location. If you installed to `./agent-laws/laws/`, the paths already
     match. If the repository convention requires a different location, use it and rewrite
     every row of the table plus the `INDEX.md` paths to match. The table MUST resolve.

3) CLAUDE COMPATIBILITY
   - Create `./CLAUDE.md` as a symlink to `AGENTS.md`:
       ln -s AGENTS.md CLAUDE.md
   - If symlinks are unavailable (Windows without developer mode, some sandboxes) or
     `./CLAUDE.md` already exists with Claude-only content: do NOT delete anything.
     PREPEND a first line containing exactly:
       @AGENTS.md
     and keep the existing content below it.
   - Never duplicate the law corpus into `CLAUDE.md`. One source of truth.

4) DO NOT CREATE ANY OTHER TOOL-SPECIFIC MEMORY FILE
   - In particular, do NOT create a Gemini-specific instruction file (GEMINI.md).
     It is out of scope for this blueprint. Gemini CLI users point their own
     configuration at `AGENTS.md`.

5) OPTIONAL ADAPTERS — install only the ones this repository actually uses
   - Cursor:   copy source `adapters/cursor/rules/*.mdc` to `./.cursor/rules/`
   - Claude:   copy source `adapters/claude/rules/*.md` to `./.claude/rules/`
   - Copilot:  copy source `adapters/github/copilot-instructions.md` to
               `./.github/copilot-instructions.md`
   - These are pointers, not copies of the corpus. Do not inline law text into them.

6) FILL IN PROJECT CONTEXT
   - Edit ONLY the `## Project context` section at the bottom of `./AGENTS.md`.
   - Fill in facts you can verify in THIS repository right now: what it is, stack and
     pinned versions read from lockfiles, install/run/test/lint commands found in
     manifests or CI config, directory ownership.
   - Everything you cannot verify stays `TODO`. Do NOT guess commands or versions.
   - No machine-local absolute paths.

7) RESTART
   - Tell me to restart my agent session so the new instruction files are loaded.

8) DO NOT COMMIT
   - Do NOT run `git add`, `git commit`, `git push`, or create a branch, PR, or release.
   - Leave the changes in the working tree and list every file you created or modified.
   - I will review and commit myself.
```

---

## Fallbacks

### Direct fetch (no agent)

```sh
# always-on file
curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/core/ALWAYS.md -o AGENTS.md
ln -s AGENTS.md CLAUDE.md

# law corpus (needs the repo listing; simplest is a shallow clone, see below)
```

### Shallow clone + script

```sh
git clone --depth 1 https://github.com/OWNER/REPO /tmp/agent-engineering-laws
/tmp/agent-engineering-laws/scripts/install.sh --target .
```

`scripts/install.sh` refuses to overwrite an existing `AGENTS.md` without `--force`, and
prints a diff first. It never creates a Gemini instruction file.

### git subtree (vendored, updatable)

```sh
git subtree add --prefix agent-laws https://github.com/OWNER/REPO main --squash
# later
git subtree pull --prefix agent-laws https://github.com/OWNER/REPO main --squash
```

Then point the lazy-load table at `agent-laws/laws/`.

### git submodule (pinned to a commit)

```sh
git submodule add https://github.com/OWNER/REPO agent-laws
git submodule update --init --recursive
```

Submodules pin a commit, which is the strictest option: the laws cannot change under you
until you bump the pointer.

---

## Verifying the install

1. `./AGENTS.md` exists and its "External law loading" table paths all resolve on disk.
2. `./CLAUDE.md` is a symlink to `AGENTS.md`, or its first line is `@AGENTS.md`.
3. `./agent-laws/laws/INDEX.md` exists and every path it lists exists.
4. The `## Project context` section contains verified facts or explicit `TODO`s — no guesses.
5. Ask your agent: *"which law file covers git mutations?"* It should answer
   `laws/git-safety.md` by reading the table, not from memory.

## Updating

Re-run the install prompt. Step 1 will detect the existing `AGENTS.md`, show a diff, and
stop — review the diff, then instruct the agent to apply it while preserving your
`## Project context` section.
