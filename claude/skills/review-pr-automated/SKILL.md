---
name: review-pr-automated
description: One-shot automated PR review that runs review-pr-quick plus user-selected lenses (solid, leetcode, ai), condenses everything into one deduplicated findings list in Katie's casual PR-comment voice, and posts them to the PR as inline review comments. Use when the user wants a full automated PR review posted to the pull request.
purpose: Router for a one-shot automated PR review across four lenses run in a fixed order: `review-pr-quick` (always-on binary house rules), then `review-pr-solid` (architecture / regression / backward-compat), `review-pr-leetcode` (algorithmic complexity incl. DB N+1 / load-then-filter / async fan-out), and `review-pr-ai` (AI-authored code smells). `review-pr-quick` always runs first and needs no selection; the user picks which of the remaining three to add (recommending the ones the diff implies). This file holds routing, voice, and output preferences ONLY, it contains no review rules of its own; every rule lives in the owning lens skill and is read from there at run time. Condenses everything into ONE deduplicated list of unique findings where the earliest lens in the order owns each issue, writes each finding in Katie's casual PR-comment voice, and posts them directly to the PR as inline review comments via the gh API, approving the PR when the findings are all addressable (no hard blockers).
inputs:
  - PR number (required)
  - optional repo (defaults to the current repo's origin)
  - optional event override (APPROVE / COMMENT / REQUEST_CHANGES)
outputs:
  - a single deduplicated set of findings (no repeats across the lenses), each as a Conventional Comment (blocking / check / question / nit) in Katie's casual voice; findings sourced from `review-pr-quick` keep its 2-4 word form
  - inline review comments posted to the PR at exact file/line, plus a short overall review body
  - a PENDING (draft) review by default so Katie can edit the comments in GitHub and submit herself; a recommended verdict (APPROVE when only check/question/nit remain; COMMENT or REQUEST_CHANGES when a true blocker exists) is noted in the body + recap
  - only submits with an event when the user explicitly asks
  - an "escalate to a domain owner" list: findings in a subsystem whose intent could not be verified from the diff, surfaced in the recap and left as `question` comments rather than guessed at or silently approved
  - a short recap to the user: review URL, pending vs submitted, recommended event, comment counts
success_criteria:
  - runs `review-pr-quick` first on every PR without asking, then asks which of the remaining three lenses to add (multi-select, pre-checking the ones the diff implies) and blocks on their answer
  - runs the selected lenses in the fixed order below (quick → solid → leetcode → ai), never interleaved or reordered
  - reads each lens's rules from the owning skill at run time; never applies a rule restated in this file, because this file deliberately restates none
  - applies the selected lenses but emits each underlying issue ONCE, the earliest lens in the order owns the comment; a later lens may only raise its severity or sharpen its wording, never add a second comment for the same root cause
  - every comment is in Katie's voice (lowercase, friendly, framed as a question or soft suggestion, concrete fix named) with no trailing hedges, no tester jargon, and no PR / ticket ids
  - every inline comment targets a line that is actually in the diff hunk (added or context), with side RIGHT (or LEFT for removed-only lines)
  - creates a PENDING review via gh api with commit_id = PR head SHA so the comments stay editable in GitHub; submits with an event only when the user asks
  - recommended verdict approves only when there are zero hard blockers; otherwise COMMENT (or REQUEST_CHANGES if asked) and says so in the body
  - writes a `question` (not a guess, not silence) for any finding whose intent can't be verified from the diff, and lists those escalations with their subsystem in the recap
  - recaps the review URL, pending vs submitted, recommended event, and the comment-count line to the user
failure_modes:
  - skipping the lens-selection prompt for the three optional lenses and running all of them (or a fixed set) without asking, the user wants to choose which apply per PR
  - restating a lens's rules inside this file, or reviewing from a summary instead of opening the lens skill, this file routes, it does not carry review content, and an inlined copy silently drifts from the owning skill
  - making `review-pr-quick` optional, or skipping it because a deeper lens was selected, it is the always-on baseline and it is cheap
  - running the lenses out of order, or running a deeper lens before quick has established the baseline
  - re-stating the same issue once per lens because several lenses found it (must dedupe; earliest lens in the order owns it)
  - expanding a `review-pr-quick` finding into a paragraph when its 2-4 word form already says it (`nit: should be ts` needs nothing added)
  - running `review-pr-ai` before the other lenses and proposing a deletion that a later lens then asks to add back
  - posting a comment on a line that is not in the diff (gh api 422): resolve to a hunk line or fold into the body
  - writing in a stiff/formal voice instead of Katie's casual style
  - tacking a hedge onto the end of a comment ("no worries if not", "totally optional tho"): the label already sets the severity
  - auto-approving a PR that has a genuine blocker (security, data loss, crash, missing migration on a schema edit)
  - using the diff-hunk offset as the line number instead of the real file line from the PR branch
  - guessing at a domain rule the diff doesn't establish (or approving it by saying nothing) instead of asking the author to confirm with whoever owns that subsystem
  - citing a PR number or ticket id in a posted comment or review body: name the behavior or file instead
  - using tester jargon the author shouldn't have to decode (`interaction tests`, `lock-in`, `happy path`): say what the test should actually do
  - leaving a ticket id in the author's code comments or PR description unflagged, that is a finding, not something to copy
tools:
  - AskQuestion: present the lens-selection prompt for the three optional lenses (multi-select, recommended ones pre-checked) and block on the user's choice before analyzing; `review-pr-quick` is not offered because it always runs
  - Shell (gh CLI): gh pr diff / gh pr view / gh api contents / gh api pulls/{n}/reviews
  - Read/Grep: trace callsites, sizes, existing utils/tests when the diff is ambiguous; also used to open each selected lens skill and read its rules before applying them
  - the four source skills, in run order: `review-pr-quick`, `review-pr-solid`, `review-pr-leetcode`, `review-pr-ai`
---

# Review PR: Automated (combined lens, posts comments in Katie's voice)

Run one combined review over a PR: `review-pr-quick` always, plus whichever deeper lenses **the user selects**. Condense to a single deduped list of unique findings, write each in Katie's casual comment voice, and **post them to the PR as a PENDING (draft) review** so Katie can edit the comments in GitHub and submit herself. The skill recommends a verdict (approve when everything left is addressable) but leaves the actual submit to her unless she says otherwise.

This skill is the "just do it and leave the comments" front-end to the five detailed skills.

**This file is a router. It carries no review rules of its own.** Everything here is routing (which lens, when, in what order, who owns a duplicate finding) plus Katie's preferences for input, voice, draft mode, and output. The rules themselves live in the lens skills and are read from there at run time. Do not restate a lens's rules here and do not review from memory of one: open the skill. A second copy drifts from the original, which is exactly why the condensed checklist that used to live in this file was removed.

## Run order (fixed)

The lenses run in this sequence, and the order is load-bearing:

1. **`review-pr-quick`**: always, and before the lens-selection prompt. Cheapest and most mechanical, so it establishes the baseline before anything expensive runs, the deeper lenses don't spend effort re-finding `should be ts` or `no test`, and its `escalate` pointers tell you which deeper lenses to recommend.
2. **`review-pr-solid`**: architecture, regression risk, backward compat.
3. **`review-pr-leetcode`**: complexity, when there is non-trivial logic or a DB access pattern.
4. **`review-pr-ai`**. AI-authored code smells, when the diff reads as machine-generated. Last because it argues for removal, so it needs to see what the earlier lenses asked to add before proposing a cut.

Skipped lenses are simply omitted; the relative order of the ones that do run never changes.

## Lens map (routing only: open the skill for its rules)

Scope, not rules. Use this to decide which lens to route a diff to and which lens owns a finding; read the actual checks from the skill itself.

| Lens | Route here when | Owns |
|---|---|---|
| `review-pr-quick` | always, first, unconditionally | binary greppable house rules; 2-4 word comments |
| `review-pr-solid` | almost every PR | architecture, SRP/OCP/ISP, additive-over-modifying, backward compat, type safety in shared layers |
| `review-pr-leetcode` | non-trivial logic or a DB access pattern | algorithmic complexity, plus DB N+1 / load-then-filter / async fan-out |
| `review-pr-ai` | diff reads as machine-generated | AI code smells: sequential awaits called batching, a shared component changed for one call site, eslint-disable no-ops |

**Ownership where lenses overlap.** When two lenses would raise the same finding, the earliest in run order owns it (see step 5). Two boundaries are set by the skills themselves rather than by run order, so honor them:

- `review-pr-ai` owns code that is wrong or a no-op. When it overlaps a `review-pr-solid` finding on the same lines, solid owns it because it runs first.
- Test presence is `review-pr-quick`'s (`check: no test`, `blocking: needs integration test`). Test quality and colocated-test rules are `review-pr-solid`'s.

## Mandatory procedure

1. **Fetch context.**
   - `gh pr diff {N} --repo {owner/repo}` for the diff.
   - `gh pr view {N} --repo {owner/repo} --json title,body,author,baseRefName,headRefName,headRefOid,files` for metadata + head SHA + changed files.
   - Stop there for now. The full-file fetch happens in step 6, once you know which files actually get comments, pulling every changed file up front would make the quick pass expensive for nothing.
2. **Run `review-pr-quick` first**, before asking anything. It needs only the diff, costs one pass, and its findings become the baseline every later lens dedupes against. Keep its `escalate` pointers, they feed the next step.
3. **Ask which of the three optional lenses to add.** `review-pr-quick` is not offered; it already ran. Work out which of the remaining three the diff implies, present those three as a multiple-choice selection (allow multiple), **pre-check the recommended ones**, and **block until they answer**. Recommendation heuristic:
   - Anything `review-pr-quick` escalated, pre-check the skill it named. That is the point of running it first.
   - `review-pr-solid`: recommend on almost every PR (architecture applies broadly).
   - `review-pr-leetcode`: recommend when the diff has non-trivial logic or a DB access pattern worth analyzing.
   - `review-pr-ai`: recommend when the diff reads as machine-generated: long plausible-looking additions, comments restating the code, or vocabulary that does not match what the code does.
   If the user says "all" or "you pick", run the recommended set; if they pick a subset, run exactly that subset. If they pick none, the quick pass alone is a valid review, post it and say so.
4. **Run the selected lenses in the fixed order** from **Run order** above: quick, solid, leetcode, ai. **Open each selected lens skill and review from its rules**: this file does not restate them, so a lens you have not opened is a lens you have not run. Do not interleave lenses or revisit an earlier one after moving on.
5. **Condense to one unique list, earliest lens wins.** Collect every finding in run order, then dedupe:
   - Same file + same line + same root cause → the **earliest lens in the order owns the comment**. A later lens may raise the severity or sharpen the wording of that existing comment; it may not add a second one.
   - So a missing test caught by `review-pr-quick` (`check: no test`) stays quick's comment even when `review-pr-solid` would have called it `blocking`: keep quick's wording, take solid's severity.
   - Overlapping findings from two deeper lenses → one comment that names the strongest reason.
   - Drop anything purely stylistic that isn't worth the author's time; keep signal high.
5a. **Escalate what you cannot verify.** Some findings turn on intent that is not in the diff: whether a compliance rule genuinely works that way, whether a customer's configuration expects this shape, whether an integration's quirk is deliberate. Guessing produces a confident wrong comment, and staying quiet approves it by default. For each of these, write a `question` that states plainly what you could not verify and asks the author to confirm with whoever owns that subsystem, and collect them into an **escalations** list for the recap so Katie can pull the right person in. Keep it to genuine unknowns, a rule you can check by reading the repo is not an escalation, it is a lookup you should do.
5b. **Ticket ids in the author's comments or code.** Grep the diff (and the PR description) for `SUPPORT #`, `PR #`, `pull/#`, and tracker `TICKET-` ids inside comments, JSDoc, or user-facing copy. A code comment that points at a ticket instead of naming the behavior is a `nit`: ask them to describe the invariant (`the activation still fans out from the primary group`) so the next reader doesn't need the ticket. Do not copy those ids into your own comments. Allow-list: changelog entries, deploy docs, and `scripts/dataFixes/` filenames that already use the ticket as the artifact name.
6. **Resolve line numbers + comment-ability.** Now fetch the full content on the PR branch for each file that ended up with a comment, and confirm every line number against it:
   `gh api "repos/{owner}/{repo}/contents/{path}?ref={headRefName}" --jq '.content' | base64 -d | cat -n`
   `review-pr-quick` derives its line numbers from hunk-header arithmetic rather than the file, so re-check those here, an off-by-a-few from a miscounted hunk is the most common cause of a 422. Each inline comment must target a line that's part of the diff hunk (added `+` line or context line). If a finding is about an unchanged line outside any hunk, attach it to the nearest related changed line in the same file, or fold it into the overall review body. Use `side: "RIGHT"` for added/context lines; `side: "LEFT"` only for lines that exist only on the deletion side.
7. **Write each finding in Katie's voice** (see the style guide below). Quick-pass findings already are, leave them alone.
8. **Recommend an event (but don't submit it by default).** Compute which event the review *should* get so you can tell Katie in the recap and pre-fill the draft body, but leave the actual submit to her (see step 9):
   - **APPROVE**: no hard blockers; everything left is `check` / `question` / `nit`. Body should say it's approved and happy for them to address the comments (the "approve, they'll fix" flow Katie likes).
   - **COMMENT**: there's something you want addressed before merge but you don't want to hard-block, or you're unsure.
   - **REQUEST_CHANGES**: a genuine blocker (security hole, data loss, crash, `DELETE` SQL, missing activity log on a mutation, schema edit with no migration, exact incident replay).
9. **Post the review as PENDING by default** so Katie can edit the comments in GitHub and submit herself (see posting recipe). A pending review's comments are visible only to her until she submits, so she can reword, drop, or add comments inline, then pick the final event in the GitHub UI. Only submit a review outright (with an `event`) when the user explicitly says to (e.g. "just post it and approve" / "submit it"); then use the recommended event from step 8, and never auto-`APPROVE` over a hard blocker. After posting, recap to the user: the review URL, the lenses that ran in order, whether it's pending vs submitted, the recommended event, the comment-count line, and the escalations list from step 5a (subsystem + what you could not verify) so she knows who to loop in.

## Voice and posting

Read both before posting anything to a PR.

- `~/.claude/skills/_shared/comment-format.md`: the labels, ordering, line-number rules and mandatory count roll-up every lens shares.
- `references/voice.md`: the posted-comment voice and formatting rules, with real examples.
- `references/posting-recipe.md`: the gh api calls that post inline review comments and set the review event.

## Where the rules live

This router deliberately restates none of them. Open the owning skill for the lens you are running and review from its rules directly.

| Lens | Read | Subagent |
|---|---|---|
| `review-pr-quick` | `review-pr-quick` → **The checks** | none: runs in the main thread |
| `review-pr-solid` | `review-pr-solid` | `review-solid` |
| `review-pr-leetcode` | `review-pr-leetcode` | `review-leetcode` |
| `review-pr-ai` | `review-pr-ai` | `review-ai-smells` |

Dispatch the selected deep lenses to their subagents **in one message so they run concurrently**, then dedupe their returned findings here. Each subagent reads its own skill in its own context, so their bodies never enter this thread. `review-pr-quick` stays inline: it is small, always runs, and you want its findings visible as they land.

Run a lens inline instead when the user asks to see it work step by step, or when a subagent returns something you need to interrogate against the diff.

A condensed checklist used to live here. It was removed because it drifted from the skills it summarized: a rule changed in the owning skill kept being applied from the stale copy in this file. Do not reintroduce one. If a lens feels too slow to open mid-review, fix that in the lens, not by caching it here.

## Output contract (recap to the user after posting)

- One line: review created as **pending (draft)** + URL, note it's editable in GitHub and ready for her to submit (or, if she asked you to submit, say which event was used).
- One line naming the lenses that ran, in order (e.g. `quick → solid → leetcode`), so she can see what was and wasn't looked at.
- The recommended verdict (approve / comment / request changes) and a one-line why.
- The deduped findings as they were posted (grouped by file, blocking → check → question → nit), so the user can eyeball them.
- Final line, the count of every label, including zeros:

```
**Comment counts:** 0 blocking, 2 check, 2 question, 1 nit (5 total).
```
