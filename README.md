# kstack

My zsh setup for coding: git aliases and two Claude Code launchers.

## Install

Clone it, then source what you want from `~/.zshrc`:

```zsh
source ~/Documents/kstack/zsh/aliases.zsh
source ~/Documents/kstack/zsh/claude-code.zsh
```

Open a new tab, or run `source ~/.zshrc`.

## `zsh/aliases.zsh`

`c` to clear, plus the git shorthands I type most: `ga`, `gaa`, `gc`, `gp`, `gl`, `gs`.

## `zsh/claude-code.zsh`

Two ways to start Claude Code. Both are functions rather than aliases, so extra
flags pass through: `claude-teams --model opus`.

`claude-quick`: one agent, auto permissions. The everyday one.

`claude-teams`: same, plus [agent teams](https://code.claude.com/docs/en/agent-teams).
Teammates run as separate sessions with their own context windows, which is worth
it for parallel review or research and wasteful for anything sequential.

What each piece does:

- `--permission-mode auto`: a classifier reviews each tool call instead of
  prompting you. It is the built-in default from Claude Code v2.1.283, so the flag
  mostly matters on older versions. It reduces prompts, it does not guarantee
  safety. Turn on the [Bash sandbox](https://code.claude.com/docs/en/sandboxing)
  with `/sandbox` for actual containment: it is a separate system, not part of auto mode.
- `--teammate-mode auto`: split panes when you are already in tmux or iTerm2 with
  `it2`, otherwise in-process. Forcing `tmux` breaks in VS Code's terminal,
  Windows Terminal, and Ghostty.
- `CLAUDE_CODE_SUBAGENT_MODEL=sonnet`: teammates otherwise inherit the lead's
  model, so a team of Opus agents gets expensive fast.
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`: scoped to this function on purpose.
  Set globally, any subagent Claude names becomes a full teammate, so teams form
  when you did not ask for one.
- `caffeinate -ims`: keeps the machine awake while a long run finishes. No `-d`,
  so the display still sleeps and your screen still locks.

## `claude/`

My global Claude Code setup: `CLAUDE.md`, skills, subagents and
`settings.json`. Symlink or copy what you want into `~/.claude/`:

```zsh
ln -s ~/Documents/kstack/claude/skills/create-design-doc ~/.claude/skills/create-design-doc
```

`CLAUDE.md` is cross-cutting preferences only: writing rules, the Conventional
Comments contract for review output, where rules files live, and what a skill
needs in frontmatter to be reachable at all.

`skills/` splits into three groups. Writing and thinking: `create-design-doc`,
`create-notes`, `dive-deep`, `read-paper`, `handoff`, `gather-context`. PR
review lenses: `review-pr-quick` for binary house rules, then `review-pr-solid`,
`review-pr-leetcode` and `review-pr-ai` for the deeper passes, with
`review-pr-automated` routing them and posting the result as a draft review.
Guardrails: `check-evidence` labels every claim in a draft as verified or not,
`check-format` verifies a skill's output against its own contract, and
`fallback-handler` covers what to do when a step fails.

`agents/` holds one runner per review lens, so each lens reads its own skill in
its own context and returns only findings.

Hooks are not here yet. The two I run, a formatter that picks up whichever
formatter the edited file's own project has, and a once-per-session reflection
pass, are shell scripts and land in a later pass. `settings.json` here carries
no `hooks` block for that reason.

Names in the review skills are angle-bracket placeholders.
`claude/PORTING.md` has the substitution table.
