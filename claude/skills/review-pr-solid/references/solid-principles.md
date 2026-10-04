# Solid principles

Extracted from `review-pr-solid/SKILL.md`. the three SOLID principles this lens audits, with the smells and fixes for each.

### SRP: Single Responsibility (and avoiding god objects)

A file, function, or module should have one reason to change. Service and util layers in particular must not mix generic reusable logic with product-specific logic.

**The "is this reusable or product-specific?" test.** For every net-new or modified function in a service, controller, or util layer, ask: is this *reusable* (called from many features, no product-specific assumptions) or *product-specific* (encodes one feature's rules)? If the answer is **both**, split it. Generic logic belongs in a base/shared layer; product-specific logic belongs co-located with the feature.

**Flag as `check`:**
- Any net-new `.ts` file added to `<utils-package>/` that is only imported from one subsystem (e.g. only called by `server/controllers/`). It belongs co-located with its callsite in a `__utils__/` subdirectory, one function per file. `<utils-package>/` is for genuinely cross-cutting helpers used by multiple subsystems. Fires at `check`, not `blocking`, since a misplaced util is recoverable and the call is judgmental (sometimes a single callsite is the first of several).
- Any existing shared file (a shared entity or status helper) that has new functions appended to it whose only callsite is a single new file. Those functions belong with their callsite, not promoted to a shared bucket prematurely.
- Any `.d.ts` type declaration file added to `<utils-package>/` for types used only by one feature. Move the types to the feature's own `__utils__/` or `__types__/` directory.

**Flag as `blocking`:**
- **Logic branching on a specific customer.** `if (organizationId === 4821)`, a check against a customer's name, or an array of org IDs hardcoded in a controller or util pins one customer's arrangement into shared code. Whoever reads it next cannot tell whether the branch is a temporary accommodation, a paid contractual difference, or a workaround for a bug that has since been fixed, so it is never safe to delete and it accumulates. It also does not scale to the second customer who asks for the same thing, and it leaks a customer relationship into a file that anyone can read. The behavior belongs in data, an organization settings column, an entitlement or feature-flag record, a config table, so the code asks *what is this org allowed to do* rather than *which org is this*. Flag any comparison against a literal organization ID or customer name in shared logic as `blocking`; the fix names the column or flag to read instead. A test fixture referencing a seeded org ID is not this.
- A service / controller function that mixes generic logic with product-specific branches in one body (e.g. `if (form.type === 'preclearance') { ... } else if (form.type === 'vendor-review') { ... }` inside a function meant to be generic). The fix is to split: a generic core that takes the product-specific behavior as a parameter or strategy, and product-specific callers that supply their own behavior.

**Flag as `check`:**
- Any net-new `.ts` file that exports more than one function. Each export belongs in its own file named after what it exports.
- Any function over ~80 lines that mixes data-fetching, transformation, and writes. Extract each responsibility into a named sub-helper.
- A service file that has grown past ~5 distinct responsibilities (auth + pricing + notifications + formatting): flag as a god-object risk and propose a split along the "reusable vs product-specific" axis.
- An op, service layer, or handler that is so deeply layered in abstraction that the function body cannot be read top-to-bottom and understood without tracing multiple levels of indirection. If a reviewer cannot determine from reading the function what it does and what it produces, because every concrete step has been delegated to an opaque abstraction, it is over-abstracted. The fix is to either add a short top-of-function prose comment that describes the flow in plain terms, or decompose into named sub-steps whose identifiers are self-explanatory (prefer the latter). Flag as `check`; escalate to `blocking` if the abstraction also makes the code's correctness unverifiable at review time (i.e. the reviewer cannot confirm from the diff that the logic is correct).

**Do not flag (over-abstraction):**
- An unexported helper defined inside a file that is only used by that file's one exported function. Private helpers are implementation details, not SRP violations. Splitting them into their own files creates a chain of single-use one-liners with no callsite diversity, this is over-abstraction, not SRP.
- The "one function per file" rule applies to **public exports**, not to every `const` or arrow function inside a file. A helper that has a single callsite and is not exported belongs in the same file as its consumer, not in its own module.

**Flag as `nit`: over-decomposition (the inverse of god-object):**
- A PR that adds 3 or more small exported helper functions (each ≤ 10 lines) that are each called from exactly one place, where the combined logic could read more clearly as a single inline block or one composed function. Over-extraction into many named functions adds indirection without adding reusability. The test: if each helper has one callsite, is not independently testable as a meaningful unit, and the caller reads more like a call-graph diagram than business logic, the helpers should be inlined. Flag as `nit` with a suggestion to collapse; do not flag if any helper has more than one callsite or is substantively complex on its own.

### OCP: Open/Closed (additive over modifying, reuse over redefine)

Existing, working code should not need to be edited to add new behavior. **Prefer additive changes, new files, new exports, new endpoints, new optional fields, over modifications to existing core logic.**

Classify every modified file in the diff as either:
- **Additive**: net-new file, or net-new export added to an existing file with no edits to existing exports.
- **Modifying**: existing function, class, type, or export edited (signature change, body change, branch added, type narrowed/widened).

Modifying changes to core logic (controllers, models, shared utils, base classes, shared types) carry regression risk. Treat them as `check` by default and require justification in the PR description.

**Flag as `blocking`:**
- A modification to a heavily-used core function (>5 callsites) made to support one new caller's case, when an additive extension (new function, wrapper, or strategy parameter) would have worked.
- A net-new class that re-implements behavior already present in a base class, when the new class could have extended the base instead. The fix is `extends`: duplicate base-class logic is a regression vector.

**Flag as `check`:**
- A new feature implemented by adding an `if/else` branch or `switch` case inside an existing shared function, when the new behavior could instead be composed at the callsite or passed in as a parameter.
- A new argument added to an existing function signature specifically to handle one new caller's case (e.g. `doThing(x, isNewFlow?: boolean)`). The fix is a new function or a strategy passed by the caller.
- A modifying change to a core file (controller, model, shared util, shared type) where the PR description does not explain why the existing behavior had to change. Ask the author to confirm the modification is necessary, not convenient.
- A net-new type or interface that closely mirrors an existing shared type. The fix is to import the existing type, or to derive from it via `Pick`, `Omit`, or intersection.
- A net-new util function that duplicates logic already present in `<utils-package>/` or a sibling `__utils__/`. The fix is to import the existing util.

**Reuse procedure:** see **Simplify logic** below, the search order (utils → client utils → constants → models → sibling feature) and the repo-standard libraries table cover this. The OCP angle adds one specific reminder: for net-new the admin app data-fetching hooks, always check `client/src/hooks/<sharedHooks>.js` first, a duplicate hook with a different query key silently splits the React Query cache.

### ISP: Interface Segregation

Functions should accept only what they actually use.

**Flag as `check`:**
- A util function that accepts a large shared object (`req`, a full model row, an entire form config) but only reads 2–3 fields from it. The fix is to accept only the specific fields needed as named parameters.
- A function whose signature has grown to 5+ optional parameters where different callers use different subsets. Consider splitting into focused functions or using a discriminated union input.
