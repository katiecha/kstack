# Global preferences

Cross-cutting only. Anything true of one repo belongs in that repo's CLAUDE.md,
not here.

## Writing

- No em dashes. Use a period, a comma, a colon, or a new line. This covers skill
  text and output templates, not just prose: a skill teaches by example, so a
  template with an em dash in it produces output with em dashes in it.
  When removing one: a colon after a label or before an instruction, a comma
  mid-sentence, a colon in a heading (never a period, which reads as the title
  ending), and a comma where a colon would be the second one on the line.
- Colon form over term-then-period: "Key Terms: why the thing exists", not
  "Key Terms. Why the thing exists."
- Delete unmeasured numbers. If a figure was not measured, do not write it.
- Short paragraphs, or a list. Not a wall.

## Code review comments

Conventional Comments: `blocking` / `check` / `question` / `nit`, lowercase,
label first. Every review ends with a count roll-up listing all four labels,
including the zeros.

The full shared contract (label meanings, ordering, line-number rules, the
roll-up format) is in `~/.claude/skills/_shared/comment-format.md`. Reference it
rather than restating it: a condensed copy drifts, and the stale copy is what
gets applied.

## Rules files

Rules live in `.claude/rules/*.md` with `paths:` frontmatter, a YAML list of
globs. Not `.mdc`, and never Cursor's `globs:` or `alwaysApply:` keys, which
Claude Code ignores: the rule then either does not load at all or loads
unconditionally, and nothing reports either. A rule with no `paths:` key loads
every session, which is how an always-on rule is expressed.

```
---
paths:
  - "src/**/*.{ts,tsx}"
---
```

`~/.cursor/skills-cursor/create-rule` writes the Cursor format. A rule authored
through Cursor needs converting before it does anything here.

## Skills

Every skill needs `description:` in its frontmatter: what it does, plus when to
use it. `purpose:` is not read by the skill loader. A skill without
`description:` lists by title alone, so nothing matches a request to it and it
never fires. Keep `purpose:` as documentation if it helps, but `description:` is
what decides whether the skill is reachable.

## Scope

- Localized changes by default. Do not refactor unrelated code.
- Ask before systemic changes that affect shared patterns.
- Finish the whole task. If part of it is blocked, do the rest and say plainly
  what was left out.
