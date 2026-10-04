# Algorithm toolbox

Extracted from `review-pr-leetcode/SKILL.md`. the technique catalog to name a concrete fix from, by data shape.

## The algorithm toolbox (name the specific technique in every fix)

This is the heart of the review: pattern-match the code's *shape* to a known technique and name it so the author can look it up. Recommend the **simplest** technique that achieves the win, a `Map` beats a segment tree whenever it suffices. Reach for the heavier structures only when the access pattern (many updates **and** many range queries, online queries, geometry) actually demands them.

### Arrays & sequences
- **Two pointers**: pair/triple search, partitioning, merging two sorted runs, in-place dedup. Signals: nested loop over a sorted (or sortable) array, or `i`/`j` both walking the same array. O(n^2) → O(n) (after an O(n log n) sort if needed).
- **Sliding window** (fixed or variable): longest/shortest/count of subarrays satisfying a monotone predicate (sum ≤ k, ≤ K distinct, no repeats). Signals: recomputing an aggregate over `arr.slice(i, j)` inside a loop. O(n^2) → O(n).
- **Prefix sums** (1D / 2D): many range-sum / range-count / average queries over a static array or grid. Build once, answer each query O(1). 2D prefix sums for submatrix sums.
- **Difference array / imprecise sweep**: many *range updates* (`+v` on `[l, r]`) then one final read. Apply at endpoints, prefix-sum once at the end. O((n+q)) instead of O(n·q). The range-update dual of prefix sums.
- **Prefix / suffix extrema (prefix/suffix min/max, prefix products)**: "best to the left / right of each index", trapping-rain-water-shaped problems, max-product-excluding-self. Precompute `prefMax[i]` / `sufMin[i]` in O(n), then each index is O(1).
- **Kadane**: maximum-sum (or max-product) contiguous subarray / running-best with reset. Signals: nested loop trying every subarray to maximize a sum. O(n^2) → O(n).
- **Coordinate compression**: values are sparse but only their *relative order* matters (huge IDs, timestamps) and you want to index them into an array / Fenwick / segment tree. Sort-unique the values, map to ranks. Enables array-indexed structures over a large value domain.

### Stack / queue / heap
- **Monotonic stack**: next-greater / next-smaller / previous-greater element, largest rectangle in histogram, stock-span, "remove k to make smallest". Signals: nested loop scanning forward/back for the next larger/smaller value. O(n^2) → O(n).
- **Monotonic deque**: sliding-window maximum/minimum (window aggregate that must support pop-front). O(n) for all windows vs O(n·k).
- **Binary heap / priority queue**: repeatedly extract min/max from a changing multiset, k-way merge, top-k, Dijkstra/Prim frontier, scheduling by next event time. O(log n) per op. (No built-in JS heap, a small array-based binary heap helper is standard; for small n a maintained sorted array can be simpler.)

### Searching
- **Binary search** on a sorted array. O(log n) lookup, plus lower/upper-bound for insertion points and counting.
- **Binary search on the answer**: the answer is monotone in a feasibility predicate ("min capacity so all fit in D days", "max min-distance", "smallest threshold that passes"). Binary-search the value, run an O(n) feasibility check. O(answer_range_log · n).
- **Ternary search**: unimodal function, find the peak/valley without a derivative.

### Strings
- **Hash set / Map for grouping, dedup, anagrams**: one pass keyed by a canonical form. O(n·L).
- **Trie (prefix tree)**: prefix queries, autocomplete, many keys with shared prefixes, word-break DP, maximum-XOR-pair (binary trie). O(L) per op, shares prefixes.
- **KMP**: single-pattern substring search / failure-function for borders and periodicity. O(n+m), no hashing collisions.
- **Z-algorithm**: all prefix-match lengths; pattern matching, distinct-substring counts. O(n+m).
- **Rabin-Karp (rolling hash)**: multi-pattern search, substring equality in O(1) after O(n) preprocessing, palindrome/duplicate-substring checks. Watch collisions (double hashing).

### Range-query structures (static vs dynamic)
- **Sparse table**: *immutable* array, many idempotent range queries (min/max/gcd). O(n log n) build, O(1) query. Best when there are no updates.
- **Fenwick tree (BIT)**: point update + prefix/range sum (or count, via coordinate compression), inversion counting, order statistics. O(log n) per op, tiny constant, easy to code.
- **Segment tree**: point/range update + range query for any associative op; lazy propagation for range updates. O(log n) per op. Use only when both updates and range queries are frequent and a Fenwick can't express the op.

### Graphs
- **BFS / DFS**: reachability, connected components, shortest path in an *unweighted* graph (BFS), cycle detection, flood fill. O(V+E).
- **Topological sort** (Kahn's BFS or DFS post-order): dependency ordering, build/task scheduling, DAG-DP order, deadlock/cycle detection on a DAG. O(V+E).
- **Union-Find (DSU)**: dynamic connectivity, grouping/merging, "are these in the same set", cycle detection while adding edges, Kruskal. Near-O(1) amortized with path compression + union by rank.
- **Kruskal MST** (sort edges + DSU) / **Prim MST** (heap from a seed): minimum spanning tree / min cost to connect all nodes. Kruskal O(E log E); Prim O(E log V) (better on dense graphs).
- **Dijkstra** (heap): single-source shortest path, non-negative weights. O(E log V).
- **Bellman-Ford**: shortest path with negative edges, negative-cycle detection. O(V·E).
- **Floyd-Warshall**: all-pairs shortest path / transitive closure on a small graph (V ≲ 400). O(V^3).
- **Tarjan / Kosaraju SCC**: strongly connected components, condensation DAG, 2-SAT. O(V+E).
- **Bridges & articulation points** (Tarjan low-link): critical edges/nodes whose removal disconnects the graph; reliability/biconnectivity analysis. O(V+E).

### Trees
- **Tree DP**: aggregate over subtrees (subtree sizes/sums, max independent set, counts of paths). Single DFS, O(n).
- **Tree diameter**: longest path in a tree: two BFS/DFS, or one DFS tracking the two deepest child branches. O(n).
- **LCA via binary lifting**: many lowest-common-ancestor / k-th-ancestor / path queries. O(n log n) preprocess, O(log n) per query.
- **Euler tour + range structure**: flatten the tree so subtree = contiguous range; combine with Fenwick/segment tree for subtree updates/queries, or LCA via Euler tour + sparse table (RMQ). O(log n) or O(1) per query.
- **Binary lifting (general)**: any "jump 2^k steps" on a functional graph / ancestor chain. O(log n) per jump query.

### Dynamic programming families
- **1D DP**: climbing stairs / house-robber / decode-ways / Kadane-as-DP; state = index, O(n).
- **2D / grid DP**: edit distance, LCS, unique paths, min-path-sum; state = (i, j), O(n·m).
- **Knapsack**: 0/1 (subset reaching a target sum, partition, min coins to a capacity) and unbounded (coin change). O(n·W); roll to a 1D array for O(W) space.
- **LIS**: longest increasing subsequence: patience-sorting + binary search, O(n log n) (vs O(n^2) DP). Generalizes to envelopes / chain problems.
- **Interval DP**: optimal merging/splitting over contiguous ranges (matrix-chain, burst balloons, palindrome partitioning). state = (l, r), O(n^3) / O(n^2).
- **Digit DP**: count numbers in `[L, R]` with a digit property (sum, no-repeats, divisibility). DP over (position, tight, accumulated). O(digits · states).
- **Bitmask DP**: small-set DP (TSP path, assignment, set cover) over subsets, n ≲ 20. O(2^n · n).

### Geometry & intervals
- **Sweep line / line sweep**: events sorted along an axis processed in order: skyline, segment intersections, max-overlap of intervals, closest pair, area of union of rectangles. O(n log n) with a balanced/ordered active set.
- **Interval merging**: sort by start, then merge/insert/count overlaps in one pass. O(n log n). Use for booking/availability, calendar overlap, range coalescing.
- **Coordinate compression + sweep**: many interval add/remove + count queries over a large coordinate space (often paired with a Fenwick/segment tree).
- **Convex hull** (Andrew's monotone chain / Graham scan): outer boundary of a point set, farthest-pair setup, extent problems. O(n log n).
- **Rotating calipers**: on a convex hull: diameter (farthest pair), width, minimum-area enclosing rectangle, max distance between two convex polygons. O(n) after the hull.

> Most production code never needs the bottom three sections. When you cite them it should almost always be in **coach's corner** ("if this grew into a geometry/graph problem, X is the tool"), not as a blocking finding. The everyday wins are: hash map/set, prefix sums, two pointers, sliding window, sort + binary search, a heap, and memoization.
