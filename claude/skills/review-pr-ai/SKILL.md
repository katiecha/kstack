---
name: review-pr-ai
description: Review a pull request for AI-authored code smells: changes that look plausible and read as finished but are wrong, unnecessary, or quietly no-ops. Use when reviewing a PR or diff for AI slop, dead abstractions, defensive code that never fires, or confidently written code that does nothing.
purpose: Review a pull request for AI-authored code smells: the patterns that look plausible and read as finished, but are wrong, unnecessary, or quietly no-ops.
inputs:
  - PR number or diff
outputs:
  - findings in Conventional Comments format (blocking / check / question / nit) with exact file path and line number for each
  - a mandatory comment-count roll-up as the final line (counts of every label, including zeros)
success_criteria:
  - identifies AI code smells (sequential awaits described as batching, a shared component modified for one call site, eslint-disable no-ops in a Biome repo)
  - names the concrete fix rather than naming the smell
  - separates a genuine smell from an unfamiliar but deliberate choice, asking rather than asserting when the intent is not in the diff
  - identifies AI code smells (sequential awaits called "batching", shared component modified for one call site, eslint-disable no-ops)
failure_modes:
  - flagging idiomatic code as AI-authored because it is verbose
  - commenting on the code's provenance rather than the code: describe what is wrong, never who or what wrote it
  - flagging over-engineering that the diff does not justify
tools:
  - Shell (gh CLI): gh pr diff / gh pr view
  - Read/Grep: confirm a suspected no-op or a single-call-site change against the rest of the repo
---

# Review PR: AI code smells

The AI-slop lens. These patterns pass a skim because they use the right vocabulary. Each one below
is a case where the words say one thing and the code does another.

## Output contract

Labels, ordering, line-number rules and the mandatory count roll-up are defined in
`~/.claude/skills/_shared/comment-format.md`. Read it, do not restate it. This lens adds no
sections of its own: the body is the findings list plus the count line. If the diff is clean,
the entire body is `no AI smells found.` and the count line.

## AI Code Smells

- Shared component modified for a single call-site: flag as `check`; compose the variation at the call site.
- `tsconfig` exclusions added to suppress type errors: flag as `blocking`; fix the types.
- Unnecessary refactor of correct existing code: flag as `check`.
- Global design system changes made to solve a local problem: flag as `check`; fix is a local override.
- `// eslint-disable-next-line` comments: flag as `nit`; the repo uses Biome, not ESLint.
- `window.confirm()` / `window.alert()` for destructive actions: flag as `check`; use `AlertDialog` from `<ui-package>`.
- Writing to DB rows without first confirming they exist: flag as `blocking`.
- **Missing or incomplete environment variable documentation**: any new env var must be documented in `.env.example`. Flag as `check`.
- **Unused exported functions or dead code**: flag exported functions not called from any module or test as `check`.
- **Conditional column omission in UPDATE functions**: always write `NULL` explicitly; never skip a SET clause via ternary. Skipping leaves the column at its stale DB value.
- **MySQL NULL in unique keys**: a `UNIQUE KEY` including a nullable column does not deduplicate `NULL` in MySQL. If deduplication is the intent, the column must use a sentinel non-null value. Flag as `blocking`.
- **Hardcoded Auth0 prefix for reviewer type inference**: `reviewerId.startsWith("auth0")` misclassifies SSO users. Use UUID-schema detection instead. Flag as `blocking`.
- **JS-computed column with a client-side filter but no server-side `columnMap` entry**: computed columns cannot participate in SQL `WHERE`. Flag any column with a `filter:` definition but no `columnMap` entry as `blocking`.
- **Unreachable dead code in OR conditions that cover `null`**: `x !== "foo" || x == null` is dead code when the first branch already handles `null`. Flag as `nit`; simplify to the minimal condition.
- **Vendor secrets hard-coded in `.env` instead of Secrets Manager**: long-lived third-party credentials belong in a secrets manager, read through the project's shared secrets accessor. Flag any net-new `env.VENDOR_*`, `env.*_API_KEY`, or `env.*_TOKEN` reference in production code as `check`.
- **`REACT_APP_*` prefix on server-side env vars**: `REACT_APP_*` is a CRA convention that signals "safe to inline into the browser bundle." Using it in `server/`, daemons, or lambdas conflates public and private keys and misleads future engineers who might later reference the same name from client code. Server env vars must use unprefixed names (e.g. `ANALYTICS_API_KEY`, not `REACT_APP_ANALYTICS_API_KEY`). Client and server keys are often different tokens with different trust levels: keep them named distinctly. Flag as `blocking`.
- **Integration-agnostic client directly hard-wires a vendor SDK**: a client package named or described as vendor-agnostic (e.g. `<analytics-package>`) that imports `<analytics-vendor>`, `<analytics-vendor-b>`, or similar SDKs directly is tightly coupled to a single vendor. Prefer an adapter layer: the client accepts an `AnalyticsAdapter` interface; each vendor ships its own adapter class. This lets you swap or fan-out providers without touching call sites. Flag direct vendor SDK imports in an iPaaS-style client as `check` (non-blocking if the PR author agrees to a follow-up; blocking if the same PR also exports the client as a public API surface).
- **Merge-conflict markers and resolution debris**: grep every added line in the diff for `<<<<<<<`, `=======` as a standalone line, and `>>>>>>>`, plus committed `.orig` / `.rej` files. A marker inside a template literal, a JSX text node, a markdown file, or a comment does not break the build, so it survives typecheck and lint and ships. Flag any conflict marker as `blocking` and a committed `.orig` / `.rej` file as `check`. When you find one, look at the rest of that file specifically: a bad resolution usually leaves duplicated blocks or a dropped hunk nearby.
- **Committed temp / local-env artifacts**: deploy runbooks, `.vscode/tasks.json`, worktree shell scripts, CI planning documents, and in-progress markdown design notes must not be committed to the repo. Flag any PR that adds these files as `check`; fix is to delete them before merge and store runbooks in Notion or a Gist instead.
- **Unresolved Bugbot findings**: when Bugbot leaves comments that appear substantively correct (security, null safety, data correctness, logic bugs), the author should either fix them or post a rationale for dismissal. Flag PRs with open valid Bugbot comments and no author response as `check`.
- **Foundation bundled with its consumers**: a PR that lands a new shared abstraction (a base class, a factory, a context provider, a schema module) together with the five call sites adopting it is hard to review well: the abstraction's design cannot be judged separately from the code pressuring it, and a revert drags all six changes with it. Prefer a foundation PR (the abstraction plus one reference consumer) followed by per-consumer PRs. This differs from **Unrelated scope** below, here the files are all related; there are simply too many decisions in one diff. Flag a net-new shared abstraction arriving with 3+ consumers in the same PR as `check`.
- **Unrelated scope**: flag files modified in a PR that are clearly unrelated to its stated purpose (e.g. <orm> schema changes inside an auth fix, data-table handler edits inside a UI PR, `.gitignore` or config edits not motivated by the feature) as `check`. Ask the author to confirm the change is intentional or move it to a separate PR.
- **Missing Loom for visual changes**. PRs that modify user-facing visual behavior (layout, interaction, new UI states, styling beyond trivial token swaps) should include a Loom video or screenshots in the description before merge. Flag PRs with non-trivial visual changes and no Loom as `check`. Exception: single-line copy changes, token-only color/spacing fixes, or PRs where the author has confirmed product sign-off via another channel.
