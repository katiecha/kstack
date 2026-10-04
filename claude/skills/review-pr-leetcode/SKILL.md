---
name: review-pr-leetcode
description: Review a PR's core logic as an algorithms and data-structures coach: time and space complexity of every non-trivial algorithm, accidental quadratic or exponential blowups at production scale, better data structures and techniques, and database-access complexity bugs (N+1 queries, load-then-filter in JS, unbounded async fan-out), plus a coach's-corner discussion of alternatives. Use when reviewing a PR for performance, complexity, or algorithm choice.
purpose: Review a PR's core logic the way a competitive-programming coach would, analyze the time and space complexity of every non-trivial algorithm in the diff, flag accidental quadratic / exponential blowups on data that scales with prod, recommend better data structures (heap, trie, union-find, monotonic stack, balanced/sorted structures, bitsets) and algorithmic techniques (two pointers, sliding window, prefix sums, binary search on the answer, memoization / DP, BFS/DFS, topological sort), catch the database-access cost patterns that are really complexity bugs (N+1 queries, load-then-filter in JS, unbounded async fan-out), and open an explicit "coach's corner" discussion of more advanced alternatives and their trade-offs even when the current approach is acceptable. Complement to `review-pr-quick` (binary house rules) and `review-pr-solid` (architecture / regression). This skill owns both the in-memory algorithmic analysis AND the DB-access complexity patterns (N+1 / load-then-filter / async fan-out).
inputs:
  - PR number or diff
  - optional expected input size n (per data structure touched): otherwise inferred from the domain (org users, tasks, documents, archived emails) and asked as a question when it decides severity
outputs:
  - an optimization table listing ONLY the hotspots that have an available improvement (current → achievable time/space + the technique); already-optimal code is not listed and gets no complexity callout
  - findings in Conventional Comments format (blocking / check / question / nit) with exact file path, line number, the current Big-O, the achievable Big-O, and the concrete data structure or technique that gets you there. Big-O is stated only because there is a concrete win to quantify
  - a "coach's corner" section of optional advanced-algorithm discussions and trade-offs (not merge blockers)
  - a mandatory comment-count roll-up as the final line (counts of every label, including zeros)
  - one-sentence verdict
success_criteria:
  - identifies every non-trivial in-memory algorithm in the diff (loops over collections, nested loops, recursion, repeated scans, sort-then-search, manual grouping/dedup/joining in JS) but only surfaces complexity when there is a concrete optimization, does NOT annotate already-optimal code with its Big-O
  - states the current AND achievable complexity together (only when an optimization exists) and names the exact data structure or technique that reaches it (e.g. "O(n^2) -> O(n) with a Map keyed by userId"; "O(n) repeated scans -> O(1) amortized with a prefix-sum array")
  - draws on a deep competitive-programming toolbox (prefix/suffix extrema, difference arrays, monotonic stack/queue, Kadane, sliding window, two pointers, binary search incl. on the answer, coordinate compression, sweep line / interval merging, DSU + Kruskal/Prim MST, Dijkstra/Floyd-Warshall/Bellman-Ford, BFS/DFS, topological sort, Tarjan SCC / bridges / articulation points, LCA via binary lifting / Euler tour, tree DP / diameter, 1D-2D-knapsack-LIS-interval-digit DP, Z / KMP / Rabin-Karp / trie, Fenwick / segment tree / sparse table, convex hull / rotating calipers) and names the specific algorithm in the fix
  - calibrates severity to the dominant n: blocking only when the input provably scales with prod data and the blowup is super-linear; question when n is unknown and decides the call
  - separates genuine algorithmic defects (findings) from coach's-corner enrichment (advanced alternatives offered for discussion, never blocking)
  - flags accidental quadratics hidden behind array methods (`.includes()` / `.indexOf()` / `.find()` / `.some()` inside a loop, `arr.filter(...).length` in a loop, spread-in-reduce, repeated `Object.keys().find()`)
  - flags recomputation that should be hoisted, cached, or memoized (same pure call with same args inside a loop; recursion with overlapping subproblems and no memo)
  - flags the wrong container choice (array used as a membership set; array `.shift()`/`.unshift()` in a hot loop where a deque/index pointer is O(1); linear scan for min/max in a loop where a heap is O(log n); repeated sort inside a loop)
  - analyzes DB-access cost as a first-class complexity concern: flags N+1 queries (query inside a loop), load-then-filter (fetch all rows then `.find()`/`.filter()` in JS), and unbounded `Promise.all`/`allSettled` over prod-sized data, naming the concrete fix (batch/JOIN, indexed `WHERE`, `p-limit` cap or single batched query)
  - matches the Conventional Comments severity and line-number conventions in `~/.claude/skills/_shared/comment-format.md` (exact PR-branch line, short code snippet)
failure_modes:
  - flagging micro-optimizations on provably tiny / fixed-size inputs as blocking instead of nit or coach's-corner (the cardinal sin, real-world n matters)
  - recommending a fancy structure (segment tree, balanced BST, trie) where a plain Map/Set or a single sort already wins, purely to show off
  - missing an accidental quadratic because the inner linear scan is disguised as a built-in array method (`.includes`, `.indexOf`, `.find`, `.some`, `.filter().length`) called inside an outer loop
  - missing accumulating spread in a loop or `reduce` (`{ ...acc, [k]: v }` / `[...acc, x]`) which is silently O(n^2) in time and allocations
  - missing recursion with overlapping subproblems that needs memoization, or a DP that recomputes a row it already has
  - treating a single sort (O(n log n)) as a problem when it is the cleanest correct solution, sorting once to enable a linear pass or a binary search is usually the right answer, not a smell
  - proposing an in-memory algorithm when the data lives in the DB and the real fix is a SQL JOIN / indexed WHERE / aggregation, recognize the DB-access pattern and prescribe the SQL fix directly, do not reinvent the work in JS
  - ignoring space: an O(n) time win that allocates an O(n) intermediate map may be the wrong trade in a memory-constrained daemon processing millions of archived emails: state the space cost
  - ignoring constant factors and readability: a clever O(n) that no one can maintain can be worse than an obvious O(n log n); say when the simpler form wins
  - not asking for expected n when it is genuinely unknown and is the deciding factor between nit and blocking
  - flagging stable-sort reliance, numeric-vs-lexicographic sort bugs, or off-by-one as complexity issues (those are correctness bugs, note them, but label them as correctness, not optimization)
  - stating Big-O on code that is already optimal, complexity is only worth the reader's attention when paired with a concrete improvement
judge_rubric:
  - optimization_focus (complexity is stated only where an improvement exists; already-optimal code is not annotated)
  - complexity_accuracy (current and achievable Big-O are correct for time AND space, wherever stated)
  - fix_concreteness (each finding names the specific data structure or technique and the resulting complexity, not "use a better algorithm")
  - severity_calibration (blocking only for super-linear blowup on prod-scaling n; tiny/fixed n is nit or coach's-corner; unknown n is a question)
  - db_access_awareness (catches N+1 / load-then-filter / unbounded async fan-out and prescribes the batch-query, JOIN, indexed-WHERE, or p-limit fix; offers advanced alternatives as discussion, not blockers)
  - pragmatism (weighs constant factors, space, and readability; does not gold-plate working code)
tools:
  - Shell (gh CLI): `gh pr diff {pr_number}` to fetch the diff; `gh pr view {pr_number}` for metadata; `gh pr view {pr_number} --json files --jq '.files[] | "\(.additions) \(.deletions) \(.path)"'` to enumerate changed files
  - Grep/Read: fetch the full file from the PR branch for exact line numbers; trace the source of a collection to estimate its size (is it bounded by a constant, by org size, or by total prod rows?); check whether the data actually comes from a DB query that should do the work in SQL
  - avoid running tests or builds: this is a static complexity audit
  - avoid web search: complexity analysis needs no external docs
---

# Review PR: Algorithms & Data Structures Coach

Review the **core logic** of a PR the way a competitive-programming coach reads a contestant's solution: where is the real work, what is the dominant input size, and is there a cleaner or asymptotically better way using the right data structure or technique? Be generous with interesting alternatives, but never gold-plate code whose input is provably tiny.

**Only talk about complexity when there is something to fix.** Do not annotate already-optimal code with its Big-O, that is noise. State a current → achievable complexity pair *only* when you are proposing a concrete optimization (a finding) or floating a sharper alternative (coach's corner). If the code is already the right algorithm for its input size, say nothing about its complexity.

This skill owns **algorithmic complexity**: both the in-memory analysis and the database-access cost patterns that are really complexity bugs. It is a complement to:
- `review-pr-quick`: binary house rules.
- `review-pr-solid`: architecture, reuse, regression risk.

If the real cost is in the database (querying in a loop, fetching all rows then filtering in JS, unbounded `Promise.all`), the fix is a SQL JOIN / indexed `WHERE` / batched query, **name the SQL or batching fix directly; do not reinvent the work in JS.** See **Database access patterns** below.

## The first question: what is n?

Severity is meaningless without the dominant input size. Before flagging anything, classify every collection the diff iterates:

| Class of n | Examples | Posture |
| --- | --- | --- |
| **Fixed / tiny constant** | enum values, a handful of form sections, table columns, integration list | Almost never a finding. Clarity wins. At most a coach's-corner note. |
| **Bounded by one org** | users in an org, tasks on a calendar, sections in a form | `check` for super-linear; `nit` for linear-with-bad-constant. |
| **Scales with all prod data** | the largest append-only tables (archives, attachments, audit logs), every row across all orgs, daemon/lambda batch input | `blocking` for super-linear; this is where asymptotics actually bite. |
| **Unknown from the diff** | a collection whose source you cannot trace | Ask as a `question`: n is the deciding factor. |

When you cannot determine n and it changes the severity, **emit a `question`**, do not guess.

## Mandatory procedure

1. Fetch the diff: `gh pr diff {pr_number}`, metadata: `gh pr view {pr_number}`. For each file with a hotspot, fetch its full content from the PR branch via `gh api "repos/{owner}/{repo}/contents/{path}?ref={branch}" --jq '.content' | base64 -d | cat -n` for exact line numbers.
2. **Find the hotspots.** Scan added / modified code for non-trivial logic: nested loops, a loop containing an array search (`.includes` / `.indexOf` / `.find` / `.some` / `.filter`), recursion, sort-then-process, manual grouping / dedup / join / set-difference in JS, accumulating spread (`{...acc}` / `[...acc]`) in a loop or `reduce`, repeated computation of the same pure value.
3. **Trace n** for each hotspot's input using the table above (Grep/Read the source of the collection). If it comes from a DB query, ask whether the work belongs in SQL, if so, flag it per **Database access patterns** below with the concrete SQL / batching fix.
4. **Look for an improvement** at each hotspot, using the algorithm toolbox below. If there is no real win, the code is already the right algorithm for its n, move on and say nothing about its complexity. Only when you find a concrete optimization do you derive the current AND achievable complexity (time and space) and name the data structure / technique that reaches it.
5. **Calibrate severity** against n. Super-linear on prod-scaling data is `blocking`; clear win on org-bounded data is `check`; tiny/fixed n or clever-but-marginal is `nit` or coach's-corner; unknown deciding n is a `question`.
6. Produce the report using the output contract. Put genuine defects in **Findings**; put "this works, but here's a sharper approach worth discussing" in **Coach's corner**.

## Rules and toolbox

Open these when you have a hotspot to name a fix for. Every fix must name a specific technique.

- `references/what-to-flag.md`: the defect catalog: super-linear time, wrong data structure, redundant work, and database access patterns.
- `references/algorithm-toolbox.md`: the technique catalog to name a concrete fix from, by data shape.

## Coach's corner (discussion, never a merge blocker)

This is the fun part the user asked for: even when the current code is correct and fast enough, offer one or two **interesting** alternatives and discuss the trade-off, like a coach reviewing a contestant's accepted solution and asking "could we do better, and what would it cost?".

For each item: state the alternative, its complexity, and **when it would actually be worth it** (the n at which it overtakes the current approach, the added space, the maintenance cost). Be honest when the answer is "not worth it here, but good to know." Keep this to the genuinely interesting cases: do not pad.

Examples of good coach's-corner notes:
- "Current `O(n log n)` sort-then-scan is the right call. If this ever needed the *k* smallest rather than all sorted, a partial selection / heap of size k is `O(n log k)`: only matters when k << n."
- "This linear scan is fine at org scale. If it moved into the archived-email daemon (n in the millions), a `Set` lookup or a SQL `IN` would be the move."
- "You could do this in one pass with a running max instead of a prefix array, saving the `O(n)` space, worth it only in the memory-constrained lambda."
- "A Fenwick tree would give `O(log n)` updates here, but with a static array prefix sums are simpler and `O(1)` per query; only reach for the tree if updates become frequent."

## Severity rubric

- `blocking`: super-linear (quadratic or worse) time, or unbounded memory, on a collection that provably scales with prod data; or exponential recursion reachable at non-tiny depth. This will degrade or fall over in production.
- `check`: a clearly better data structure or technique with a real asymptotic win on org-bounded data, where the current code works today but degrades as the org grows.
- `question`: the win depends on the input size and you cannot determine n from the diff. Ask for the expected size before assigning severity.
- `nit`: a constant-factor or readability micro-win, or a better structure on a provably small/fixed input. Optional.
- **Coach's corner**: interesting alternative offered for discussion; not counted as a blocking/check/question/nit finding.

When the simpler form is the right call (clever O(n) is unreadable, or n is tiny), **say so explicitly** rather than flagging, a good coach also tells you when to stop optimizing.

## Output contract

Produce these sections in order.

### Subsystems & hotspots
List the files/functions with non-trivial core logic this PR touches, and one line on what each computes. Do NOT put complexity here, this is just an inventory of where the real work lives.

### Optimization table
**Only list hotspots that have an available improvement.** If a hotspot is already the right algorithm for its `n`, leave it out entirely, no Big-O, no row. One row per genuine optimization:

```
| Hotspot (file:line, fn) | Dominant n | Current | Achievable | Technique |
|---|---|---|---|---|
| server/controllers/foo.controller.js:142, groupTasksByUser | org users × tasks | O(u·t) time, O(1) space | O(u+t) time, O(u) space | hash map join |
```

If nothing in the diff has an available optimization, write "None, core logic is already appropriate for the data sizes involved." and skip straight to Coach's corner.

### Findings
Group by file path; within each file order blocking -> check -> question -> nit. Sort file groups alphabetically by directory then filename (matching how GitHub renders the diff). Use this template:

```
#### `server/controllers/foo.controller.js`

**blocking(accidental quadratic):** line 142, `tasks.filter(t => userIds.includes(t.userId))`
- **Problem:** `userIds.includes` is an O(u) scan inside an O(t) loop -> O(u·t); both scale with org size.
- **Current → achievable:** O(u·t) time → O(u+t) time, O(u) space.
- **Fix:** build `const userIdSet = new Set(userIds)` once, then `tasks.filter(t => userIdSet.has(t.userId))`.

**question(unknown n):** line 88, `candidates.sort(...)` inside the request loop
- **Problem:** sorting per iteration is O(k log k) each; impact depends on how large `candidates` and the loop bound get.
- **Question:** what is the expected size of `candidates` and the loop in production?
```

**Line number rules** (see `~/.claude/skills/_shared/comment-format.md`): cite the exact line from the PR branch (fetch via `gh api ... | base64 -d | cat -n`), quote a short snippet at that line, cite the opening line for a range, never write "line N or function name".

### Coach's corner
Optional advanced-algorithm discussion per the section above. If there is nothing genuinely interesting to add, write "None, current approaches are appropriate for the data sizes involved."

### Deferred to other reviews
N+1, load-then-filter, and unbounded async fan-out are **owned by this skill**: put them in Findings, not here. Only list costs that are genuinely a schema/DDL concern (a missing DB index definition, a missing partition-key on a partitioned table's `WHERE`, a migration) which are a schema concern rather than an algorithmic one. One line each. If there are none, write "None."

### Not checked / insufficient context
Any hotspot whose n or data source could not be traced from the diff.

### Verdict
One sentence: core logic is appropriately efficient / optimize before merge / discuss approach with author.

### Comment counts
The final line. Count every finding by label (coach's-corner items do not count):

```
**Comment counts:** 1 blocking, 2 check, 1 question, 3 nit (7 total).
```
