---
name: review-pr-solid
description: Audit a PR or branch for SOLID violations, regression risk, backend backward-compatibility breaks, test coverage and style, component composability and controlled/uncontrolled support, concurrency and lost-update guards on read-modify-write paths, AI structured-output validation, and opportunities to reuse existing libraries and repo conventions. Use when reviewing a PR for architecture, design, or regression risk.
purpose: Audit a PR or branch for SOLID violations, regression risk, backend backward-compatibility breaks, test coverage (presence and mocha→vitest style), component composability and controllability (slots/injection/context-boundary/controlled-uncontrolled), concurrency and lost-update guards on read-modify-write paths, AI structured-output validation loopbacks (Zod gate, bounded retries, request-path TTL), and opportunities to simplify logic by reusing existing libraries and repo conventions, focused on co-location, single-export files, premature promotion to shared packages, additive-vs-modifying changes, god-object service layers, reuse of shared types and base classes, type-safety guardrails in shared layers, and OCP breaks in existing functions. Database mocking rules are in scope here too.
inputs:
  - PR number or branch context
outputs:
  - net-new file table (SRP ok? right location? reuses existing shared type/util?)
  - modified file table (additive vs modifying, regression risk on modifying changes)
  - modified shared file list with promotion assessment
  - backend backward-compatibility check (renamed/removed fields, narrowed types, status code changes)
  - composability & controllability check (prop-bag-vs-slots, missing component-injection seam, context boundary placed too low, prop-drilling, controlled/uncontrolled support) for touched `<ui-package>` and `client` components
  - AI structured-output validation check (Zod gate on model output, bounded retries, request-path TTL) for any touched LLM/agent call path
  - type-safety check across shared layers (forms, models, API contracts), including contradictable dual-written fields
  - concurrency check on read-modify-write paths reachable by two actors (optimistic-concurrency guard + `409`)
  - test-coverage check (new source files have tests, modified source files update their tests, new tests use vitest not mocha+chai, and DB mocking is at the right depth)
  - simplification check (hand-rolled logic that duplicates `<utils-package>/`, client utils, `<constants-package>`, <orm>, <query-lib>, zod, data-table framework, or other established patterns, with named existing helper or library in each finding)
  - findings in Conventional Comments format (blocking / check / question / nit) with exact file path and line number for each, grouped by top-level directory then ordered by severity within each directory
  - a mandatory comment-count roll-up as the final line of the review (counts of every label, including zeros)
  - one-sentence verdict
success_criteria:
  - enumerates every net-new file before writing any findings
  - classifies every modified file as additive or modifying, with regression risk noted on modifying changes to core logic
  - checks every modified shared file for premature promotion
  - distinguishes genuinely cross-cutting utils (multi-subsystem) from feature-local ones (single callsite)
  - identifies god-object service files where generic and product-specific logic are mixed in one function
  - applies the "is this reusable or product-specific?" test to every modified service/controller/util function
  - identifies OCP breaks where a new caller added a branch inside an existing function instead of composing at the callsite
  - flags reuse misses (new type, base class, or util that duplicates an existing shared one)
  - flags simplification misses (reimplemented date/string/validation/retry/query/UI-fetch logic when an existing util, model function, or repo-standard library already covers the case)
  - flags backend backward-compatibility breaks (renamed/removed response fields, new required request fields, narrowed types, changed status codes, response shape wrapping)
  - flags backend changes to public API surfaces that do not support both old and new behavior simultaneously during the transition window
  - flags dual-support changes that do not reference a follow-up sunset PR or ticket, or that lack observability on the legacy path
  - flags type-safety regressions in shared layers (`any`, widened unions, `as` casts, optional-where-required-was-enforced, missing return-type annotations on exported functions)
  - flags contradictable dual-written fields that are cross-validated at runtime instead of one being derived from the other
  - flags read-modify-write paths reachable by concurrent actors with no optimistic-concurrency guard (version/`UpdatedAt` check plus `409`)
  - flags logic branching on a literal organization ID or customer name in shared code, naming the settings column / entitlement / flag to read instead
  - flags index-based correlation of `Promise.all` / `Promise.allSettled` results where the input array is filtered or conditionally built in between
  - flags database `catch` blocks in loops and batch jobs that treat transient errors (deadlock, lock-wait timeout, dropped connection) the same as permanent ones
  - enumerates the consumers of any changed shared shape (model row type, response shape, enum, constant) by grep, including consumers outside the deploy unit (lambdas, daemons, persisted config)
  - flags flag-gated user-facing copy duplicated as ternaries across components instead of one copy object selected behind the flag
  - flags ISP violations where a function accepts a large object but reads only a few fields
  - flags composability misses (structural variation encoded as a wide prop bag instead of slots/children/compound sub-components, a hardcoded internal piece with no injection seam, or a closed prop surface that forces a downstream fork)
  - flags controllability misses (context boundary placed too low for a peer to hook into shared state, prop-drilling a lifted context would remove, or an interactive component supporting only controlled or only uncontrolled mode)
  - flags AI structured-output paths that consume model output without a Zod validation gate, lack a bounded retry/loopback, or run in a synchronous request path with no TTL/deadline
  - flags net-new source files (controllers, routes, handlers, models, components, hooks, non-trivial utils) without corresponding test files in the diff
  - flags modifying changes to existing source files where the existing colocated test file was not updated to cover the new branch
  - flags any new tests written in mocha+chai style (`describe(..., function() {})`, `expect(...).to.equal(...)`, `sinon`, `before()`/`after()` hooks): new tests should use vitest (`import { describe, it, expect, vi } from "vitest"`)
  - groups findings by top-level directory (`client/`, `database/`, `packages/`, `scripts/`, `server/`, `test/`, etc.) in alphabetical order, then by severity (blocking → check → question → nit) within each directory, then by file path within each severity bucket
  - cites the exact line number (fetched from the PR branch, not the diff hunk offset) and a short code snippet for every finding
failure_modes:
  - treating <utils-package>/ additions as acceptable without checking whether they have multiple callsites
  - missing modified shared files (the shared entity and status helpers) when scanning for SRP violations
  - flagging OCP without verifying there was no simpler composition option at the callsite
  - not checking .d.ts files added to <utils-package>/ for types used only in one feature
  - approving a "modifying" change to core logic where an additive extension (new function, wrapper, strategy parameter) would have worked
  - not noticing a new type or base class duplicates an existing shared one, the fix is to import or extend, not redefine
  - not checking `client/src/hooks/<sharedHooks>.js` before approving a new co-located hook that hits an admin endpoint, duplicate hooks create split React Query caches with different keys, meaning cache invalidation on one won't refresh the other
  - approving hand-rolled date parsing, retry loops, validation, or list/query logic without grepping `<utils-package>/`, `client/src/utils/`, and sibling feature code for an existing helper
  - suggesting a new npm dependency when the repo already has a utility or pattern for the same job
  - flagging simplification that would require a systemic refactor outside the PR scope as `blocking` instead of `nit` with "defer to follow-up"
  - missing a backend rename/removal of a public API field that breaks existing clients
  - approving a "rename and remove" change in one PR when it should ship as two PRs: dual-support first, removal later
  - flagging a dual-support pattern as duplication without recognizing it as the correct backward-compat pattern
  - approving dual-support that has no observability on the legacy path, without it, the team can't tell when the old code is safe to remove
  - missing a god-object service file accumulating both generic and product-specific responsibilities in one function
  - missing an `any` / widened union / `as` cast added to a shared layer (forms config, model row types, API response shapes) that re-introduces the ambiguity types are meant to prevent
  - accepting runtime cross-validation of two contradictable persisted fields as sufficient, the inconsistent state stays representable and a backfill or admin path will eventually write it; the fix is to derive one field or collapse both into a discriminated union
  - approving a hardcoded organization ID or customer-name comparison because it is "just one customer", nobody can safely delete it later, and it does not survive the second customer asking for the same thing
  - approving positional correlation of async results where the input array is reshaped between construction and pairing, the data lands on the wrong entity and reads as correct
  - accepting a single log-and-continue policy over every database error in a batch job, rows lost to a deadlock become indistinguishable from rows that were genuinely invalid
  - approving a change to a shared shape on the strength of a green test suite, without grepping consumers the type system cannot see (raw SQL column names, data-table `columnMap` entries, CSV headers, lambdas on their own deploy cadence, persisted enum values in saved filters)
  - mistaking a transaction for a concurrency guard, atomicity prevents a half-applied write, not a lost update; a read-modify-write reachable by two actors still needs a version check and a `409`
  - flagging a modifying change as risky without explaining what the additive alternative would look like
  - flagging a small single-use leaf component for lacking a provider or injection seam, that is premature abstraction, not a composability miss; the seam is only warranted when a real peer/consumer needs it
  - flagging a behavior/value prop (`disabled`, `placeholder`, `dateFormat`) as a prop-bag smell, the smell is *structural* variation encoded as flags, not ordinary configuration props
  - missing an LLM/agent call whose structured output is persisted or passed downstream with no Zod validation, the single most important AI-boundary check
  - accepting native provider structured-output/JSON-schema coercion as sufficient without a Zod revalidation gate behind it
  - missing an unbounded model-retry loop, or a synchronous-request model call with no TTL/deadline and generic-error fallback
  - flagging an unexported, single-callsite helper as an SRP violation and demanding it be split into its own file, this is over-abstraction, not SRP; the "one function per file" rule applies only to public exports
  - missing the inverse: approving 3+ small exported helpers each called from exactly one place, when the logic would read more clearly inlined (over-decomposition: flag as `nit`)
  - approving hand-rolled domain logic without first opening the domain util for the entity the PR touches, where the type-resolution helpers and default constants already live
  - approving a net-new controller/route/handler/model/component/hook with no corresponding test file in the diff
  - approving a new test file written in mocha+chai when the same area already has vitest tests, or when the area's test runner is being migrated to vitest
  - listing findings in random order (by discovery order or by severity-only) instead of grouped by directory then by severity, defeats the goal of letting reviewers paste comments file-by-file as they walk the diff
judge_rubric:
  - enumeration_completeness (every net-new file listed, every modified file classified)
  - additive_vs_modifying (every modified file classified, regression risk noted on modifying changes to core logic)
  - location_accuracy (correctly identifies whether a util belongs in <utils-package>/ or co-located)
  - principle_precision (finding correctly names which principle is violated and why. SRP, OCP, ISP, composability, controllability, concurrency, AI validation, type safety, backward compat, test coverage, or simplification)
  - composability_controllability_awareness (catches structural variation forced into a prop bag, a missing slot/injection seam, a context boundary too low for peers, or an interactive component missing controlled/uncontrolled support, and does not over-flag single-use leaf components)
  - ai_validation_awareness (catches model output consumed without a Zod gate, coercion trusted without revalidation, unbounded retries, or a synchronous-path model call with no TTL)
  - reuse_awareness (catches new code that should reuse an existing shared type, base class, or util)
  - simplification_awareness (catches hand-rolled logic replaceable by existing utils, models, constants, or repo-standard libraries; fix names the specific symbol or pattern to use)
  - backward_compat_awareness (catches breaking backend changes, renamed/removed fields, narrowed types, status codes; verifies dual-support of old + new behavior during transition windows; flags missing sunset plans and missing observability on the legacy path)
  - test_coverage_awareness (catches missing tests for new source files, missing test updates for modified source files, and new mocha+chai tests that should be vitest)
  - fix_specificity (fix describes a concrete additive alternative or names the existing shared type/util to reuse, not just "compose it")
  - finding_ordering (findings grouped by top-level directory in alphabetical order, then by severity within each directory)
tools:
  - Shell (gh CLI): gh pr diff {pr_number} to fetch the diff; gh pr view {pr_number} for metadata; gh pr view {pr_number} --json files --jq '.files[] | "\(.additions) \(.deletions) \(.path)"' to list changed files with stats
  - Grep/Read: trace import callsites to verify whether a util is used by one subsystem or many; locate existing shared types/base classes that new code should reuse; grep `<utils-package>/`, `client/src/utils/`, `<constants-package>/`, and sibling feature folders for helpers before flagging reimplemented logic; locate the existing test file colocated with a modified source file
  - avoid web search: all conventions are defined in this skill and CLAUDE.md
  - avoid running tests or builds: this is a static structure audit only
---

# Review PR: SOLID, Regression Risk, Backward Compatibility

Focused audit for SOLID violations, regression risk, and backend backward compatibility. Use `gh pr diff` or `@Branch` for context. Do not run tests or builds.

The bias of this review is **additive over modifying**. New behavior should arrive as new files, new exports, new endpoints, new optional fields. Modifications to existing core logic carry regression risk and require explicit justification.

## The audit, rules by area

Read the reference file for each area you are auditing. Do not review from memory: open the file.

- `references/solid-principles.md`: the three SOLID principles this lens audits, with the smells and fixes for each.
- `references/composability.md`: component API design: slots, injection seams, lifted context, controlled/uncontrolled support.
- `references/simplification.md`: hand-rolled code that an existing library, util, or repo convention already covers.
- `references/reliability.md`: type safety, read-modify-write races, async correlation, retry classification, and AI output validation.
- `references/backward-compat-and-tests.md`: breaking API changes and the test-coverage bar, including the mocha to vitest migration.
- `references/principle-overlap.md`: which principle to name when two of them describe the same finding.

## Mandatory procedure

1. Fetch the diff: `gh pr diff {pr_number}` or use the provided branch context. For each file with findings, fetch its full content from the PR branch via `gh api "repos/{owner}/{repo}/contents/{path}?ref={branch}" --jq '.content' | base64 -d | cat -n` to get exact line numbers before writing findings.
2. **Net-new files.** List every file with `changeType: ADDED`. For each one, answer:
   - Does it export more than one thing? (SRP)
   - Does it belong in `<utils-package>/` or should it be co-located with its callsite? If unsure, use Grep to check how many distinct subsystems import it.
   - Is there an existing shared type, base class, or util it should reuse instead of defining anew? Grep for similar names and shapes before approving.
   - Could this logic call an existing helper in `<utils-package>/`, `client/src/utils/`, or `<models-package>` instead of reimplementing? (Simplification)
3. **Modified files, additive vs modifying.** List every file with `changeType: MODIFIED`. For each one, answer:
   - Is the change **additive** (new export with no edits to existing code) or **modifying** (existing function/export/type edited)?
   - If modifying, is the change to core logic (controller, model, shared util, base class, shared type)? If so, was an additive extension considered? (OCP)
   - Does the modification mix generic and product-specific logic in one function? (SRP / god object)
   - For every modification to a shared service file (e.g. `*Utils.js`, `*Utils.ts`, `*Service.ts`): is the new function called from more than one place, or just one new file? (SRP / premature promotion)
4. **Type safety.** Scan the diff for shared-layer regressions: `any`, widened unions, `as` casts, optional-where-required-was-enforced, missing return-type annotations on exported functions, unnarrowed `unknown`. Also check for two persisted fields that can contradict each other being written together and cross-validated, where deriving one (or a discriminated union) would make the bad state unrepresentable.
4a. **Concurrency.** For each write in the diff, identify read-modify-write shapes (load a row, compute from its current values, write back). For each one, ask whether two actors, two users on a shared record, or a user and a background job, can reach it concurrently. If so, check for a version / `UpdatedAt` guard in the `WHERE` clause and a `409` on zero affected rows. Do not accept a surrounding transaction as the guard; it prevents partial writes, not lost updates. Skip single-owner resources, append-only writes, and intentional last-write-wins upserts.
4b. **Async result correlation.** For each `Promise.all` / `Promise.allSettled` in the diff whose results are consumed positionally, trace the input array from construction to correlation. If anything filters, conditionally pushes, skips, or early-returns in between, or if rejected results are filtered out before the pairing: flag per **Async result correlation** and propose returning the key from the mapper.
4c. **Transient vs permanent failures.** For each `catch` around a database write inside a loop, batch, or background job, check whether it distinguishes retryable errors (deadlock, lock-wait timeout, dropped connection) from permanent ones (constraint violation, bad column). A single log-and-continue policy for both, or a blanket retry over both, is a `check` per **Transient vs permanent failures**.
4d. **Customer-specific branching.** Grep the diff for comparisons against literal organization IDs or customer names in non-test code. Each one is `blocking` per **SRP**; the fix names the settings column, entitlement, or flag to read instead.
5. **Backend backward compatibility.** Scan the diff for public API surface changes: renamed/removed response fields, new required request fields, narrowed response types, changed status codes, wrapped response shapes. For each, ask:
   - Does the PR support **both** the old and new behavior simultaneously during the transition window?
   - If yes, is the legacy path observable (a the project logger line or metric) so the team knows when clients have migrated?
   - If yes, does the PR reference the follow-up sunset PR or ticket?
   - If no dual-support, is there evidence that no client uses the old behavior (internal-only endpoint, recently shipped, etc.)?
   Flag missing dual-support as `blocking` unless the old behavior was internal-only. Flag missing sunset plan or missing legacy-path observability as `check`.
6. **ISP.** Scan function signatures in new and modified files for large object params and 5+ optional-param signatures.
7. **Composability & controllability.** For each touched component in `<ui-package>/**` or `client/src/components/**`:
   - Does structural variation ride on a wide flat prop bag (booleans/enums, `renderX` pileup) where slots / `children` / compound sub-components / an injected component prop would read better? (composability)
   - Is an internal piece a consumer would need to swap hardcoded with no seam (`children`, `asChild`/`Slot`, or a component-typed named prop like `calendar.tsx`'s `components`)? (composability)
   - Does a closed prop surface force a downstream fork (copy into `client/` or a near-duplicate `<ui-package>` component) to get a variation? (composability, `blocking`)
   - Is shared state defined inside a leaf component that a sibling/peer feature needs to read, when a provider one level up + a `use…()` hook (the `DataTable.Provider` shape) would let peers hook in? Is a value prop-drilled through 3+ intermediaries a lifted context would remove? (controllability)
   - Does an interactive component support both controlled (`value`/`onChange`) and uncontrolled (`defaultValue`) modes? (controllability)
   - Do not flag single-use leaf components with no peer/consumer needing the seam, that is premature abstraction.
8. **AI structured output.** For each touched code path that calls an LLM/agent and consumes *structured* output:
   - Is the response validated with a Zod schema (`.parse` / `.safeParse`) before use, even when native provider coercion is available? Output consumed by persistence / a downstream call with no Zod gate → `blocking`. Output typed `any` or `as`-cast to fit → `blocking`.
   - On a Zod failure, does it loop the error back to the model and retry with a **bounded** cap (not unbounded, not budget-blowing)? Missing/failing-open → `check`.
   - If it runs in a synchronous request path, is there a TTL/deadline (~3–5s) with a generic-error fallback? Missing → `check`.
   - Is a hand-rolled retry/backoff used where `retryUtils.js` already covers the mechanics? → `check` (see Simplify logic).
   - Do not flag free-form text output (chat/draft/summary) with no structured contract, or background jobs where a longer processing budget is acceptable (still require bounded retries + Zod validation there).
9. **Simplify logic.** For each net-new or substantially modified function (especially utils, controllers, hooks, and handlers over ~25 lines):
   - Run the **search order** from **Simplify logic** (utils → client utils → constants → models → sibling feature).
   - Compare against the **repo-standard libraries and patterns** table; flag hand-rolled equivalents as `check` or `nit` with the **named** existing symbol or pattern in the Fix line.
   - Note intentional complexity in the net-new/modified file tables when no simpler in-repo option exists.
10. **Test coverage.** Walk every source file in the diff:
   - For each net-new source file (controller, route, handler, model, component, hook, non-trivial util), check whether the diff also adds a corresponding test file in the expected location (see the "where do tests live?" map). Missing test → `blocking`.
   - For each modified source file, locate its colocated test file and check whether that test file was also modified in this diff. If the source change is non-trivial and the test file is unchanged → `check`.
   - For every net-new test file in the diff, scan the imports / assertion style. If it uses `chai`, `sinon`, `mocha`'s `function() {}` callbacks, or `before()`/`after()` hooks instead of vitest's `import { describe, it, expect, vi, beforeAll, beforeEach } from "vitest"` → flag (`blocking` if the area is migrated, `check` if mid-migration).
   - For new server endpoints that mutate persisted state, verify the integration test covers happy path + auth/permission failure + not-found. Missing critical case → `blocking`.
11. Produce the report using the output contract below, findings grouped by top-level directory in alphabetical order, then by severity (blocking → check → nit) within each directory, then by file path within each severity bucket.

## Output contract

```
## SOLID + regression audit

### Net-new files
| File | SRP ok? | Right location? | Reuses existing shared type/util? | Simpler in-repo option? | Has test? | Notes |
|---|---|---|---|---|---|---|

### Modified files, additive vs modifying
| File | Additive / Modifying | If modifying: core logic? | Regression risk: low / medium / high | Test updated? | Notes |
|---|---|---|---|---|---|

### Modified shared files
[list each, noting what was added and whether it belongs there]

### Backend backward compatibility
| API surface change | Backward compatible? | Both old + new supported? | Legacy path observable? | Sunset PR/ticket |
|---|---|---|---|---|

### Type safety in shared layers
[list any `any`, widened union, `as` cast, optional-instead-of-required, or missing return annotation in forms / models / API contracts]

### Test coverage
[for each net-new source file: does the diff add a colocated test? for each modified source file: was its colocated test updated? for each new test file: vitest or mocha+chai? note any missing happy-path/permission-failure/not-found coverage on new server endpoints]

### Simplification opportunities
| File / function | Hand-rolled pattern | Existing util / library / convention to use | Severity if not addressed |
|---|---|---|---|
[one row per opportunity found, or "None, grep'd utils/constants/siblings; no duplicate helpers identified"]

### Findings

Labels, ordering, line-number rules and the mandatory count roll-up are defined in `~/.claude/skills/_shared/comment-format.md`. Read it, do not restate it. Two additions specific to this lens: use a `####` heading per top-level directory so the reviewer can paste the comments file-by-file as they walk the diff, and every finding body carries a `Principle:` line.

#### `client/`

**blocking(short title):** `client/path/to/file.tsx` line N, `exact code at that line`
- Principle: SRP / OCP / ISP / Composability / Controllability / Concurrency / AI validation / Type safety / Backward compat / Test coverage / Simplification
- Problem: one sentence
- Fix: one sentence (must name the additive alternative, the specific existing shared type/util/library to reuse, or the canonical helper to use, `dateUtils.*`, `retryUtils.*`, etc.)

**check(short title):** `client/path/to/file.tsx` line N, `exact code at that line`
- Principle: SRP / OCP / ISP / Composability / Controllability / Concurrency / AI validation / Type safety / Backward compat / Test coverage / Simplification
- Problem: one sentence
- Fix: one sentence (name the existing util, constant, library, or pattern to use)

**nit(short title):** `client/path/to/file.tsx` line N, `exact code at that line`
- Principle: SRP / OCP / ISP / Composability / Controllability / Concurrency / AI validation / Type safety / Backward compat / Test coverage / Simplification
- Problem: one sentence
- Fix: one sentence

**question(short title):** `client/path/to/file.tsx` line N, `exact code at that line`
- Principle: SRP / OCP / ISP / Composability / Controllability / Concurrency / AI validation / Type safety / Backward compat / Test coverage / Simplification
- Problem: one sentence
- Question: what you need the author to clarify before severity can be decided

#### `packages/`

[same structure: blocking → check → question → nit, file-path sorted within each]

#### `server/`

[same structure]

#### `test/`

[same structure]

[…and so on for any other top-level directory touched by the PR, in alphabetical order]

### Not checked / insufficient context
[List any files or callsites that could not be verified, with reason]

### Verdict
One sentence: clean / restructure before merge / minor cleanup needed.

### Comment counts
The final line of every review. Count every finding by label and list all four in this fixed order, including any with a count of zero:

**Comment counts:** 0 blocking, 3 check, 1 question, 2 nit (6 total).
```

**Line number rules:**
- Always cite the exact line number from the file on the PR branch (not from the diff hunk offset). Fetch the file with `gh api ... | base64 -d | cat -n` to get numbered lines.
- Quote a short snippet of the code at that line (the function name, statement, or expression being flagged) after the line number so the reader can verify context without reopening the file.
- For findings that span a range (e.g. a function body), cite the opening line of the construct.
- Never write "function or line" as a placeholder: always resolve to the actual line number before writing the report.

If a top-level directory has zero findings, omit its `####` section entirely (do not write an empty heading). If the entire PR has zero findings, write "None." for the Findings section.
