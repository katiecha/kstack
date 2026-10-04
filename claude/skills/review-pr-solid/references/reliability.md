# Reliability

Extracted from `review-pr-solid/SKILL.md`. type safety, read-modify-write races, async correlation, retry classification, and AI output validation.

### Type safety as a regression guardrail

Types are the cheapest way to prevent regressions and ambiguity in shared layers. A loose type today is a silent regression tomorrow. This is especially critical for **forms config, model row types, and API request/response contracts**: anywhere a value crosses a module boundary and is consumed by multiple callers.

**Flag as `blocking`:**
- An `any` introduced (or left in place after a refactor) on a shared type used across modules, forms config, model row types, API response shapes. The fix is a precise type or a discriminated union.
- A union widened to include `string | null | undefined` where a literal union was previously enforced, silently allows new invalid values from upstream sources.
- A `as` cast added to bypass a type error in a shared layer. The fix is to fix the underlying type, not silence the checker. (An `as` cast outside a shared layer is the same smell at `check` severity. This one stays at `blocking` because shared-layer casts hide ambiguity from every consumer downstream.)

**Flag as `check`:**
- Two fields that can contradict each other, both written by the same operation and then cross-validated (e.g. persisting `startDate` *and* `dayOfWeek`, or `status` *and* `isComplete`). Cross-validation is a runtime patch for a modelling problem: the inconsistent state is still representable, so something will eventually write it through a path that skips the check, a backfill, an admin tool, a future caller. Fix: persist only the field the other can be derived from and compute the second at read time, or collapse both into one discriminated union, so the contradiction is unrepresentable rather than merely detected. Escalate to `blocking` when both fields are persisted *and* different readers trust different ones, that is a live data-integrity bug, not a modelling preference.
- A net-new shared type whose fields are all optional (`{ a?: string; b?: number }`) when the producer always sets them. Prefer required fields and apply `Partial<T>` at the consumer site if needed.
- An exported function in a shared layer whose return type is inferred rather than annotated. Annotating the return type catches accidental shape drift on edit.
- New `unknown` values that are never narrowed before use. The fix is to narrow with a type guard or schema parser at the boundary.

### Concurrency & lost updates

A write two owners can perform at the same time needs a concurrency story. Wrapping it in a transaction is a *different* guarantee: a transaction makes the write atomic, but two sequential transactions still silently overwrite each other (last write wins). The shape to look for is read-modify-write, load a row, compute from its current values, write the result back.

**Flag as `check`:**
- A read-modify-write on a row that more than one actor can trigger concurrently (two users on a shared record, or a user and a background job), with no optimistic-concurrency guard. Fix: carry the version or `UpdatedAt` from the read into the `WHERE` clause of the write, and return `409` when zero rows are affected so the caller can refetch and retry.
- A full-object `PUT` on a resource multiple people edit, where a stale client payload silently clobbers a concurrent edit to a field the second user never touched. Fix: patch semantics on changed fields only, or a version check as above.

**Do not flag:**
- Single-owner resources (a user editing their own profile), append-only writes, or idempotent upserts where last-write-wins is the intended semantic.
- Partial-failure atomicity, that is the separate rule that multi-step writes must run inside a single <orm> transaction. A transaction is the fix for a half-applied write, not for a lost update.

### Async result correlation

`Promise.all` and `Promise.allSettled` preserve input order, and code routinely relies on that to match results back to their inputs by index (`results[i]` belongs to `items[i]`). The guarantee holds, what breaks is the assumption that the two arrays still describe the same sequence. A `filter` before the map, a conditional `push` inside it, a `continue` that skips an item, or an early `return` in the mapper all shift the alignment by one, and the failure is silent: the data is attributed to the wrong entity, which reads as correct until someone notices one customer's numbers on another customer's row.

**Flag as `check`:**
- Index-based correlation (`items[i]`, `zip`-style pairing, `results.forEach((r, i) => ... items[i])`) where the input array is filtered, conditionally built, or otherwise reshaped anywhere between its construction and the correlation. Fix: carry the key through the async boundary, have the mapper return `{ id, value }` (or `{ item, result }`) so the pairing travels with the data instead of depending on position.
- `Promise.allSettled` results correlated by index where rejected entries are filtered out before the correlation, dropping the failures compacts the array and misaligns every entry after the first failure. Fix: correlate before filtering, or return the key from the mapper.

**Do not flag:**
- A straight `Promise.all(items.map(fn))` whose results are consumed positionally with no reshaping in between, the ordering guarantee covers this, and rewriting it adds noise.

### Transient vs permanent failures

A database error is not one thing. A deadlock, a lock-wait timeout, a dropped connection, or a brief pool exhaustion will usually succeed on the next attempt; a constraint violation, a type error, or a missing column will fail identically forever. Code that catches both in one `catch` has to pick a single policy, and either choice is wrong for half the cases: retrying a constraint violation burns the budget to fail anyway, and skipping a deadlocked row silently drops data that was never actually bad.

**Flag as `check`:**
- A `catch` around a database write in a loop or batch job that logs and continues without distinguishing transient from permanent errors. The rows lost to a transient blip are indistinguishable in the logs from rows that were genuinely invalid, so nobody can tell what needs re-running. Fix: branch on the driver's error code (MySQL `ER_LOCK_DEADLOCK` / `ER_LOCK_WAIT_TIMEOUT` / `PROTOCOL_CONNECTION_LOST`, Postgres `40001` / `40P01` / `57P01`), retry the transient class with backoff via `retryUtils.js`, and let the permanent class fail loudly with the offending row in the log.
- A blanket retry that re-attempts every failure, including permanent ones. Fix: same split, from the other direction.

**Do not flag:**
- A single-statement write in a request path where the caller can retry, or a job whose whole run is re-runnable and idempotent, the retry story is the run itself.

### AI structured output, validation loopback

An LLM/agent boundary is a runtime boundary like any other (see CLAUDE.md "Validate runtime boundaries with Zod"), but a *non-deterministic* one, so it needs more than a single parse. Whenever a code path asks a model for structured (JSON) output and then *consumes* that output, the review checks for the full control loop, not just the happy path:

1. **Validate regardless of coercion.** Even when the provider supports native structured-output / JSON-schema coercion, the response is still validated with a **Zod** schema before use. The model "thinking" it produced valid JSON is not proof: treat native coercion as a hint, Zod as the gate.
2. **Loop errors back, with bounded retries.** On a Zod failure, feed the validation error back to the model ("this field is wrong, here's why") and retry, but with a **capped retry count** so a stubborn model can't slam the API in an unbounded loop.
3. **Deadline / TTL in the request path.** When this runs inside a synchronous web request, enforce a time budget (the senior-eng rule of thumb is ~3–5s). Past the deadline, return a generic error and tell the user to retry rather than blocking the request indefinitely.

Pairs a compile-time generic with the runtime Zod schema (the `BaseTool<TResult, TInput>` + `inputSchema` shape) so the handler gets both intellisense and runtime safety.

**Flag as `blocking`:**
- Model / agent output consumed by persistence, a downstream API call, or any critical path **without a Zod (`.parse` / `.safeParse`) validation step** on the response. The raw model output is trusted directly. Fix: parse the response against a Zod schema at the boundary before use.
- Model output typed as `any` (or `as`-cast into a type) to make it "fit" the expected shape, this launders an unvalidated boundary through the type system. Fix: define the Zod schema and derive the type from it (`z.infer`), do not assert.

**Flag as `check`:**
- A model-output validation that fails "open", on a Zod error it proceeds with a partial/`undefined` value instead of retrying or erroring. Fix: on failure, either loop the error back to the model or fail fast with a handled error; don't silently continue.
- A retry loop around a model call with **no cap** on attempts (or a cap high enough to blow the request budget). Fix: bound the retries with a named constant.
- A model call inside a synchronous request path with **no deadline / timeout**, so a slow or looping model hangs the request. Fix: add a TTL and a generic-error fallback past the budget.
- A hand-rolled retry/backoff around the model call when `retryUtils.js` already covers the mechanics (see **Simplify logic**): reuse it and layer the Zod-revalidation on top.

**Do not flag:**
- A model call whose output is surfaced to the user as free-form text (chat, a draft, a summary) with no structured contract to enforce, there's nothing to Zod-validate.
- An async/background job where a longer or unbounded processing budget is acceptable, the TTL rule is specific to synchronous request paths (still require bounded retries + Zod validation).
