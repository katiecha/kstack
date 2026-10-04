# Structure

Extracted from `create-design-doc/SKILL.md`. section order, collapsible headings, Key Terms, and acyclic top-down diagrams.

## Document structure

- **Every heading-2 section is a collapsible toggle**, so the doc reads as an outline that expands
  section by section.
- **Close each section with a blank line then a divider**, both at top level rather than indented,
  so the divider stays visible when the section is collapsed.
- **Heading depth stops at two levels.** Heading-2 for sections, heading-3 for their parts. Anything
  deeper becomes a bold text line, which keeps the table of contents readable and trades away anchor
  links for those labels deliberately.
- **Only heading-2 sections toggle. Never nest a toggle inside one.** A collapsible block inside an
  already-collapsible section is confusing to read and to navigate. Everything inside a section is
  plain content: prose, bullets, tables, code blocks.
- **Implementation detail goes to an appendix**, not inline and not deleted. Full schema DDL, vendor
  adapter caveats, and packaging or registration checklists belong in a final `Appendix` heading-2
  section, with the body pointing at it in a clause ("Full DDL is in the appendix"). This is the
  house pattern: the Workflows doc keeps every verbose payload example in an appendix and its
  Proposed Design is about 600 words as a result.

## Diagrams

A diagram is worth more than the prose it replaces, and it is also the easiest thing in the doc to
make unreadable. Two failures cost real rework, and both were mechanical rather than aesthetic.

- **Keep the graph acyclic, with exactly one entry node.** A single edge pointing back to an earlier
  node makes the graph cyclic, and Mermaid's layered layout resolves a cycle by demoting the first
  stage. One back-edge is enough to render "1. Publish" at the bottom of a top-down chart.
- **Express a round trip as a terminal node or a sentence, never as a back-edge.** A node reading
  "settled status published as a new event, which starts this path again at the top" says the same
  thing and preserves the ordering.
- **Pick one grouping axis and hold it.** Grouping three boxes by deployment location and a fourth by
  code package is the single most confusing thing a diagram can do, because the reader cannot tell
  what the boxes mean. Stages, layers, or locations: choose one.
- **Aim for eight to ten nodes.** Twelve nodes inside four subgraphs with cross-group edges was
  rejected as too detailed; nine nodes in a flat chain was not. Subgraphs earn their place only when
  no edge crosses between them.
- **Verify it mechanically before shipping it.** Parse the edges, run a topological sort, and confirm
  the graph is acyclic, that exactly one node has no incoming edge, and that every node named in an
  edge is declared. Eyeballing a diagram does not catch a cycle.
- **Put what the diagram cannot carry in one sentence beneath it.** Fan-out to several subscribers and
  the dead-letter terminal state are both cheaper as a sentence than as nodes.
- **Re-check the surrounding prose after any diagram edit.** Text saying "everything here is new" or
  referring to "stage 4" goes stale the moment nodes or groups change.

## Section conventions

- **Overview closes with Goal and Decision.** Open with the narrative: what happens today, why it
  does not work here, and what the proposal contains. Then land the two bullets last, as the takeaway
  a reader carries out of the section:

  ```markdown
  - Goal: [one sentence on what capability this gives, in plain terms]
  - Decision: [the chosen mechanism, the one new dependency it adds, and the single sentence that
    says where the guarantee actually comes from]
  ```

  Do not lead with them. The bullets only land once the reader knows why the current approach fails.
- **Key Terms**: define only two kinds of term, words being narrowed to a specific local meaning and
  mechanisms invented in this design. Skip anything a senior engineer already knows. Two or three
  sentences each, in this shape: what it is in plain words, then why it exists or what breaks without
  it. The second half is the point, so an entry that only says what the thing is has not earned its
  place. Name the cost of absence rather than the benefit of presence where you can, since
  "reconstructing one filing means correlating timestamps across two tables by hand" lands and "gives
  good traceability" does not. Cut any term whose reason for being there has been deferred out of
  scope. Prefer fewer, fuller entries over a long thin glossary, and defining a term the body also
  explains is fine when a reader meets it earlier than that.
- **Alternatives and Simplifications belong together**, as two subsections under one heading rather
  than two sections, since a reader weighing one is weighing the other. Alternatives asks whether a
  *different* system should carry the work. Simplifications asks whether a *smaller version of this*
  system would do, so every piece of machinery is present by decision rather than by default. Give
  each simplification a status of **Open**, **Recommended**, or **Rejected**, and include genuine
  rejections with reasons so it does not read as one-sided advocacy for cutting. Watch for the same
  option appearing in both, which is the most likely duplicate in the doc.
- **Monitoring / Observability** answers three questions, on the stated assumption that nothing is
  working, so every guarantee gets its own detector and no detector is trusted to cover another's
  failure. The three questions: what does a healthy or unhealthy system look like, what does it mean
  to recover, and how do we not lose data. Answer the first with a bulleted list of invariants, each
  bullet named for the alarm that watches it, the second with a named recovery path per failure class,
  and the third with the guarantee at each hop plus the gaps no guarantee covers. Bullets beat a table
  here, since naming the bullet after the alarm makes the watcher column unnecessary. **State each
  detector once, in that first list.** Restating a detector per hop reads as thoroughness and is
  duplication, and the third answer earns its space through the gaps it admits rather than the chain
  it recites.
- **Requirements versus Success Metrics**: Requirements is the reviewable contract. Success Metrics
  carries only the measurements that are not obvious from it, and says so.
- **Timeline**: if work runs on parallel tracks, use a grid with one column per track and one row per
  week, so a reader can follow a column down or a week across. Call out cross-track hand-offs
  explicitly rather than burying them as sub-bullets.
- **When the doc is one project inside a program, key the Timeline to the program plan.** Take the
  weeks and milestone ids from the program rather than inventing a sprint, and say they move when it
  moves. Then filter hard: include only milestones whose project ids actually name this project. A
  program week labelled for the parent workstream usually belongs to a sibling project, and claiming
  it overstates what this doc owns. Separate build weeks, where someone is writing this code, from
  later gates where the project appears only as an already-deployed dependency; listing gates as rows
  makes three weeks of work look like nine.
- **Show the arithmetic behind any duration, never just the number.** Taking a schedule someone else
  wrote and restating it as "roughly three weeks for two engineers" is circular, not an estimate.
  Derive available capacity out loud, including on-call rotation and how many workstreams the same
  people are split across, land on engineer-days, then say whether that is generous or light for the
  listed scope and which item is likeliest to slip. A reader who disagrees can then point at the step
  they disagree with.
- **References**: bare source links only, no trailing annotations. Before stripping annotations,
  check whether any fact lives *only* there, and move it into the body first.
- **Data-model tables**: include an Example column, and tie every example to the doc's one running
  scenario so the table reads as a single story. In the appendix, give columns and indexes as a table
  with a row per entity rather than as DDL, since a table lets a reader compare the entities and the
  copy-pasteable version arrives with the PR anyway.
- **Parallel things get symmetric treatment.** If the design adds three tables, each gets the same
  columns at the same depth. One entity with full DDL and three paragraphs while its siblings share a
  thin list reads as arbitrary, and a reader starts wondering what they are not being told about the
  others. Asymmetric detail is a signal to move that detail out, not to pad the rest.
- **Collapse reference subsections into one worked example.** Separate Publishing, Subscribing and
  configuration subsections make a reader assemble the answer to "how do I use this" from three
  places. One numbered walkthrough beats all three, and the example should deliberately not be the
  doc's primary use case, so it reads as a general recipe. Close it with what the framework provides
  and what the author still owns, which turns scattered handler rules into a contract.
- **Next Steps is only what an engineer types**, every line a numbered step, ending with a "done when".
  Requesting an entitlement, running a spike, naming an on-call owner and confirming vendor pricing are
  process rather than engineering: they belong in Open Questions, which already records what each one
  blocks.
- **Timeline cells are numbered lists**, not paragraphs. A grid cell holding six sentences is the
  hardest thing in the doc to read.
