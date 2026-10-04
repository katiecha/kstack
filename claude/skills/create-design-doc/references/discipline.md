# Discipline

Extracted from `create-design-doc/SKILL.md`. buildable scope, decisions over instructions, evidence-backed claims, and the dedup pass.

## Scope has to be buildable by the actual team

In-Scope and Out-of-Scope is where a doc quietly becomes fiction. Check it against team size, the
sprint length, and every dependency the team does not control.

- **An in-scope item whose dependency is out of scope is a contradiction, not optimism.** A sweeper
  over rows another doc has not specified cannot be built however much time there is. Find these by
  reading each in-scope item, asking what it reads or writes, then checking that thing exists.
- **Mark externally gated work as gated rather than committing it to a date.** Anything waiting on
  credentials, an entitlement, a vendor approval or another team lands when access does. Say so, and
  say how long the approval takes, because that is the number a reader wants.
- **If the in-scope list is the whole design, it is a wish.** Something has to be second. Name what a
  small team can finish with no external dependency and let that be the critical path.
- **Every out-of-scope entry states why.** The reason is the reviewable part, and it is what keeps the
  item from being re-litigated in review.
- **Deferred work can stay as a decision but must not read as a commitment.** Keep the constraint that
  binds somebody else's work, such as a 30-day clock belonging in MySQL rather than a broker's delayed
  set. Drop the mechanism that would have implemented it.

**A scope cut is a propagation, not an edit.** After removing anything, grep the doc for its name and
for the components it needed. Timeline task lists, Proposed Design prose and Next Steps all go on
committing to deleted work, and every one that survives contradicts the scope list a reviewer just
read.

## Keep Proposed Design about decisions, not instructions

This is the section that bloats. It should be specific enough to explain the general design
decisions and no more. Detail that an individual engineer can settle while implementing does not
belong here.

**The sharpest test:** cut anything that answers *how do I build this*, and keep or add anything that
answers *what goes wrong if I get this subtly right-looking but wrong*. Bloat is almost always the
first kind. The most valuable paragraphs in a design doc are almost always the second.

**Belongs in the doc**, because a reviewer has to rule on it:

- The architecture: what the components are, which are new, and how work flows between them.
- Any choice that would be wrong to make differently, with the reason. A schema column that exists
  to prevent a specific silent failure is a decision. The rest of the columns are not.
- Interfaces that form a contract across teams or layers, such as a publish function whose required
  argument is the whole point.
- Correctness arguments that are not obvious, such as why a key must name an occurrence rather than
  a state, or why a retry budget sized for internal work is wrong for an external one.
- Limits of the guarantee, stated plainly.

**Leave to the implementer**, and cut or collapse it:

- Full schema DDL, column lists, index definitions and nullability reasoning.
- Class shapes, field-name mappings to a vendor's API, and framework internals such as a decorator's
  own implementation. Show how a subscriber is *used*, not how the registration works.
- File layout and naming, build and packaging setup, and dependency registration checklists.
- **Repo-wide conventions**, which are not decisions at all. Every table carries an org id and filters
  on it, schema edits are authored in <orm> with the migration in the same PR, payloads are Zod
  parsed at boundaries. Stating these implies they were chosen here, when a reviewer already assumes
  them. Keep the one case where this design departs from the convention.
- Precedent archaeology: one line naming the precedent is enough. The reader does not need its call
  signature, its helper's name, or why its approach cannot be copied verbatim.
- Config literals, when the two or three numbers that matter can be stated in prose.

**Tests to apply while editing:**

- Would a competent engineer make a materially worse choice without this paragraph? If not, cut it.
- Does another section already say this? Alarm thresholds belong in Monitoring, not restated in
  Proposed Design.
- Is this a code block that shows *how it works* rather than *how it is used*? Cut it.
- Detail worth keeping but not worth reading in place goes to the appendix rather than the bin.

### Examples earn their space when they show a trap

Trimming and adding examples are the same rule applied twice. An example of a mechanism being
implemented is instruction, so cut it. An example of a plausible-looking mistake failing silently is
the highest-value content in the doc, so add it. After a trimming pass, go back and look for places
where the doc asserts a hazard abstractly, because those are cheap to make concrete.

Patterns that pay for themselves:

- **A call site for any contract the design rests on.** If a required argument is the whole point,
  show one call threading it. Five lines beats three paragraphs, and it demonstrates the neighbouring
  rules for free.
- **The query whose `WHERE` clause is the decision**, with the consequence as a trailing comment.
  Two lines of SQL can carry an argument that takes a paragraph in prose.
- **A tempting-versus-correct table** for anything caller-supplied, with a column for how the
  tempting version fails. This is the single most useful shape for a rule an author can get wrong.
- **Real dates or timestamps** whenever ordering or a deadline is involved. "A row can be created
  already breached" reads past. "Occurred 3 March, learned 20 March, deadline expired 13 March" does
  not.
- **Two named tenants** whenever isolation is the claim, walked far enough that the data loss is
  visible.

Skip examples of framework internals, class shapes, config literals, and anything whose example
would just be the happy path.

### Examples earn their space when they show a trap

Trimming and adding examples are the same rule applied twice. An example of a mechanism being
implemented is instruction, so cut it. An example of a plausible-looking mistake failing silently is
the highest-value content in the doc, so add it. After a trimming pass, go back and look for places
where the doc asserts a hazard abstractly, because those are cheap to make concrete.

Patterns that pay for themselves:

- **A call site for any contract the design rests on.** If a required argument is the whole point,
  show one call threading it. Five lines beats three paragraphs, and it demonstrates the neighbouring
  rules for free.
- **The query whose `WHERE` clause is the decision**, with the consequence as a trailing comment.
  Two lines of SQL can carry an argument that takes a paragraph in prose.
- **A tempting-versus-correct table** for anything caller-supplied, with a column for how the
  tempting version fails. This is the single most useful shape for a rule an author can get wrong.
- **Real dates or timestamps** whenever ordering or a deadline is involved. "A row can be created
  already breached" reads past. "Occurred 3 March, learned 20 March, deadline expired 13 March" does
  not.
- **Two named tenants** whenever isolation is the claim, walked far enough that the data loss is
  visible.

Skip examples of framework internals, class shapes, config literals, and anything whose example
would just be the happy path.

## Evidence discipline

The goal is a doc where every claim is either verified, cited, or explicitly flagged as unknown.

1. **Verify repo claims instead of asserting them.** Grep the repo before writing the claim. Counts,
   line numbers, and absence claims are all checkable, and they are usually right, so verifying
   upgrades them from assertion to evidence.
2. **Re-fetch before defending a citation. "I verified this earlier" is not evidence.** A quoted
   vendor figure that was reported as confirmed one day failed to reproduce on the same two pages the
   next, and the confident earlier note was the only thing holding it up. Re-run the check when
   someone challenges a source, and if it no longer reproduces, say so plainly and mark the claim
   unconfirmed rather than defending the memory.
3. **Verify with `file:line`, cite the greppable name.** The line number is for the author's
   checking, not the reader's. Ship `startFilingAutomationRunDB` or `` `OutlookCalendarSyncCheckpoints` ``,
   not the function or table plus a line number, since a unique symbol is faster to find than a
   coordinate and does not rot the next time someone edits above it. Keep a bare file or directory
   path when the reader has to open that file to do the work. Drop the reference entirely when it
   only proves a claim nobody will dispute.
4. **The Overview carries no citations.** It argues about the problem at a level where a specific
   call site is beside the point. "Preclearance and content review both await an email send in the
   request path" makes the case; two controller line numbers in the opening paragraph make the reader
   think the argument needs propping up. Citations start in Proposed Design.
5. **Absence claims are the ones that break.** "Nothing in this repo does X" is the most common
   false statement in a design doc. Check it specifically.
6. **Run the spike rather than reasoning about it** when a claim is about whether something works.
   Write the throwaway probe, run it through the same loader production uses, record the version, and
   delete the probe.
7. **Keep flagged uncertainty.** Open Questions, "unresolved", and "Blocks X" tags are the doc being
   accurate about what it does not know. Removing them makes the doc look more confident than the
   evidence supports, which is the opposite of grounding it.
8. **Never invent a citation.** If a figure has no source, say it has no source and ask where it came
   from.
9. **An unmeasured number comes out, rather than carrying a caveat.** Labelling a guess as an estimate
   is not enough, because a table of numbers reads as data however it is footnoted. Offer to measure
   it, and if that is not happening, delete it and make the surrounding claim qualitative: "one worker    is sufficient at current volumes" is weaker than a figure and more accurate than a fabricated one.
   Deleting a number is a propagation, so grep for it first, since the same estimate is usually
   restated in prose two or three times.
10. **Check who wrote a doc before treating it as house style.** Comparing against existing docs is
   useful, but four samples of unknown authorship is evidence about those four docs, not a convention.
   Say which it is.
11. **Do not cite an in-flight system as precedent.** A project that has not shipped cannot be a
   source of truth for schema shape, alarm design, or launch type, especially when this design will
   land first. Confine it to the Alternatives row where it is being compared, and cite nothing to it.
12. **Distinguish the two kinds of long.** A doc that repeats itself should be deduplicated. A doc
   that is long because it carries argument should be split or collapsed, not cut. Measure per
   section before recommending cuts, and do not promise a word count. Report the delta after each
   pass, including when a pass grew a section, since that is the number used to judge whether a trade
   was worth making.

## Run a deduplication pass near the end

Say each thing once. Reading for this does not work, because the two statements are usually pages
apart and worded differently. Compare sentences across sections mechanically, on shared content words
with stopwords dropped, and inspect anything above roughly half overlap. That found twenty repeated
claims in a doc already through several editing passes.

Where a claim's canonical home is, when it turns up twice:

- A hazard and its mitigation belong in Risks, not in Proposed Design prose as well.
- A drawback of the chosen option belongs in Alternatives, where it is being weighed against
  something.
- A term's definition belongs in Key Terms.
- What a question blocks belongs in Open Questions, not restated beside the action in Next Steps.
- Provisioning specifics belong in either Timeline or the cost section, not both.

**Restatement is allowed when the reader is in a different mode.** A build checklist repeating a
function signature serves a developer who should not have to jump back to Proposed Design for a
return type, and a Timeline naming work items is not restating a mechanism. Judge by whether the
second appearance does work the first cannot.
