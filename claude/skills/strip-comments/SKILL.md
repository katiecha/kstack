---
name: strip-comments
description: >-
  Delete code comments that do not earn their place, on a branch or PR, before a human reviews it.
  Applies a two-test bar: delete unless the comment carries a fact living outside the file, and
  delete explanatory prose even when the code it sits above is good. Reformats ticket references as
  single-line TODOs carrying a full clickable URL. Use when asked to strip, remove, cut, prune, or
  clean up comments, to de-slop comments, to cut AI comment noise, to fix comments before review, or
  when a reviewer flags explanatory or restating comments.
purpose: Strip code comments from a branch before human review. Deletes every comment that does not carry a why living outside the file, holds survivors to the senior reviewer's "why is it here" bar, and reformats ticket references as single-line TODOs with full clickable URLs. Operates on comments in the source, not on review threads.
inputs:
  - branch, PR number, or diff (defaults to the current branch against origin/main)
  - optional mode: `strip` (default, applies the deletions) or `report` (findings only, for someone else's PR)
outputs:
  - in `strip` mode: the edits applied to the working tree, plus a list of what was removed and a justified list of what survived
  - in `report` mode: findings in Conventional Comments format (blocking / check / question / nit) with exact file path and line number
  - a mandatory comment-count roll-up as the final line (removed, kept, reformatted, including zeros)
success_criteria:
  - every comment introduced or touched on the branch is judged individually, file by file through the diff
  - deletion is the default: a survivor is named with the outside fact it carries, a deletion needs no defense
  - catches explanatory prose attached to genuinely good code, which passes a skim because it is well written
  - catches restatement of the literal values below a comment, not just restatement of the line below it
  - every remaining ticket reference is a single-line `//` TODO above the declaration carrying a full URL
  - the repo's typecheck and lint still pass after the deletions
failure_modes:
  - deleting a comment that carries a real constraint, a rejected alternative, or a spec reference, because it read as verbose
  - keeping a paragraph because it is well written rather than because it carries a fact
  - keeping a comment on the grounds that the code it sits above is worth keeping: those are different questions
  - rewriting a comment shorter when the honest move is deleting it
  - touching comments the branch did not introduce, which turns a cleanup into an unreviewable diff
  - stripping JSDoc `@param` / `@returns` tags, which are a separate requirement
  - leaving a bare ticket id in prose instead of promoting it to a TODO line
judge_rubric:
  - deletion_rate (default was delete, not shorten)
  - survivor_justification (each kept comment names the outside fact)
  - explanatory_slop_caught (prose describing what good code does, not just bad comments)
  - ticket_format (single-line TODO, own line, full URL)
  - scope_discipline (only comments this branch introduced or touched)
tools:
  - Shell (git): `git diff origin/main...HEAD` for the branch diff, `git diff --stat` for the file list
  - Shell (gh CLI): `gh pr diff {pr_number}` when working from a PR number
  - Read/Grep: confirm whether a claimed constraint is real before deleting the comment that states it
  - Shell: the repo's own typecheck and lint after the edits (in the server repo: `pnpm typecheck <target>`, `pnpm lint <path>`)
---

# Strip comments

The comment pass you run on your own branch before a human sees it. Default to no comment. Code, names, and types carry the *what*. A comment exists only to carry a *why* that cannot be recovered from them.

The burden of proof is on the comment. Silence is free and never rots. Every comment is a second source of truth that some future edit will forget to update, so it has to buy its way in.

The bar below is a senior reviewer's standing ask, and it holds in every repo. Do not soften it: the recurring review finding is not bad comments, it is well-written comments that explain what good code already says.

## Mandatory procedure

1. Get the diff. `git diff origin/main...HEAD` for the current branch, or `gh pr diff {pr_number}` for a PR.
2. Walk it file by file, not by grep. Every comment on a `+` line is in scope. A comment the branch did not touch is out of scope.
3. Apply both tests below to each one. Delete by default.
4. Promote any surviving ticket reference to the TODO format.
5. Run whatever typecheck and lint the repo provides on the touched targets. In the server repo that is `pnpm typecheck <target>` and `pnpm lint <path>`.
6. Report using the output contract. Justify survivors, never deletions.

## The two tests

**Test one, the delete test.** Delete the comment. If a competent engineer reading the surrounding code reaches the same understanding within ~30 seconds, it was noise. Keep it only if deleting it loses a fact that lives outside this file. If you cannot name which fact, it is noise. When it is a close call, delete it.

**Test two, the why-is-it-here test.** This one catches what test one misses. A good constant, type, or function does not entitle itself to a comment, and a well-written paragraph about a useful thing clears a 30-second skim easily. So ask what the comment says about *why this exists*. If the answer is "it explains what it does", delete it. Explanatory prose attached to worthwhile code is still slop.

## Worth keeping

- A non-obvious constraint that forces the shape of the code
- An alternative deliberately rejected, and what breaks if someone "fixes" it back
- A value pinned to an external spec or contract, with the source named
- Ordering, timing, or concurrency hazards that are not visible locally
- The honest limit of what something covers, so nobody over-trusts it
- Where a failure surfaces, when it is not here (for example at runtime in a deployed lambda rather than at typecheck)

## Delete on sight

- Restating the line below it
- Restating the values below it: arithmetic on literals the reader can already see
- Describing what the code does, however good the prose
- Section banners and decorative dividers
- Narrating the edit ("now handles X", "updated to..."). That is the commit message.
- Unmeasured claims ("cleaner", "more robust", "for performance") with no mechanism
- Anything better fixed by renaming a variable or extracting a function. Do that instead.
- A TODO with no ticket id
- A multi-paragraph doc block on a constant or a short function. If the reason genuinely takes paragraphs, it belongs in the ticket or the design doc, linked.
- Emoji in a comment

## Style for survivors

State the fact, not advice to the reader. No "note that", no "we", no addressing whoever is reading. Write what stays true after a refactor. If the reason is a ticket or a spec, name it.

Hold it to one or two lines. Three sentences of why is usually one sentence of why plus two of restatement.

## Ticket references and outstanding work

A single-line `//` comment on its own line, directly above the declaration, carrying the full URL so it is clickable from the editor. Never a bare ticket id, and never a caveat buried in a paragraph, which reads as settled context rather than as work someone owes.

Put it above the doc block, not between the doc block and the declaration, so the JSDoc stays attached for editor tooltips.

```ts
// TODO: implement proper vendor SLA constants in <tracker-url>/issue/TICKET-1234
```

Not this:

```ts
/**
 * Provisional. The vendor SLA figures this should be sized against are unverified (TICKET-1234).
 */
```

## Worked example

Before, nine lines on a four-field constant:

```ts
/**
 * A third party that can be down for a while. Twelve attempts from 30 seconds, doubling to a
 * 15-minute cap, is up to ~1.75 hours before the job dead-letters and someone is paged.
 *
 * It covers an outage, not a slow response: waiting for an upstream submission to settle belongs to the
 * cadence poller and the outbox publish time, never to a retry. The cap is also the largest delay
 * SQS can express, so raising it would be silently clamped by that adapter.
 *
 * Provisional. The vendor SLA figures this should be sized against are unverified (TICKET-1234).
 */
export const EXTERNAL_RETRY_POLICY: RetryPolicy = {
    maxAttempts: 12,
    initialDelayMs: 30_000,
    maxDelayMs: 900_000,
    jitterRatio: 0.2,
};
```

After. The arithmetic went because the fields state it. What survived is the scope boundary and the external constraint on the value, neither of which is visible locally, and the caveat became work someone owes:

```ts
// TODO: size this against verified vendor SLA figures in <tracker-url>/issue/TICKET-1234
/**
 * A third party that can be down for a while. Covers an outage, not a slow response: waiting for a
 * upstream submission to settle belongs to the cadence poller and the outbox publish time.
 *
 * `maxDelayMs` is the longest delay SQS can express, so raising it would be silently clamped there.
 */
```

## Out of scope

JSDoc `@param` / `@returns` tags are a separate requirement: do not strip them, and check their types are right while you are in the file. The prose description inside a JSDoc block is **not** exempt, and is held to the same bar as any other comment.

Also out of scope: the AI code smells that are behavioral rather than textual, which belong to `review-pr-ai`. Comments only.

## Output contract

```
### Removed

<events-package>/src/core/job-retry.ts:3, restates the literals below it
<events-package>/src/core/job-retry.ts:11-19, explains what the constant does
<events-package>/src/core/job-retry.ts:28: name already says it

### Reformatted

<events-package>/src/core/job-retry.ts:19, bare TICKET-1234 in prose promoted to a single-line TODO with full URL

### Kept

<events-package>/src/ports/broker-port.ts:11, no `failed` state: names a rejected alternative
<events-package>/src/core/job-retry.ts:67, jitter subtracted: constraint that is not visible from the arithmetic

### Verdict
One line: clean / comments cut, typecheck and lint green.

**Comment counts:** 3 removed, 1 reformatted, 2 kept (6 judged).
```

Group by file, alphabetical by path. A file with nothing to judge is omitted. If the branch introduced no comments, the entire body is `no comments introduced.` and the count line.

In `report` mode, emit the same judgments as Conventional Comments (`nit: restates the line below`) with file and line, and do not edit anything. Labels, ordering, line-number rules and the count roll-up follow `~/.claude/skills/_shared/comment-format.md`.
