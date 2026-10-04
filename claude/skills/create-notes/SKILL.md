---
name: create-notes
description: >-
  Format findings, meeting recaps, design discussions, status updates,
  technical write-ups, or git/PR history into Katie's preferred Google Docs
  note style (bold title, plain short section headers, deeply nested
  bullets/numbers, telegraphic fragments,   parenthetical context, decisions
  highlighted in blue). Use when the user asks to turn something into notes,
  format it for their Google Doc, recap a meeting, or summarize history.
disable-model-invocation: false
---

# Create Notes

Format content into Katie's Google Docs note style. Produce the textual content
structured so it maps cleanly onto Docs formatting (she applies bold/blue/links
and indentation in the doc; Docs auto-linkifies URLs).

## Core conventions (all note types)

- **Title**: bold line at the top.
  - Meeting/conversation: `<Attendees joined by " / "> - <Topic>`
    (e.g. `Alex / Katie - Integration Demo`).
  - Topic/reference: `<Topic> <Qualifier>` (e.g. `<analytics-vendor> Metrics`).
- **Section headers**: short, plain labels (not bold). Often phrased as a
  question (`What was shipped?`, `Who is the user?`, `Why X over Y?`) or
  count-prefixed (`3 events`, `5 helper utilities`). May carry a parenthetical
  scope/path (`Abstraction layer (<analytics-package>/)`).
- **Hierarchy**: nest with indentation, multiple levels deep. Use a blank line
  between top-level sections.
- **List type**: numbered lists for sequential processes/steps; bullets for
  facts, observations, and non-ordered lists.
- **Voice**: telegraphic fragments, not full sentences (`Send to slack`,
  `Posts an internal note`). Keep concrete numbers/stats verbatim
  (`25-30%`, `100+ per month`), exactly as the source stated them.
- **Parentheticals**: inline clarifying context (`the CRM (where intake data lands)`, `(client/src/index.jsx)`).
- **Inline arrow `→`**: show flow or consequence (`no events fire → client-side
  via the disabled flag`).
- **Examples**: prefix with `Ex.`.
- **Code/file references**: name the file, then a colon and short description
  (`org-type.ts: classified an org as production, consultant, staging, or local`).
  Link the filename when a URL/path is available.

## Highlighting decisions (blue)

In Q&A or open-question docs, the resolution/answer/decision/agreed copy goes in
**blue** in the doc, nested under the question it answers. Output these lines
nested under their question with no special marker, the user recolors them
herself. Leave open/unanswered questions in default color.

## Note-type patterns

- **Meeting / conversation**: attendee title; sections for each theme
  (`Stats`, process names). Attribution to people is expected here
  (`Alex is building out the new team`, `best option in Sam's opinion`).
- **Process / workflow**: numbered steps with indented sub-steps for branches
  (`a. Positive: ...`, `b. Negative: ...`).
- **Design Q&A / open questions**: numbered questions grouped by area
  (`Design questions`, `Edge cases`); answers/decisions in blue beneath.
- **Status**: split into `What was shipped?` / `What was delayed?`; under each,
  bullet the item then indent the detail/caveat.
- **Technical / architecture**: count- or path-scoped section headers; per-file
  bullets with `filename: behavior`; arrows for data flow.
- **Git / PR history**: see constraints below.

## Git / PR history (extra constraints, this type only)

- Title: `<Topic> GitHub History`. Group into chronological sections with date
  ranges (`Phase 1: Admin tool is born (Apr 2026)`).
- One line per item: `<number>: <full URL> → <general description>`.
- Describe what the PR did (outcomes/behavior), not commits.
- **No author names / no blame** (including section titles).
- **No commit hashes.**
- Flag closed/unmerged/tangential state in the description.
- Gathering: exclude Cursor checkpoints
  (`git log --no-merges --invert-grep --grep="^checkpoint:" ...`); resolve PRs
  with `gh pr view <n>` / `gh pr list --search <sha>`; confirm merged vs closed.

## Templates

Meeting / status / technical:

```
<Title>
<Section header>
- <fragment> (<parenthetical context>)
  - <nested detail>
1. <step>
   a. <branch>

<Section header phrased as a question?>
- <item> → <consequence>
```

Git / PR history:

```
<Topic> GitHub History
<Section label> (<date range>)
<number>: <url> → <general description of what it did>
```
