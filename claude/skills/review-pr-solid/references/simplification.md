# Simplification

Extracted from `review-pr-solid/SKILL.md`. hand-rolled code that an existing library, util, or repo convention already covers.

### Simplify logic (libraries and repo conventions)

Before approving new helpers or non-trivial control flow, **search for an existing solution**. The goal is fewer lines and one source of truth, not novelty. Every simplification finding must name the **existing symbol, module, or repo pattern** to use (grep result or known path), not vague advice like "use a library."

**Search order (run Grep before flagging reimplementation):**
1. `<utils-package>/`: the cross-cutting helpers (`stringUtils.js`, `dateUtils.js`, `csvUtils.js`, `retryUtils.js`, `validationUtils.js`) plus one domain file per major entity. Open the domain file for the entity the PR touches before accepting hand-rolled logic: these files accumulate commonly-missed helpers (type resolution, occurrence expansion, default counts) that authors re-implement because they did not know to look.
2. `client/src/utils/`: the client-side equivalents (`StringUtils.js`, `DateTimeUtils.jsx`, and the domain formatters), plus feature-local `__utils__/`
3. `<constants-package>/`: named enums and IDs (never raw integration numbers; use a named enum in `<constants-package>`)
4. `<models-package>`. DB access belongs in models, not reimplemented queries in controllers
5. Sibling feature code, same directory or module often already solved the shape once

**Repo-standard libraries and patterns** (prefer these over hand-rolled equivalents when the dependency is already used in the touched package):

| Hand-rolled smell | Prefer |
| --- | --- |
| Manual date parse/format/timezone math | `dateUtils.js`, the recurrence helper, or `date-fns` (UTC-safe patterns per CLAUDE.md) |
| String trim/slug/case/pluralize | `stringUtils.js` or client `StringUtils.js` |
| CSV/TSV parsing or export | `csvUtils.js` / `exportUtils.js` |
| Retry/backoff loop | `retryUtils.js` |
| Ad-hoc input validation | `validationUtils.js`, the feature's own validation helper, or **zod** (already in workspace `package.json`) |
| Raw SQL string concat in controller/route | <orm> via the shared DB accessor in `<models-package>` |
| Manual row types for DB tables | the ORM's inferred row types |
| `useEffect` + `fetch` for server state | <query-lib> + `useAuthenticatedFetch()` |
| New admin data-fetching hook | Existing hook in `client/src/hooks/<sharedHooks>.js` if same endpoint |
| Bespoke paginated/filterable table endpoint | Data-table handler framework |
| New REST route without typed contract | ts-rest in `server/routes/*` (TypeScript routes) |
| Custom error/status mapping | `apiError` / established controller `next(err)` patterns |
| Lambda handler boilerplate | the shared handler wrapper in `<utils-package>` |
| Sequential `await` for independent I/O | `Promise.all` / `Promise.allSettled` |
| Nested ternaries for null guards | Optional chaining |
| `integrationId === 1` style magic numbers | a named enum in `<constants-package>` |
| Duplicate block copied from another function in the PR | Extract to shared helper or call existing util: do not copy-paste |

**Flag as `check`:**
- Net-new util function whose body closely matches an existing export in `<utils-package>/` or `client/src/utils/` (same inputs/outputs or rename-only diff). Fix: import the existing helper.
- Hand-rolled validation (long `if` chains on `req.body`) on a surface where sibling routes use zod or `validationUtils`: align with the local convention.
- Custom retry/sleep loop instead of `retryUtils.js` / `sleep.js`.
- Controller or route with inline SQL or multi-table query logic that belongs in `<models-package>` (thinner controller, simpler review).
- New paginated list/filter/sort endpoint duplicating data-table patterns already used in the same feature area.
- Client hook re-fetching an endpoint already wrapped in `<sharedHooks>.js` or an existing feature hook.
- Deeply nested `if/else` or repeated branches that could be a lookup map, early returns, or a small extracted pure function in `__utils__/` (keeps React components thin).
- Two or more sequential `await` calls with no data dependency between them.

**Flag as `nit`:**
- Magic string/number that exists as a named constant in `<constants-package>/` for the same domain.
- Verbose `x ? x.foo() : undefined` where `x?.foo()` suffices.
- Logging via `console.*` in server code instead of the project logger (see CLAUDE.md).
- Suggesting simplification that is correct but **out of PR scope** (large refactor): note as optional follow-up, not a merge blocker.

**Do not flag:**
- New logic that is genuinely feature-specific with no existing util (co-locate in `__utils__/`, do not force into `<utils-package>/`).
- Adding a dependency not already in the workspace when no in-repo util exists: say so in "Not checked" rather than inventing a library name.
- Replacing working legacy JS with TypeScript conversion when the PR did not touch that file substantively (gradual migration).
- Simplification that would change public API shape or require dual-support, backward compat wins; simplify in a follow-up PR.

**Simplification procedure:** for each net-new or substantially modified function over ~25 lines (or any new util file), run targeted Grep on distinctive strings (error messages, column names, status literals, date format tokens) across `<utils-package>/`, `<models-package>/`, and the feature directory. If a match exists, flag as `check` with the import path to use.
