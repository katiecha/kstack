# PR comment format (shared)

Single source of truth for the parts of the review output contract that every
`review-pr-*` lens shares. Each lens keeps its own finding-body fields (the
`Principle:` line in `review-pr-solid`, the Big-O pair in `review-pr-leetcode`);
only what is common lives here.

Do not copy this file into a skill. Reference it. A condensed local copy drifts
from the original, and the stale copy is what gets applied.

## Labels

[Conventional Comments](https://conventionalcomments.org/), lowercase, label
first, followed by a colon:

| Label | Means |
|---|---|
| `blocking` | Must change before merge. |
| `check` | Should change; author may push back with a reason. |
| `question` | Problem plus a question, no fix. Severity cannot be decided until the author answers. |
| `nit` | Optional. Optional by definition, so never add a softener saying so. |

## Ordering

Group by top-level directory, alphabetically. Within a directory, order
`blocking` → `check` → `question` → `nit`. Within a severity bucket, order by
file path. Omit a directory with no findings rather than writing an empty
heading. If the whole diff is clean, write `None.` for the findings section.

## Line numbers

- Cite the line number from the file **on the PR branch**, not the diff hunk
  offset. Fetch numbered lines with `gh api ... | base64 -d | cat -n`.
- Quote a short snippet of the code at that line after the number, so the
  reader can verify context without reopening the file.
- For a finding that spans a range, cite the opening line of the construct.
- Never write a placeholder such as "function or line". Resolve it first.

## Mandatory count roll-up

The final line of every review. Count every finding by label and list all four
in this fixed order, including any that are zero:

```
**Comment counts:** 0 blocking, 3 check, 1 question, 2 nit (6 total).
```

## Voice

When comments are posted to a PR rather than reported in chat, the voice rules
live in `review-pr-automated/references/voice.md`, section **Katie's comment voice**.
They are not restated here.
