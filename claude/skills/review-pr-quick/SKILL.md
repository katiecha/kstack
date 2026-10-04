---
name: review-pr-quick
description: Fast always-on PR pass over a small fixed set of binary, greppable house rules (net-new files in TS, test presence, shared UI usage, <orm>, the project logger, auth and org scoping, activity logs, migrations), reporting each finding as a 2-4 word comment. Use for a quick PR review with no architecture or complexity analysis.
purpose: The fast always-on PR pass. Checks a small fixed set of binary, greppable house rules (net-new files in TS, test presence, `<ui-package>` usage, <orm>, the project logger, auth/org scoping, activity logs, migrations) and reports each finding as a 2-4 word comment. Runs in one pass with no subagent, no per-file scans, and no architecture or complexity analysis, those belong to `review-pr-solid`, `review-pr-leetcode`, and `review-pr-ai`.
inputs:
  - PR number or diff
outputs:
  - one flat list of findings, grouped by file, one line each: `path:line, label: 2-4 words`
  - a mandatory comment-count roll-up as the final line (all four labels, including zeros)
  - one-line verdict, and an escalation pointer when a blocker warrants the full pass
success_criteria:
  - every comment is 2-4 words after the label, lowercase, no markdown emphasis, no fix paragraph
  - only the checks in **The checks** below are applied; nothing is invented or borrowed from the deeper skills
  - line numbers are computed from the diff hunk headers, not by fetching every file
  - finishes in one pass with no subagent delegation
  - names the deeper skill to run when a `blocking` finding lands in schema, auth, or data loss
failure_modes:
  - writing a full Problem/Fix block instead of a 2-4 word comment, that is a deeper lens's job, not this skill's
  - padding a comment to a sentence ("should probably be converted to typescript") instead of `should be ts`
  - drifting into architecture, complexity, backward-compat, or incident-pattern findings, out of scope here
  - fetching every changed file at full length, which defeats the purpose of a quick pass
  - reporting a `nit` pile-up on a large diff instead of the first occurrence per file per rule
  - approving silently when a `blocking` check fires: always name the deeper skill to run
judge_rubric:
  - brevity (every comment 2-4 words after the label)
  - scope_discipline (only the fixed check list applied)
  - cost (one pass, no subagent, no full-file fetches)
  - line_accuracy (line numbers resolved from hunk headers)
  - escalation (deeper skill named when a real blocker fires)
tools:
  - Shell (gh CLI): `gh pr diff {pr_number}` for the diff; `gh pr view {pr_number} --json files --jq '.files[] | "\(.additions) \(.deletions) \(.path)"'` for the file list
  - avoid subagents, full-file fetches, test runs, builds, and web search, this pass is deliberately cheap
---

# Review PR: Quick

The pass you run on every PR. A fixed list of binary house rules, each reported in 2-4 words. If it takes more than a sentence to explain, it does not belong here: run the matching deeper lens for that.

## Mandatory procedure

1. `gh pr diff {pr_number}` for the diff and `gh pr view {pr_number} --json files` for the changed-file list with add/delete counts.
2. Walk the diff once against **The checks** below. Nothing else.
3. Resolve each line number from its hunk header, count forward on the `+` side from the `@@ -a,b +c,d @@` start. Do not fetch whole files.
4. Report one line per finding. First occurrence per rule per file: do not list the same `nit` fifteen times.

## The checks

**Files and TypeScript**

- Net-new `.js` / `.jsx` file → `nit: should be ts`
- New TS file not kebab-case → `nit: kebab-case`
- `default export` → `nit: named export`
- Net-new file with 2+ exports → `check: split file`

**Tests**

- Net-new component, hook, util, model, or controller with no test in the diff → `check: no test`
- Net-new route with no integration test → `blocking: needs integration test`

**Frontend**

- Text in raw `<p>` / `<span>` / `<div>` / `<label>` / `<td>` / `<h1>`-`<h6>` → `check: use Text`
- Raw HTML where a `<ui-package>` component exists → `check: use gui`
- `useEffect` + `fetch` for server state → `check: use useQuery`
- Raw tailwind color or hex → `nit: use token`
- Hardcoded z-index → `nit: z token`
- `key={index}` with a stable id available → `check: unstable key`

**Backend**

- `console.*` in `server/`, `<models-package>/`, `<utils-package>/` → `nit: use the project logger`
- Net-new raw SQL → `check: use <orm>`
- `DELETE` SQL → `blocking: hard delete`
- Create / edit / delete with no activity log → `blocking: missing activity log`
- New route missing `requireAuth` or org scoping → `blocking: missing auth`
- Empty catch, or catch returning `[]` / `null` with no log → `blocking: silent catch`
- `organizationId` read from `req.query` / `req.body` on a user route → `blocking: org from token`

**Schema and constants**

- `schema.ts` edited with no generated migration committed → `blocking: missing migration`
- Magic string duplicating a known `<constants-package>` enum → `check: use constant`

## Comment style

Label, colon, 2-4 words. Lowercase. No bold, no backticks unless the word is a symbol, no fix paragraph, the rule name *is* the fix.

```
nit: should be ts
check: no test
check: use Text
check: use <orm>
blocking: missing activity log
blocking: missing migration
```

Not this:

```
nit: this is a net-new file and per our conventions all new files should be
written in TypeScript rather than JavaScript, could you convert it?
```

## Output contract

```
### Findings

client/src/components/vendor/vendor-card.jsx:1, nit: should be ts
client/src/components/vendor/vendor-card.jsx:44, check: use Text
server/controllers/vendor.controller.js:88, check: use <orm>
server/controllers/vendor.controller.js:112, blocking: missing activity log
server/routes/vendor.routes.js:14, blocking: missing auth

### Verdict
One line: clean / fix blockers first.

**Comment counts:** 2 blocking, 2 check, 0 question, 1 nit (5 total).
```

Labels, ordering, line-number rules and the mandatory count roll-up are defined in `~/.claude/skills/_shared/comment-format.md`. Read it, do not restate it. This lens groups by **file**, not top-level directory, because it reports single-line findings. If the diff is clean, the entire body is `clean.` and the count line.

## When to escalate

Name the deeper skill in one line after the verdict when the quick pass trips on something it cannot fully judge:

- `blocking: missing migration`, or any schema edit → `review-pr-solid` (backward compatibility, regression risk)
- `blocking: missing auth`, `org from token`, or a cross-org path → `review-pr-solid` (shared-layer type safety, regression risk)
- `blocking: hard delete`, `silent catch`, or a bulk/destructive operation → `review-pr-ai` (defensive code that quietly no-ops)
- A query in a loop, a load-then-filter, or an unbounded `Promise.all` → `review-pr-leetcode`
- A net-new surface over ~300 lines → `review-pr-solid`

To post these as inline PR comments, hand the list to `review-pr-automated` and use its posting recipe.

## Out of scope

Architecture, SOLID, backward compatibility, complexity and Big-O, over-engineering, incident patterns, UTC safety, server-test DB mocking, page architecture, and the per-file raw-text and literals scans. All of it lives in the deeper skills. This one stays small on purpose.
