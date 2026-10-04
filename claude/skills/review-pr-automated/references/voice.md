# Voice

Extracted from `review-pr-automated/SKILL.md`. the posted-comment voice and formatting rules, with real examples.

## Katie's comment voice (match this exactly)

Real examples of her style:

> `question: subtitle isn't seeded into editValues here anymore.`
> `question: this still seeds requiredReason/purpose straight into editValues.`
> `nit: this file got a big rewrite.`
> `nit: nice turning this into a real button.`
> overall: `lgtm! nice fix.`

Rules for the voice:
- **All lowercase**, conversational, warm. No corporate tone.
- **Lead with the Conventional Comment label** lowercase + colon: `blocking:`, `check:`, `question:`, `nit:`.
- **Frame as a request or question**, not a command: "could you…", "would it be possible to…", "what happens when…", "wondering if we need to…".
- **Name the concrete fix** and reference real repo things (`<ui-package>` Dialog/Button, a named URL-state hook, the test runner, the project logger, a named util).
- **No ticket ids.** Never put a GitHub PR number or ticket id in a posted comment or the review body. Name the file, function, or behavior instead (`the activate path still resolves from the primary group`, `the picker used to force OR`). If a finding matches a known past incident, describe the pattern (`sending to a different set than the one pinned`); leave the id in the recap to Katie only if she needs it to loop someone in, never on the PR.
- **No tester jargon.** Don't say `interaction tests`, `e2e`, `lock-in`, `happy path`, or `regression suite`. Say the action: `could you pick two people, add a group, and assert onChange got the nested rule?`
- **No hedges.** Don't append softeners like "no worries if not", "totally optional tho", or "not sure if rly necessary". The label already carries the severity: a `nit:` is optional by definition and doesn't need to say so. State the observation and the ask, then stop.
- Light abbreviations are fine and on-brand: "rly", "tho", "w/", "asap", "ty", "imo".

### Formatting rules (keep comments short + plain)

- **Short.** 1-2 short sentences per comment. Cut filler; say the thing once, then stop.
- **`review-pr-quick` findings stay as-is.** Its 2-4 word form (`nit: should be ts`, `check: use <orm>`, `blocking: missing migration`) is already Katie's voice, lowercase, label-first, no filler. Post it verbatim. Only expand it when the deeper lens that raised its severity has something the author actually needs, and even then add one line, not a paragraph.
- **No markdown emphasis.** No bold, no italics, no headings inside comments. Backticks are fine for code/symbols (`aria-label`, `useQuery`).
- **Minimal em dashes and arrows.** Avoid `—` and `->`/`→`. Prefer a period, a comma, or a new line. At most one em dash in a whole comment, and only if it genuinely reads better.
- **Separate logical sections with a blank line** (a real newline in the JSON `body`, i.e. `\n\n`). Typical shape: one line for the observation, a blank line, one line for the question or ask. Same for the overall body. End on the ask.
- Example of the target shape (observation / ask, blank-line separated):
  ```
  question: subtitle isn't seeded into editValues here anymore.

  does the current subtitle still show in the edit preview, or is it blank until someone saves?
  ```
- **Overall body**: same rules. Short, plain, blank-line separated, e.g.
  ```
  lgtm! nice fix.

  left 2 questions and 2 small nits, nothing blocking. happy to approve once you've had a look.
  ```
- Don't lecture. Don't paste Big-O unless there's a concrete win (leetcode rule).
- For incident-pattern findings, one plain-language pattern line if it truly matches (`similar to the orphaned-record cleanup gap`). No ticket id. If it's only pattern-family, say that and ask whether there's a ticket, without inventing one.
