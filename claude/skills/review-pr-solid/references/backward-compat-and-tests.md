# Backward compat and tests

Extracted from `review-pr-solid/SKILL.md`. breaking API changes and the test-coverage bar, including the mocha to vitest migration.

### Backend backward compatibility

When backend changes ship before (or independently of) the frontend, every modification to a public API surface must be backward compatible. Older clients (cached SPAs, mobile builds, integrations) will hit the new backend with the old contract.

**The "both shapes supported" rule.** When a change to an existing public API surface is unavoidable, the PR should support **both the old and the new behavior simultaneously** during the transition window, accept either request shape, return both old and new response fields, keep both status codes producible, so older clients keep working until they're updated. Removal of the old behavior happens in a *separate, later* PR after clients have migrated. A dual-support PR should reference the follow-up sunset PR or ticket; dual-support with no sunset plan is just permanent duplication.

For every modification to a public API surface, ask: **does this PR keep the old behavior reachable in parallel with the new?** If no, and the old behavior was in use by any client, the change is breaking and must be split into (1) ship dual-support now, (2) remove old behavior later.

**Flag as `blocking`:**
- A field renamed or removed from a public API response (REST endpoint, controller return shape consumed by the client) without dual-support, the response should include both `oldField` and `newField` for the transition window.
- A required field added to a public API request body without dual-support, the validator should still accept payloads without the new field, with a documented default applied server-side.
- A response field's type narrowed (e.g. `string | null` → `string`) without dual-support, the consumer side should still tolerate `null` until clients confirm they no longer emit it.
- A status code changed for an existing endpoint (e.g. `200` → `204`, or `404` → `400`) without dual-support, both the old and new status codes should be producible during transition, or the change should be deferred until a versioned route exists.
- A response shape wrapped (e.g. previously `[...]`, now `{ items: [...], total: N }`) without dual-support, the controller should return either shape based on a versioned route or a request-header flag.

**Flag as `check`:**
- **A shared shape changed without its consumers enumerated.** When a PR edits a model row type, a response shape, an enum, or a constant that other code reads, "the tests pass" only proves that the consumers with tests still work. Before approving, `Grep` the symbol and list every callsite in the review, then say for each one whether it still holds, the ones that break loudest are the ones the type system cannot see: a `SELECT` naming the old column, a data-table `columnMap` entry, a CSV export header, a lambda in `lambda_functions/` on its own deploy cadence, a saved filter or report definition holding the old enum value, and any client build older than this deploy. Flag a change to a shared shape whose consumers were not enumerated as `check`, listing the callsites you found; escalate to `blocking` when a consumer outside the deploy unit (a lambda, a daemon, persisted config) still reads the old shape.
- A new optional field added to a request body where the validation layer rejects unknown fields, confirm the validator still accepts payloads without the new field.
- A daemon or background job that uses a broad falsy-field guard to skip downstream record creation without distinguishing between activity types that legitimately have no steps (e.g. `AccessPersonTask`, `VendorReview`) and types that should have steps but don't due to bad data. The broad guard silently fails to create downstream records for corrupted admin tasks with no error surfaced to ops. Fix: narrow the guard by ActivityType and add a `the project logger.error` for types that should always have steps.
- An enum value removed from a database column or API response, existing rows / cached responses may still carry the old value.
- A controller that adds a new branch returning a different shape under some conditions, the union of return shapes is now part of the contract; document it.
- A PR that ships dual-support but does not link to the follow-up PR or ticket that removes the old behavior. Dual-support without a sunset plan accumulates indefinitely. Require the author to name the follow-up.
- Dual-support implemented as silent fallback (e.g. "if `newField` is missing, derive from `oldField`") with no logging, without an observability hook, you can't tell when clients have migrated and the old path is safe to remove. Ask for a `the project logger.info` (or metric) on the legacy path.

**Do not flag:**
- A net-new field added to a response (additive, backward compatible).
- A net-new endpoint or route (additive).
- An internal-only function signature change with no public API exposure.
- A change that ships proper dual-support and references the follow-up removal PR or ticket, this is the desired pattern.

### Test coverage (and the mocha→vitest migration)

This repo is mid-migration from **mocha + chai + sinon** to **vitest**. New tests must be vitest; existing mocha tests should be left alone unless they're being substantively rewritten (in which case convert them). Every PR that adds or modifies behavior must update its tests in the same diff, drive-by source changes without test updates are how regressions slip in.

**The "where do tests live?" map** (per CLAUDE.md):
- Server controllers/routes/handlers: integration tests in `test/IntegrationTests/<Feature>/*.test.js` (mocha today, vitest going forward), unit tests in `test/UnitTests/*` (mocha today, vitest going forward).
- Server data-table handlers: vitest, run via `pnpm test:datatable`.
- `<models-package>/*`: colocated vitest in `<models-package>/__tests__/*.model.test.ts`.
- `<utils-package>/*`: colocated vitest in `<utils-package>/__tests__/*.test.ts`.
- `<ui-package>/*` components and hooks: colocated vitest in `__tests__/` next to the component, with `*.test.tsx` (jsdom) for rendering / accessibility / data attributes and `*.browser.test.tsx` (Playwright) for userEvent / focus / keyboard / portals.
- `client/src/components/**` and `client/src/hooks/**`: colocated vitest in `__tests__/`, same two-tier strategy as <ui-package>.
- Pure logic extracted to `__utils__/`: vitest unit tests, no React rendering.

**Flag as `blocking`:**
- A net-new server controller, route, handler, or model with no corresponding test file added in the same diff. Server changes that touch persisted data without a test are the highest-risk class of change in this repo.
- A net-new client component, hook, or non-trivial util (`<ui-package>/*`, `client/src/components/**`, `client/src/hooks/**`, `client/src/utils/**`) with no corresponding `__tests__/*.test.tsx` file added in the same diff.
- A new test file written in mocha+chai style, `describe(..., function () {})`, `expect(...).to.equal(...)`, `chai.expect`, `sinon.stub`, `before()` / `after()` hooks, when the area being tested either already has vitest coverage or is one of the migrated areas listed above. The fix is to write the test in vitest: `import { describe, it, expect, vi } from "vitest"`.
- A net-new server endpoint that mutates persisted state with no integration test covering at least the happy path + one auth/permission failure case + one not-found case.

**Flag as `check`:**
- A modifying change to an existing source file that has a colocated test file, where the test file was not updated in the same diff to cover the new branch / new return shape / new error case. Quick check: for each modified source file, `Grep` the diff for the matching `*.test.{ts,tsx,js}` filename; if absent, flag.
- A new vitest test that mocks so heavily it no longer exercises the function under test (e.g. mocking the function's body and only asserting the mock was called).
- A new client component test that exists only as a `*.test.tsx` (jsdom) when the component's primary value is interaction (focus, keyboard, portals): should also have a `*.browser.test.tsx`.
- A new server integration test that does not cover the org-isolation / forbidden-cross-org-access path for any endpoint that reads or writes user-scoped data.
- A test file that was modified but lost coverage of an existing branch (assertion deleted, `it.skip` added without a TODO referencing a follow-up issue).
- New mocha+chai tests in an area that is mid-migration to vitest, even if other mocha tests exist alongside, new ones should be vitest going forward.

**Do not flag:**
- Pure type-only files (`*.d.ts`, type re-exports) without tests.
- Trivial edits to CSS, config, JSON, or markdown.
- Pure renames or import path changes with no behavioral change.
- Changes confined to a Storybook story.
- Existing mocha tests that were not touched by the PR (the migration is gradual, not a blocker on every PR).

> **Database mocking** (real DB, `createDbTestContext`, email stubs, `*.sql-structure.test.ts` split): check these at `check` severity as part of the test-coverage pass.
