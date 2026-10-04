# Composability

Extracted from `review-pr-solid/SKILL.md`. component API design: slots, injection seams, lifted context, controlled/uncontrolled support.

### Composability & controllability (component API design)

Applies to `<ui-package>/**` and `client/src/components/**`. Two design levers decide how far a component can be reused without editing it: **composability** (consumers *assemble* the piece from slots/children/injected components) and **controllability** (consumers *drive* its state via controlled/uncontrolled props and exposed hooks). The house style is a small prop surface plus slots, `date-picker.tsx` takes ~6 flat props and its body is pure composition (`Popover` → `Popover.Trigger asChild` → `Popover.Content` → `Calendar`); `data-table.tsx` lifts shared state into `DataTable.Provider` and hangs a flat namespace of subcomponents off it; `calendar.tsx` forwards a `components={{...}}` named prop so callers can inject overrides into `DayPicker` without forking it.

Bias: **composition over configuration**. New variation should arrive as a new slot, an injected component, or a composed callsite, not as another boolean/enum on an existing prop bag. This is the frontend twin of the OCP "additive over modifying" rule.

**Flag as `check`:**
- A net-new or modified component that grows a **wide flat prop bag** (multiple booleans/enums like `showHeader`, `withFooter`, `variantA`/`variantB`, or a `renderX`-per-slot pileup) to cover layout/structure variations that would read more clearly as `children`, compound sub-components (`Card.Header`), or an injected component prop. Fix: expose a slot or accept the piece as `children` / a component-typed named prop instead of a flag.
- A component that **hardcodes an internal piece** a consumer needs to swap (a fixed trigger, a fixed row/cell renderer, a fixed empty-state) with no way to override it. Fix: accept it as a component-typed named prop (`trigger`, `components={{ ... }}`, `renderRow`) or via `children` / `asChild` (Radix `Slot`): mirror the `calendar.tsx` `components` pattern and `date-picker.tsx`'s `Popover.Trigger asChild`.
- **Context boundary placed too low.** Shared state that a *sibling/peer* feature must read (e.g. an AI-assist control that lives next to a date picker and needs the same selected-date state) is defined *inside* the leaf component instead of in a provider one level up. Fix: lift the context to a provider that wraps both the component and its peers, and expose a `use…()` hook (the `DataTable.Provider` + `useDataTableLocalState` shape) so peers hook into the same state rather than re-deriving it.
- **Prop-drilling that a lifted context/hook would remove**: the same value threaded through 3+ intermediate components that don't use it, when a provider + hook at the boundary is the established pattern.
- **Flag-gated copy scattered as ternaries.** A feature flag that renames user-facing labels (`isNewNamingEnabled ? "Vendor" : "Third Party"`) repeated across components makes every new string another edit site, and retiring the flag becomes a manual sweep that reliably misses one. Fix: select a single copy object behind the flag at the boundary (`const copy = isNewNamingEnabled ? NEW_COPY : LEGACY_COPY`) and read fields from it, so the cleanup deletes one object and one ternary. This is a different axis from the prop-bag rule above, the smell is *duplicated flag branches on copy*, not structural variation on a component API, so the "behavior/value props are fine" carve-out below does not apply.
- An interactive component that supports **only controlled or only uncontrolled** mode. Fix: support both, `value` + `onChange` for controlled, `defaultValue` for uncontrolled, and expose state via a hook where consumers need to drive behavior.

**Flag as `blocking`:**
- A change that forces a **downstream fork** to get a variation: a `<ui-package>` component whose closed prop surface leaves a consumer no choice but to copy-paste it into `client/` (or add a near-duplicate `<ui-package>` component) to swap one internal piece. The fix is an injectable slot/component prop on the shared component, a fork is a permanent divergence and a regression vector, same as duplicating base-class logic (see OCP).

**Do not flag:**
- A genuinely leaf, single-use component with a small fixed prop surface and no peer that needs its state, not everything needs a provider or injection seam. Adding a context/slot with one callsite is premature abstraction (mirror the SRP over-abstraction carve-out).
- A flat prop (`disabled`, `placeholder`, `dateFormat`) that configures *behavior/value*, not *structure*, those are appropriate props, not a prop-bag smell. The smell is structural variation encoded as flags.
- `asChild` / `Slot` polymorphism already in use, that is the desired pattern, not a finding.
