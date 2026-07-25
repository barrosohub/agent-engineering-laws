---
id: prefer-executable-contract
title: Prefer executable contract over new versioned prose
always: false
---

# Prefer executable contract over new versioned prose

Before versioning new prose because "an important contract is not versioned", ask two
questions: **what already guarantees this?** and **is that guarantee executable?**

## Hierarchy (highest first)

1. **A versioned guard or test.** Executable, fails loudly, cannot be forgotten.
2. **An extension of an existing versioned document.** One more paragraph in the file
   that already owns the topic.
3. **A new versioned document** — only if the contract is durable AND not expressible
   as a test.

## Forbidden

- Versioning seasonal, migration-only contracts as permanent law. They expire; law does
  not. Put them in the migration's own scope and delete them with it.
- Inventing name-keyed allowlists in critical configuration in order to version one
  artifact. See law `attack-root-class`.
- Versioned documents that reference non-versioned artifacts as required inputs.
  A versioned document may reference only versioned artifacts or explicit external
  services. See law `hermetic-artifacts`.

## Test

If a reviewer could enforce the rule by running one command, write that command instead
of the paragraph.
