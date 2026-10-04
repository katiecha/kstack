---
name: gather-context
description: Retrieve the minimum context needed to fully resolve a task rather than just answer the surface question, including policy, process, edge cases, and prerequisites before execution begins. Use when starting a non-trivial task that needs codebase or background research first, or when a request is underspecified and the missing inputs must be found before acting.
purpose: Retrieve the minimum information required to fully resolve a task, not just answer a query. Expands retrieval around task completion, gathering policy, process, edge cases, and prerequisites before execution begins.
inputs:
  - task description (what the user is trying to accomplish)
  - task_type (inferred from the request, or supplied by the caller)
  - optional: skill being invoked (narrows retrieval targets)
outputs:
  - retrieval_plan: what needs to be looked up and why
  - retrieved_context: the gathered information, organized by relevance
  - gaps: what could not be retrieved and why
  - ready_to_proceed: yes / no
success_criteria:
  - identifies the underlying job-to-be-done, not just the surface query
  - expands retrieval to cover prerequisites, edge cases, and known failure modes
  - returns only what is needed, does not dump entire files
  - explicitly names what could not be retrieved
failure_modes:
  - retrieves information to answer the surface question but misses prerequisites for the task
  - loads entire files when only a section is needed
  - marks ready_to_proceed: yes when a required schema or code path was not found
  - retrieves the same information twice under different queries
judge_rubric:
  - task_understanding (identified the real job, not just the surface query)
  - retrieval_precision (narrow and targeted, not broad dumps)
  - prerequisite_coverage (policy, edge cases, and prerequisites included)
  - gap_honesty (unable-to-retrieve items named explicitly)
tools:
  - Read: load specific file sections (not whole files unless necessary)
  - Grep/Glob: find relevant code paths, function names, call sites
  - SemanticSearch: locate relevant logic when exact names are unknown
  - Shell: read schema docs, run grep over large directories
---

# Gather Context

Run this skill when a task needs background research before execution. Its job is to gather everything needed to fully resolve the task, not just the immediate answer.

The key question is not "what does the user ask?" but "what does the agent need to know to complete this task correctly?"

## Step 1: Identify the underlying task

Restate the user's request as a completion goal:

- Surface query: "What does `getRecordByIdDB` return?"
- Underlying task: "Review a PR that calls `getRecordByIdDB` to check whether status is validated before the result is used"

The retrieval plan should serve the underlying task, not just answer the surface query.

## Step 2: Build the retrieval plan

For the identified task, list what needs to be retrieved across four categories:

**Policy / rules**
What constraints, conventions, or known failure modes apply to this task?
- For code review: which section of the repo's knowledge doc (`AGENTS.md`, `CLAUDE.md`, `KNOWLEDGE.md`) covers the touched subsystem?
- For DB ops: which schema tables are involved? Are there soft-delete patterns to know about?
- For diagnosis: what are the known failure modes for this feature area?

**Prerequisites**
What must be true or known before the task can be completed?
- For DB queries: column names must be verified against schema before writing SQL
- For component creation: existing utilities must be checked before writing new helpers
- For PR review: subsystems must be named before any checklist section is applied

**Code paths**
What functions, controllers, or models does the task involve?
- Trace the relevant call chain for diagnosis tasks
- Find call sites when a review finding requires checking downstream impact
- Locate the canonical implementation before suggesting a fix

**Edge cases**
What are the known ways this task can go wrong?
- For form versioning: does the caller copy existing status? Does it use `latestVersion: true`?
- For task publishing: is the batch using `Promise.allSettled` over DB transactions?
- For vendor sync: are all three completion paths covered?

## Step 3: Execute retrieval

Retrieve narrowly. Rules:

- Read only the sections of a file that are relevant: do not load the full file unless the task requires understanding the entire file
- For a long knowledge doc, read only the section headers first, then load individual sections as needed
- Stop retrieving when you have enough to resolve the task: do not keep searching for more coverage
- If a search returns more than 5 results, filter to the top 3 most relevant before continuing

## Step 4: Produce the retrieval summary

```
## Retrieval summary

### Retrieval plan
[list: what was retrieved and why, one line each]

### Retrieved context
[organized by category: Policy, Prerequisites, Code paths, Edge cases]
[each item: source (file:line or schema section) + the relevant excerpt or finding]

### Gaps
[list: what could not be retrieved and why]
[or "None, sufficient context to proceed"]

### Ready to proceed
yes / no, [if no, state what is still needed]
```

## Retrieval targets by task type

| task_type | Primary retrieval targets |
|---|---|
| `code-review` | the repo's knowledge-doc section for the touched subsystem; call sites for changed functions |
| `diagnosis` | `server/controllers/` for the relevant feature; `<models-package>/` for data constraints; `<schema-docs>` for column names |
| `db-operation` | `<schema-docs>` section for relevant tables; any soft-delete or status patterns |
| `aws-operation` | Profile, region and account config for the target environment; the project's own runbook for connecting to it |
| `component-creation` | `<utils-package>/` and `client/src/utils/` for existing helpers; `<ui-package>/` for existing primitives |
| `pr-creation` | No retrieval needed, inputs come from the user |
| `log-analysis` | The log group for the failing service and the filter syntax its platform uses |
| `conversational` | Retrieve only if the question is factual and codebase-specific |
