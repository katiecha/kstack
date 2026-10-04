---
name: check-format
description: >-
  Guardrail that inspects a draft skill output and verifies required sections
  are present, in order, and correctly formatted. Use when checking a skill's
  draft output against its contract before delivery.
---

# Format Check

This skill runs on a draft skill output before it is delivered. It checks structure only, not whether the content is correct. Use `check-evidence` for content accuracy.

## Where the contract comes from

Every skill that produces a structured output owns its own `## Output contract` section. **Read it from the owning skill** rather than from a copy here. A condensed copy in this file drifts from the skill it summarizes, and the stale copy is what gets applied.

The tables below are the section order only, so the check can run without re-reading a 20K skill. Anything not listed here, such as field-level format, table columns, or per-finding body, is read from the owning skill.

## Shared contract: every `review-pr-*` lens

Labels, ordering, line-number rules and the mandatory count roll-up live in `~/.claude/skills/_shared/comment-format.md`. Check all four against that file:

1. Labels are Conventional Comments, lowercase, label first, then a colon: `blocking` / `check` / `question` / `nit`. Any other label is a violation.
2. Ordering matches the lens. See each lens below for whether it groups by file or by top-level directory, then `blocking` to `check` to `question` to `nit`, then by file path.
3. Every finding cites a line number from the file **on the PR branch** with a short snippet quoted at that line. A placeholder such as "line N or function name" is a violation.
4. The final line is the count roll-up, listing all four labels including zeros:
   `**Comment counts:** 0 blocking, 3 check, 1 question, 2 nit (6 total).`

A severity bucket with no findings must say `None.` Omitting it entirely is a violation.

## Section order by skill

### `review-pr-quick`

1. Findings, grouped by **file**, alphabetical by path
2. Verdict, one line
3. Comment counts

Clean diff: the entire body is `clean.` plus the count line. Each finding is a single 2-4 word comment. A multi-line finding body is a violation in this lens.

---

### `review-pr-solid`

1. Net-new files
2. Modified files, additive vs modifying
3. Modified shared files
4. Backend backward compatibility
5. Type safety in shared layers
6. Test coverage
7. Simplification opportunities
8. Findings, with a `####` heading per top-level directory, alphabetical
9. Not checked / insufficient context
10. Verdict
11. Comment counts

Every finding body carries a `Principle:` line. A finding without one is a violation.

### `review-pr-leetcode`

1. Subsystems & hotspots, inventory only, no complexity
2. Optimization table
3. Findings, grouped by file path
4. Coach's corner
5. Deferred to other reviews
6. Not checked / insufficient context
7. Verdict
8. Comment counts

Sections 2, 4 and 5 must be present even when empty, with the skill's stated "None" line. Big-O in section 1 is a violation. Each finding body carries a `Current` to `achievable` pair.

---

### `review-pr-ai`

1. Findings
2. Comment counts

Clean diff: the entire body is `no AI smells found.` plus the count line. This lens adds no sections of its own.

---

### `review-pr-automated`

The recap to the user after posting, in this order:

1. One line: review created as **pending (draft)** plus URL
2. One line naming the lenses that ran, in order
3. Recommended verdict (approve / comment / request changes) plus a one-line why
4. The deduped findings as posted
5. Comment counts

A finding attributed to more than one lens is a violation. The earliest lens in the run order owns it.

---

### `strip-comments`

1. Removed
2. Reformatted
3. Kept
4. Verdict

No comments introduced: the entire body is `no comments introduced.` plus the count line. In `report` mode nothing may be edited. A diff alongside a report is a violation.

---

### Any skill not listed above

Open the skill's `## Output contract` section and check the draft against it. If the skill has no output contract, say so in the verdict rather than inventing one. An unlisted skill with no contract is a pass, not a fail.

## How to run the check

1. Identify the skill name from the draft or context.
2. Read the owning skill's `## Output contract`. Use the order above as the index. The skill is the source of truth.
3. For each required section: is it present? Is it in the right position? Does it use the correct format?
4. For `review-pr-*` lenses: run the four shared checks against `_shared/comment-format.md`.

## Output format

```
## Contract check: [skill name]

### Violations
[list each violation as:]
- Missing section: [section name], must appear after [preceding section]
- Wrong order: [section name], found at position N, contract says M
- Wrong format: [section name], [what the format should be]
- Label not Conventional Comments: [quote the label]
- Line number unresolved: [quote the finding]
- Missing count roll-up, or a label omitted from it
- Section omitted instead of "None." / "n/a": [section name]

### Verdict
Pass: deliver as-is / Fail: fix [N] violation(s) before delivering
```

If the output passes: state "Pass: deliver as-is."
If it fails: list every violation. Do not stop at the first one.
