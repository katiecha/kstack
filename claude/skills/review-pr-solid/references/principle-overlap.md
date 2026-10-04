# Principle overlap

Extracted from `review-pr-solid/SKILL.md`. which principle to name when two of them describe the same finding.

## Notes on principle overlap

Several principles overlap in practice:

- **Avoiding god objects** is SRP, but the fix often looks like OCP (extract a generic core, let callers compose product-specific behavior).
- **Reusing a shared type instead of redefining** is OCP-flavored (extend, don't redefine), but the smell is also DRY/SRP (one source of truth per concept).
- **Backend backward compatibility** is often enforced at the type level, a precise shared response type makes a breaking change a type error, not a runtime surprise.
- **Test coverage** overlaps with backward compatibility (an integration test on the old response shape is the cheapest way to catch a breaking rename) and with type safety (a unit test that locks in the discriminated-union return type catches future widening).
- **Simplification** overlaps with OCP/reuse (import existing util vs new file) and SRP (move query out of controller). Name **Simplification** when the primary win is deleting hand-rolled code in favor of a known helper or repo pattern; name **OCP** when the smell is modifying shared core logic instead of composing.
- **Composability** is the frontend face of OCP: a slot or injected component prop lets a consumer extend a component without editing it, the same way a new export extends a module without modifying existing code. Name **Composability/Controllability** when the fix is a component-API change (slot, injection seam, lifted context, controlled/uncontrolled support); name **OCP** when the fix is on the backend/module side (new function/export/parameter instead of editing shared core).
- **Concurrency** overlaps with **Type safety** at the modelling end: the dual-write rule (two contradictable fields cross-validated instead of one derived) and the lost-update rule are the same instinct applied to different clocks: make the bad state unrepresentable rather than detecting it after something has already written it. Name **Concurrency** when the trigger is two actors racing on one row; name **Type safety** when a single writer can produce the contradiction on its own.
- **AI validation** is a specialization of **Type safety** at a *non-deterministic* runtime boundary: the Zod gate is the same boundary-parsing rule, plus the loopback/retry/TTL controls that a model (unlike a normal caller) requires. Name **AI validation** when the finding is about a model/agent output path specifically; name **Type safety** for ordinary boundary parsing.

When a finding fits multiple principles, name the most actionable one, the one that points the author to the clearest fix.
