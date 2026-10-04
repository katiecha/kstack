---
name: review-conversation
description: Analyze past agent conversations to extract failures, cluster patterns, and surface actionable fixes to rules, skills, and retrieval. Use when reviewing a transcript or session history for what went wrong, auditing agent behavior, or looking for improvements to make to skills and instructions.
purpose: Analyze past agent conversations to extract failures, cluster patterns, and surface actionable improvements to rules, skills, and retrieval. Lightweight version of an Explorer loop.
inputs:
  - one or more past conversation transcripts or summaries
  - optional: a specific failure type to focus on (routing errors, overclaiming, contract violations, wrong skill invoked)
outputs:
  - failure clusters: grouped patterns of what went wrong
  - root causes: why each cluster happened
  - rule suggestions: changes to the global `CLAUDE.md` or a skill's own rules
  - skill suggestions: new skills, skill splits, or skill content gaps
  - retrieval suggestions: missing knowledge-doc sections, missing schema references
success_criteria:
  - groups failures into patterns rather than listing them individually
  - distinguishes root cause from symptom (e.g. "missing retrieval step" not just "wrong answer")
  - produces suggestions that are specific and actionable, not vague
  - does not suggest changes that would make skills longer without making them better
failure_modes:
  - lists every individual failure instead of clustering
  - suggests adding more content to already-bulky skills
  - conflates symptoms with root causes
  - produces suggestions too vague to act on ("improve grounding")
judge_rubric:
  - clustering_quality (patterns identified, not just enumerated failures)
  - root_cause_depth (why it happened, not what happened)
  - suggestion_specificity (actionable changes, not general advice)
  - scope_discipline (suggests targeted changes, not rewrites)
tools:
  - Read: load specific transcript files or summaries
  - Grep: search transcripts for specific failure patterns or keywords
  - no execution tools, this is analysis only
---

# Conversation Reviewer

This skill analyzes past conversations to find what went wrong, why, and what to change. It does not fix anything directly, it produces a prioritized improvement plan.

Use it periodically (after a set of complex tasks, after a notable failure, or when the harness feels unreliable) to close the loop between observed behavior and harness design.

## Step 1: Load and scan

Load the conversation transcripts or summaries to analyze. If given a focus area (e.g. "routing errors only"), filter to relevant interactions first.

Look for these signal types:

| Signal | What to look for |
|---|---|
| Wrong skill invoked | Agent used a broad lens when a narrower one applied; routed to freeform when a skill existed |
| Missing input not caught | Agent proceeded without a PR number, org ID, or ticket text |
| Overclaiming | Agent stated something as verified without citing evidence |
| format-check violation | Required section missing, finding not templated, sections out of order |
| Retrieval miss | Agent answered without reading the relevant schema section or knowledge-doc section |
| Fallback not triggered | Tool returned empty and agent continued as if it had results |
| Stop condition ignored | DB write or prod op proceeded without hostname verification or explicit permission |
| Wrong confidence level | Agent stated High confidence when evidence was partial or missing |

## Step 2: Cluster failures

Group individual failures into patterns. A pattern is 2+ failures that share the same root cause.

Name each cluster with a short label:
- "Routing to generic when specific skill applies"
- "Schema not consulted before DB queries"
- "Missing section in review output"

For each cluster: list the instances (by conversation ID or description) and note frequency.

## Step 3: Identify root causes

For each cluster, identify the underlying cause, not just what went wrong but why the harness allowed it.

Common root cause categories:

| Root cause | Description |
|---|---|
| `missing-signal` | The routing rule didn't cover this input pattern |
| `retrieval-not-triggered` | `retrieval_needed` was marked no when it should have been yes |
| `knowledge-gap` | The relevant knowledge-doc section doesn't exist or doesn't cover this case |
| `format-not-enforced` | The output contract exists but the agent drifted without catching it |
| `stop-condition-unclear` | The stop rule exists but wasn't specific enough to trigger reliably |
| `overclaim-unchecked` | `evidence-check` was not run when `verification_required` should have been yes |
| `skill-too-broad` | One skill is doing too much and the relevant section is too buried to apply reliably |

## Step 4: Produce the improvement plan

```
## Conversation review

### Failure clusters
[Cluster name], [N instances]
  Root cause: [root cause category], [specific explanation]
  Instances: [brief descriptions]

[repeat for each cluster]

### Suggestions

#### Rule changes
- [global CLAUDE.md / the skill's own rules]: [specific change: add, remove, or tighten a rule]
  Addresses: [cluster name]

#### Skill changes
- [skill name]: [specific change: add a section, tighten a trigger, split into two skills]
  Addresses: [cluster name]

#### Retrieval changes
- [knowledge doc or schema doc]: [specific gap to fill, missing section, missing edge case]
  Addresses: [cluster name]

### Priority order
1. [highest impact change, affects the most frequent or highest-risk cluster]
2. [second]
3. [third]
[continue]

### What not to change
[List any areas that look fine or where changes would add bulk without improving reliability]
```

## Scope discipline

Before suggesting any change, check:
- Does the change make a rule or skill more specific, or just longer?
- Is the failure pattern frequent enough to warrant a rule change, or is it a one-off?
- Would a new skill be genuinely distinct in scope, or is it a section that belongs in an existing skill?

If a suggestion would make a skill significantly longer without making it more precise, do not include it. Suggest a split instead.
