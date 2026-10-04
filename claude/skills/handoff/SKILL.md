---
name: handoff
description: Compact the current conversation into a handoff document so a fresh agent or session can continue the work without re-reading the chat history. Use when the user asks for a handoff, a context dump, or a summary to pick up later, or is about to clear or restart the session.
purpose: Compact the current conversation into a handoff document so a fresh agent can continue the work without re-reading the full chat history.
inputs:
  - current conversation (implicitly available)
  - optional argument: description of what the next session will focus on
outputs:
  - markdown handoff doc with a chat-name-prefixed filename saved to the OS temp directory (not the workspace)
  - sections (in order, omit any that don't apply): Header, Context, What this chat covered, Key files / areas, Work completed, Work in progress, Commands / verification, Manual steps / checklists, Known issues / quirks, Suggested next steps, Suggested skills, Reference state, Copy-paste prompt for next agent, Redaction notes
success_criteria:
  - saved to OS temp dir (e.g. /tmp/ on macOS/Linux), not inside the workspace
  - filename and H1 both lead with the derived chat-name (lowercase, plain-English, no ticket/PR prefixes)
  - does not duplicate content captured in other artifacts, references them by path or URL instead
  - includes a "suggested skills" section that lists skills the next agent should invoke
  - redacts sensitive information (API keys, passwords, PII)
  - if the user provided an argument, the doc is tailored to the described next-session focus
failure_modes:
  - saving the doc to the workspace instead of the OS temp directory
  - using a generic filename (`handoff.md`, `summary.md`) or omitting the chat-name prefix
  - using ticket/PR/project IDs (e.g. `SUPPORT-1234`, `TICKET-5678`) as the chat-name prefix instead of a plain-English phrase
  - title-casing the chat-name or letting filename and H1 disagree
  - duplicating content that already exists in plans, PRDs, commits, or issues
  - omitting the suggested skills section
  - leaving sensitive values (tokens, passwords, env var values) in the document
  - writing a vague summary that forces the next agent to re-read the full conversation
judge_rubric:
  - save_location (OS temp dir, not workspace)
  - filename_format (chat-name-prefixed, lowercase, no ID prefixes; H1 matches filename verbatim)
  - artifact_references (paths or URLs used instead of inline duplication)
  - skills_section (suggested skills present and relevant)
  - redaction (no sensitive values appear in the doc)
  - focus_tailoring (if argument provided, doc is scoped to the next-session goal)
tools:
  - Write: save the handoff doc to the OS temp directory
  - Read/Glob: locate referenced artifacts (plans, research docs, PRDs) to produce correct paths
  - avoid Shell: no need to run commands; this is a static summarization pass
---

# Conversation handoff

Compact the current conversation into a self-contained handoff document a fresh agent can read as its first action, without access to the chat history.

## Why this skill exists

Long sessions accumulate context that is expensive to re-derive. A handoff doc transfers only the minimum necessary state, what was done, what is in flight, what to do next, so the next session starts at the right point rather than from scratch.

## Step 1: Determine the next-session focus

If the user passed an argument (e.g. "focus on implementing phase 2"), treat it as the primary lens for the doc. Highlight information relevant to that goal; move unrelated context to a brief "Background" section or omit it.

If no argument was provided, write a balanced summary covering all significant threads.

## Step 2: Identify existing artifacts

Before writing, check for artifacts that already capture context:

- Markdown plan docs under `thoughts/shared/plans/`
- Research docs under `thoughts/shared/research/`
- Open PRs (note the URL)
- Issue-tracker / support tickets referenced in the session
- Committed code (note the branch or commit SHA)

Reference these by path or URL in the doc instead of duplicating their content.

## Step 3: Redact sensitive information

Scan the session for:
- API keys, tokens, bearer credentials
- Database passwords or connection strings
- PII (email addresses, names tied to personal data)

Replace with `[REDACTED]`. Note any redactions in a "Redaction notes" section at the bottom of the doc.

## Step 4: Derive a chat name

A short **lowercase**, plain-English phrase that names the topic the way the user would casually describe it in conversation. Aim for 2–5 words.

**Rules (all required):**

- **Lowercase only**: including acronyms (`api`, `sdk`, `gui`).
- **No ticket or ID prefixes** (no `SUPPORT-1234`, no `TICKET-5678`, no `PR-1234`, no `#1234`). Tickets and PR links belong in the document body, not in the title.
- **Plain-English casual phrasing**, not a formal description. Mimic the way the user would say it out loud.
- **Spaces allowed** (filename keeps the spaces).
- **No leading articles** (`the`, `a`, `an`).

**Good:**

- `calendar sync issues`
- `recurrence column gui`
- `<analytics-vendor> metrics audit`
- `date picker frontend`

**Bad:**

- `SUPPORT-1234 calendar swap investigation`: has ticket prefix; not lowercase; too formal
- `TICKET-5678 recurrence column`: has ticket prefix; not lowercase
- `PR 5263`. ID-only, not descriptive
- `Chat summary`: generic
- `Cal Swap Admin Tool Data Sources`: title-cased
- `The calendar issues`: has leading article

**Source of the phrase:**

1. If the user supplied a chat name in their message, use it **exactly as written** (preserving their casing and wording, even if it violates the rules above, the user's intent wins).
2. Otherwise, infer a 2–5-word lowercase phrase from the main topic. Strip any ticket numbers, project codes, or product prefixes from the inferred phrase even if they dominated the conversation.

## Step 5: Write the handoff doc

Save to the OS temp directory (`/tmp/` on macOS/Linux, `%TEMP%` on Windows). **Do not save inside the workspace.** Use a chat-name-prefixed, timestamped filename:

```
{chat-name}-handoff-{YYYY-MM-DD-HHMMSS}.md
```

- `{chat-name}`: the phrase derived in Step 4; spaces preserved verbatim.
- Timestamp: run `date +"%Y-%m-%d-%H%M%S"` at write time (local time).

**Example:** `/tmp/calendar sync issues-handoff-2026-06-17-110417.md`

At the end of the chat response, tell the user the full path to the file.

## Output contract

The H1 must match the filename's chat-name verbatim (same casing, same spacing): do not re-format it. Include only sections that apply; omit empty ones rather than padding.

```markdown
# {chat-name}: Handoff

**Created:** {YYYY-MM-DD HH:MM:SS}
**Chat scope:** {one-line description of what this chat was about}
**Session focus (next):** {argument provided by user, or "general continuation"}
**Branch:** `{branch}` (if applicable)
**Issue tracker / ticket:** {link or ID} (if applicable)
**PR:** {link} (if applicable)

---

## Context

{Background a new agent needs, problem, ticket, why this work exists.}

---

## What this chat covered

{Bulleted list of what was discussed, decided, or produced in this chat. Note if no code changed, or list files changed.}

---

## Key files / areas

| Area | Path |
|------|------|
| ... | ... |

---

## Work completed

- {bullet per completed item; reference commit SHA, PR URL, or artifact path where applicable}

---

## Work in progress

- {bullet per in-flight item; include exact file paths and what remains}

---

## Commands / verification

{Exact commands to run tests, reproduce, or verify. Omit if N/A.}

---

## Manual steps / checklists

{Unchecked items still outstanding. Use subsections A/B/C when helpful.}

---

## Known issues / quirks

{Non-obvious bugs, misleading UI, workarounds. Include code citations when useful.}

---

## Suggested next steps

1. {concrete action the next agent should take first}
2. {next action}
...

---

## Suggested skills

- `{skill-name}`: {one-line reason this skill is relevant to the next session}
...

---

## Reference state

- **PR / branch / CI:** ...
- **Tickets:** ...
- **Other links:** ...

---

## Copy-paste prompt for next agent

\`\`\`
{Short opening prompt the user can paste into a fresh chat. Include handoff file path.}
\`\`\`

---

## Redaction notes

{List anything that was redacted and why, or "None."}
```

## Content rules

- **Actionable**: the next agent should know what to do first without re-deriving context.
- **Concrete**: exact paths, org IDs, commands, PR URLs; not vague "run tests".
- **Honest**: distinguish done vs open; note sandbox/CI failures vs untested work.
- **No blame**: describe outcomes, not who did what wrong.
- **Copy-paste block**: always end with a ready-to-use prompt referencing the handoff file path.
- **Include only sections that apply**: omit empty ones rather than padding.

## What this skill does NOT do

- Save files inside the workspace: always use the OS temp directory.
- Use a generic filename (`handoff.md`, `summary.md`) or omit the chat-name prefix.
- Use ticket numbers, PR numbers, project codes, or any other ID as a prefix in the chat-name (e.g. `SUPPORT-1234`, `TICKET-5678`, `PR-1234`). IDs belong in the body, not the title.
- Title-case or re-capitalize the chat-name unless the user explicitly supplied that casing.
- Let the filename and H1 disagree, they must use the chat-name identically.
- Re-derive context that already exists in plans, research docs, or commits, reference them.
- Make code changes, this is a summarization pass only.
