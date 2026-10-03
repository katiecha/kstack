# Claude Code launchers
# Functions, not aliases, so extra args pass through: claude-teams --model opus

# agent teams in split panes, auto permissions, machine stays awake
claude-teams() {
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 \
  CLAUDE_CODE_SUBAGENT_MODEL=sonnet \
  caffeinate -ims \
  claude --teammate-mode auto --permission-mode auto "$@"
}

# one agent, auto permissions, machine stays awake
claude-quick() {
  caffeinate -ims claude --permission-mode auto "$@"
}
