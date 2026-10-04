---
name: create-design-doc
description: >-
  Write, edit, or review engineering design docs in Katie's preferred style:
  collapsible heading-2 sections with dividers, no em dashes, colon form instead
  of term-then-period, Key Terms that say why a thing exists, a Simplifications
  Considered section, and evidence-backed claims verified against the repo. Also
  covers acyclic top-down architecture diagrams, checking scope is buildable by
  the actual team, deleting unmeasured numbers, and running a deduplication pass.
  Use when creating or editing a design doc, a technical proposal, an RFC, or an
  architecture write-up, especially in Notion.
disable-model-invocation: false
---

# Design docs, Katie's style

## The style rules

Open the reference file for the part of the doc you are writing or reviewing.

- `references/structure.md`: section order, collapsible headings, Key Terms, and acyclic top-down diagrams.
- `references/discipline.md`: buildable scope, decisions over instructions, evidence-backed claims, and the dedup pass.
- `references/review-and-notion.md`: handling review feedback, and the Notion-specific editing mechanics.

## Punctuation and prose

These are hard rules, and they apply to all prose written on Katie's behalf, not just the doc:
Notion pages, markdown in the repo, PR and issue descriptions, and chat responses in the same
session.

- **No em dashes**: never use `—`, and avoid `–`. Rewrite, or use a colon, a comma, or a full stop.
- **Colon, not term then period**: write `Term: explanation`, never `Term. Explanation`. This covers
  glossary entries, table cells that lead with a label or severity, reference bullets that lead with
  a link, and numbered steps that state a directive and then justify it.
- **Lowercase after the colon**, unless the next word is a proper noun, an acronym, or a code
  identifier. `Deadline evaluation: regulatory clocks live in MySQL` is right, and so is
  `Infrastructure track: ElastiCache with a noeviction parameter group`.
- **One colon per sentence**: if the colon form would put a second colon in the same sentence, use a
  comma instead of forcing it. `Medium, with four specific traps, each a day of work if discovered
  late: ...` rather than `Medium: four specific traps ...: ...`.
- **Bold only for a leading label**, never for mid-paragraph emphasis. A Key Terms entry, a table
  cell that opens with a status, and a bold text line standing in for a deep heading are all labels
  and should be bold. Bolding a phrase inside a sentence is not, however load-bearing the claim feels.
  If a sentence needs emphasis to land, it is the wrong sentence: give the point its own sentence, its
  own bullet, or its own short paragraph.
- Semicolons and parenthetical asides are both fine. No emojis.

## Paragraphs are short, or they are lists

Long prose blocks are the main readability complaint. A paragraph past roughly 100 words is a rewrite
candidate, and past 150 it is a defect.

- **A paragraph enumerating things becomes a list.** Three definitions, four regulatory clocks, two
  schema choices, three kinds of wait: all of these read as bullets and none of them read as prose.
  Keep a one-line lead-in above the list and a one-line consequence below it.
- **A paragraph making one argument gets split at its turns**, usually at the point where it stops
  describing and starts concluding. Two paragraphs of four sentences beat one of eight.
- **A preamble is two or three sentences.** Asking for context is not asking for a wall, so add the
  framing and then stop.
- Prose is still right for a single argument that has to be followed in order. Do not bullet something
  whose sentences depend on each other.
