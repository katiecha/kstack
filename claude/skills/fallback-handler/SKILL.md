---
name: fallback-handler
description: Handle a failed or underperforming tool call, retrieval step, or skill run: classify the failure, attempt an allowed fallback, preserve the output schema, and report what changed. Use when a step fails, retrieval comes back empty, or a skill cannot complete and the run needs a graceful degradation path instead of an abort.
purpose: Define what happens when a tool call, retrieval step, or skill execution underperforms or fails. Classifies the failure, attempts an allowed fallback path, preserves the output schema, and reports what changed.
inputs:
  - failure description (what failed and at what step)
  - original task context (what was being attempted)
  - output so far (partial results, if any)
outputs:
  - failure_type: classification of what went wrong
  - fallback_action: what was attempted instead
  - output_schema_preserved: yes / no
  - confidence_after_fallback: High / Medium / Low
  - what_changed: how the fallback result differs from the ideal result
  - escalation_needed: yes / no
success_criteria:
  - correctly classifies the failure type before choosing a fallback
  - attempts a fallback that is meaningfully different from the failed approach (not the same query rephrased)
  - always preserves the output schema, even if content is partial
  - reports confidence honestly, does not present a fallback result as equivalent to the primary
failure_modes:
  - retries the exact same query and calls it a fallback
  - drops the output contract when primary execution fails
  - presents a fallback result with the same confidence as a verified primary result
  - escalates immediately without attempting any fallback
judge_rubric:
  - classification_accuracy (correct failure type identified)
  - fallback_quality (meaningfully different approach, not a rephrasing)
  - schema_preservation (output structure maintained through failure)
  - confidence_honesty (fallback confidence labeled correctly)
tools:
  - same tools as the failing step, fallback-handler does not introduce new tools, it reroutes within existing ones
---

# Fallback Handler

This skill activates when a tool call, retrieval step, or skill execution fails or returns insufficient results. Its job is to classify the failure, attempt a recovery, and report what changed, not to silently retry or silently drop results.

## Step 1: Classify the failure

Identify which failure type occurred:

| failure_type | Description | Example |
|---|---|---|
| `tool-empty` | Tool returned no results | Grep found nothing; Glob matched no files |
| `tool-error` | Tool returned an error | Shell command failed; file not found |
| `retrieval-insufficient` | Results were found but not enough to resolve the task | Schema section found but column names still ambiguous |
| `retrieval-stale` | Retrieved content exists but is outdated or contradicts known state | <schema-docs> references a column that doesn't exist |
| `model-overconfident` | The draft output made claims not supported by retrieved evidence | evidence-check flagged overclaims |
| `contract-violation` | The draft output failed format-check | Missing required section; finding not templated |
| `input-missing` | A required input was not provided | PR number, org ID, or ticket text absent |
| `stop-condition` | A skill's hard stop was triggered | Hostname not verified; write without permission |

## Step 2: Choose the fallback path

Apply the allowed fallback for the failure type. Do not attempt a fallback that is not listed, escalate instead.

| failure_type | Allowed fallback |
|---|---|
| `tool-empty` | Retry with a broader or rephrased query. If still empty: name the gap and continue with what is available. |
| `tool-error` | Retry once. If still failing: name the error, mark the step as `[unable to verify]`, continue. |
| `retrieval-insufficient` | Expand retrieval: try a related file, a parent directory, or a semantic search variant. Limit: 2 additional attempts. |
| `retrieval-stale` | Prefer the live codebase over cached/doc content. Re-read the relevant source file directly. |
| `model-overconfident` | Hand off to `evidence-check`. It will label and fix unsupported claims. Redeliver the corrected output. |
| `contract-violation` | Run `format-check`. Fix identified violations. Redeliver. |
| `input-missing` | Stop. Ask for the specific missing input. Do not attempt the task with a placeholder. |
| `stop-condition` | Stop. Do not attempt any fallback. State the condition and what is needed to proceed. |

## Step 3: Preserve the output schema

Even when a fallback is partial, the output must maintain the contract structure of the original skill. Partial sections must be labeled, not omitted:

```
[Section name]: I could not complete this section, [reason]. Fallback attempted: [what was tried].
```

Do not drop sections because content is unavailable. Drop content, not structure.

## Step 4: Report what changed

After the fallback, produce this block:

```
## Fallback report

failure_type:             [type]
fallback_action:          [what was attempted]
output_schema_preserved:  yes / no
confidence_after_fallback: High / Medium / Low
what_changed:             [how the fallback result differs from the ideal, be specific]
escalation_needed:        yes / no
```

### Confidence rules after fallback

- Primary path succeeded → confidence from the skill's own rubric
- `tool-empty` or `tool-error` fallback succeeded → drop one level (High → Medium, Medium → Low)
- `retrieval-insufficient` fallback succeeded → Medium at best
- Any fallback failed → Low; escalation_needed: yes

### When to escalate

Set `escalation_needed: yes` when:
- The fallback also failed and the task cannot be completed with available information
- A `stop-condition` was triggered (no fallback is allowed)
- Two retrieval attempts returned insufficient results and the task requires that information to be safe to complete
- The user needs to take an action (provide input, run a command, verify something manually) before the task can continue

When escalating, state exactly what the user needs to do or provide.
