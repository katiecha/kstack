# What to flag

Extracted from `review-pr-leetcode/SKILL.md`. the defect catalog: super-linear time, wrong data structure, redundant work, and database access patterns.

## What to flag (in-memory algorithmic defects)

### Accidental super-linear time

- **Linear scan inside a loop**: `outer.forEach(x => inner.includes(x))`, `.indexOf` / `.find` / `.some` on an array inside another loop, or `arr.filter(p).length` recomputed each iteration. This is O(n·m). Fix: build a `Set` / `Map` once (O(n)) and look up in O(1), giving O(n+m). Flag `check` on org-bounded n, `blocking` on prod-scaling n.
- **Accumulating spread in a loop or `reduce`**: `acc = { ...acc, [k]: v }` or `acc = [...acc, x]` copies the whole accumulator every step: O(n^2) time and allocations. Fix: mutate a single `Map`/object/array (`acc.set(k, v)` / `acc.push(x)`), or `Object.fromEntries(entries)`. CLAUDE.md already bans accumulating spread in `reduce`: flag `check`, `blocking` on prod-scaling n.
- **Nested loop computing a pairwise relationship** that a hash join, sort, or prefix structure collapses to linear / log-linear. Fix: name it (hash join on the key, sort + two pointers, prefix sum). Severity by n.
- **Repeated sort inside a loop**: sorting the same (or barely-changed) array each iteration. Fix: sort once outside the loop, or maintain order incrementally with a heap / insertion into a sorted structure. Flag `check`.
- **Exponential recursion with overlapping subproblems**: naive recursion (Fibonacci-shaped, subset/path enumeration) with no memo. Fix: memoize (`Map` cache) or convert to bottom-up DP. O(branch^depth) -> polynomial. Flag `blocking` if reachable with non-tiny depth.

### Wrong data structure

- **Array used as a membership set**: repeated `arr.includes(x)`. Fix: `Set`. O(n) lookup -> O(1).
- **Array `.shift()` / `.unshift()` in a hot loop**: each is O(n) (re-indexes the whole array). Fix: iterate with an index pointer, use `push`/`pop` as a stack, or a deque. Flag `check` on a hot path.
- **Linear min/max scan inside a loop** to repeatedly pull the smallest/largest while the set changes, that is O(n) per step. Fix: a binary heap / priority queue (O(log n) per op). Flag `check`; mention there is no built-in JS heap, so a small helper or a maintained sorted insert may be simpler for small n.
- **Repeated prefix/range aggregation**: recomputing a running sum / count / min over a sub-range each query. Fix: a prefix-sum (or difference) array precomputed once -> O(1) range queries; for many updates+queries, mention a Fenwick/segment tree as coach's-corner.
- **String concatenation in a loop building a large output**. O(n^2) in some engines. Fix: push to an array and `join("")`.
- **Manual grouping / join / dedup in JS** when a single `Map`-keyed pass (or, if the data is in the DB, a SQL `GROUP BY` / `JOIN`) is cleaner and asymptotically better.

### Redundant work

- **Loop-invariant computation inside a loop**: a pure value (`.length`, a `Map` build, a config lookup, a regex compile) recomputed every iteration. Fix: hoist it above the loop.
- **Same pure function called repeatedly with the same arguments**: memoize, or compute once and reuse.
- **Multiple passes that could be one**: three separate `.filter`/`.map`/`.reduce` chains over the same large array each allocate and re-traverse. Fix: a single pass when n is large (note: for small n, chaining is more readable: say so).

### Database access patterns

The most expensive complexity bugs are usually at the DB boundary, not in a tight JS loop. Treat these as first-class findings, the fix is almost always to push the work into a single query or bound the fan-out, not to write a cleverer in-memory algorithm.

- **N+1 queries**: a query executed inside a loop (`for (const id of ids) { await getById(id); }`), or a `.map(async …)` that issues one round-trip per element. Each iteration is a network round-trip; total cost scales with n. Fix: a single batched query (`WHERE id IN (...)`), a JOIN that fetches the related rows in one shot, or a prefetch keyed by id into a `Map`. Flag `check` on org-bounded n, `blocking` on prod-scaling n.
- **Load-then-filter**: `SELECT` (or fetch) all rows, then narrow in JS with `.find()` / `.filter()` / `.some()`. This drags the whole table across the wire and filters client-side. Fix: an indexed `WHERE` (or `WHERE id = ?`) that returns only the needed rows. Flag `blocking` when the table scales with prod data; `check` when org-bounded.
- **Unbounded async fan-out**: `Promise.all` / `Promise.allSettled` over a collection whose size scales with prod data (org users, tasks, documents), with no concurrency cap. This exhausts the DB connection pool, trips third-party rate limits, or starves the event loop. Fix: a `p-limit` cap (~5–10), or replace the fan-out with a single batched query / upsert. Flag `check`; `blocking` when the collection is provably prod-scaling and each task hits the DB or a rate-limited API.
- **Sequential `await` on independent I/O**: a `for…of` loop that `await`s each independent call is serial. If the calls are independent, run them concurrently (`Promise.all` with a bound) or fold them into one batched query. Flag `check`.
- **Chunked loop flattened to unbounded `Promise.all`**: if the previous code chunked for rate-limit or memory reasons, replacing it with a flat `Promise.allSettled` is a silent regression. Fix: keep the chunking or move to `p-limit`. Flag `check`.

State the current → achievable cost the same way as an in-memory finding (e.g. "N round-trips → 1 query", "O(rows) transferred → O(matches) with an indexed WHERE"). Name the exact fix (batched `IN`, JOIN, indexed `WHERE`, `p-limit`), not just "do it in SQL".
