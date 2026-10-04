# Review and notion

Extracted from `create-design-doc/SKILL.md`. handling review feedback, and the Notion-specific editing mechanics.

## Acting on someone else's review

Reviews arrive as numbered lists of confident findings. Treat the list as leads, not as a work order.

- **Verify every finding against the live doc before fixing anything.** Reviews are written against a
  snapshot, and on an actively edited doc a real fraction are already fixed. Across four reviews in
  one session, roughly one finding in six was stale. Fixing a stale finding means re-introducing text
  or, worse, editing something that no longer exists and silently no-opping.
- **Separate writing fixes from design gaps.** A consistency review will mix "these two sentences
  contradict" with "this mechanism is never specified". The first you fix. The second becomes an Open
  Question, because inventing a retry policy or a threshold to close a review item hides a real hole
  behind plausible prose.
- **Say when a finding conflicts with a decision the user already made.** A reviewer who was not in
  the room will suggest cutting the section the user asked for last night. Flag the conflict and let
  them rule, rather than quietly applying it or quietly ignoring it.
- **Discount an argument of the form "the other docs do not do this and nobody objected."** That is
  evidence about those docs, not about whether the practice is good. See the evidence rule on
  checking authorship.
- **Group unverifiable external claims into one Open Question** rather than caveating each in place.
  List them together, say what each one is load-bearing for, and name what would settle them.

## Editing in Notion

Read `notion://docs/enhanced-markdown-spec` before editing, and prefer `update-page` with
`update_content` over `replace_content`.

**Toggle heading syntax**: `## Title {toggle="true"}` with every child block indented one tab.

Four mechanics that fail quietly:

- **Reproduce `discussion-urls` spans verbatim.** Indenting a block recreates it and changes its
  block id, but comments survive as long as the span markup is copied exactly. Comments are *not*
  lost by this operation, despite what the block-id change suggests.
- **Re-check numbered lists afterwards.** A numbered list split across a toggle boundary silently
  renumbers from 1, with no error. Indent every item of a list in the same pass, then verify the
  numbering end to end.
- **A code block or paragraph between list items restarts the numbering**, so steps render 1, 2, 1.
  Editing the literal number does not help, since Notion renumbers again. Indent the interrupting
  block one extra tab so it nests as a child of its step, and the sequence survives. A paragraph
  deliberately splitting one list into two sequences is fine, but check it reads as two.
- **Assert the leading tab after every prose replacement.** Dropping one tab from a `new_str` silently
  un-indents the block, which terminates the toggle and orphans everything after it. Nothing looks
  wrong until the section is collapsed, so grep for un-indented lines inside each section after a
  batch.
- **Only the opening `<table>` or code fence needs indenting.** Notion re-indents the closing tag
  itself.
- **Any un-indented block terminates the toggle's children**, including an `<empty-block/>` spacer,
  and orphans everything after it.

**Anchors must be unique, and must cover whole blocks.** `update_content` fails on multiple matches,
so grow the anchor until it is unique, and anchor headings with surrounding newlines since `### Ingestion`
also matches inside `#### Ingestion change-detection feeds`. An anchor that starts or ends mid-table is
not addressable: three attempts whose `old_str` ended on an opening `<tr>` all returned success and
changed nothing. Spanning a section divider is fine, as long as every block is whole.

**A no-op reports success.** The tool does not tell you an anchor missed, so a batch can silently
apply two of three edits. Always re-fetch and assert the change landed, and check for the failure that
matters most: if a delete misses while its paired insert succeeds, the section now exists twice.
Sequence a move as delete first, then insert, so a miss loses nothing recoverable.

**Generate large edit sets mechanically.** For a section-wide reindent, script the old and new
strings from the live document rather than transcribing them, then apply in batches under 100.

**Verify after every batch**: re-fetch and diff against the previous snapshot with indentation and
toggle markers normalized away. The expected diff is empty except for intended changes. This is also
how you catch concurrent-edit corruption, which shows up as characters dropped mid-word.

**Concurrent editing collides.** If the user is typing in the UI while you write through the API,
text can be mangled mid-word. Ask them to stay out of the page during a large operation, and keep
snapshots so any damage can be diffed and repaired.

**For a single section, the UI is one click.** "Turn into toggle heading" moves all children as a
unit and cannot split a list. Offer it when the API path would take more than a handful of edits.
