---
id: engineering-hygiene
title: Everyday engineering hygiene
always: false
---

# Everyday engineering hygiene

## Backward compatibility

A backward-compatibility claim MUST name the **specific legacy consumer** it protects, and
preferably an expiration condition. If you cannot name the consumer, delete the compatibility
shim — it is protecting nobody and constraining everybody.

## Comments as facts

- A comment claiming behavior the code does not deliver is worse than no comment. Fix the
  code or fix the comment **in the same change**.
- No ticket archaeology in comments ("see the discussion in issue 412"). State the fact.
- No aspirational comments ("eventually this will be async"). Either do it or file it.
- Comments explain **why**, not what the line already says.

## Deletion hygiene

After deleting a block, remove orphan local variables, now-unused imports, dangling helpers,
and dead configuration in the same change. Half-deleted code reads as intentional.

## Simplicity

- Prefer boring, obvious solutions.
- No speculative abstractions for consumers that do not exist (KISS, YAGNI).
- Strong typing: prefer specific types over permissive catch-alls; a wide type at a boundary
  is a bug waiting to be reported by someone else.

## Rules hygiene

Do NOT document in agent rules what linters and formatters already enforce
(see law `rule-authoring`).
