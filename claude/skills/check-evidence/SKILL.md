---
name: check-evidence
description: Inspect a draft answer and label every claim as verified, inference, or unable-to-verify, flagging overclaiming before delivery. Use when checking a draft for unsupported claims, auditing whether conclusions cite real evidence, or guarding against confident-but-unverified statements about code behavior, data state, or system configuration.
purpose: Guardrail that inspects a draft answer and labels every claim as verified, inference, or unable to verify. Flags overclaiming before the answer is delivered.
inputs:
  - draft answer (the text to inspect)
  - optional: the sources used (tool results, file reads, SQL output)
outputs:
  - annotated version of the draft with each claim labeled
  - list of overclaims to fix before delivering the answer
success_criteria:
  - every factual claim about code behavior, data state, or system configuration is labeled
  - no claim is delivered as verified without a cited source
  - low-evidence claims are either downgraded or removed
failure_modes:
  - passes a claim as verified when no source was cited
  - skips claims that are stated confidently but rest only on pattern-matching
  - lets "I checked and it looks fine" through without citing what was checked
judge_rubric:
  - label_coverage (every claim labeled, none skipped)
  - overclaim_detection (no verified label without a source)
  - actionability (output tells the author exactly what to fix)
tools:
  - no tools, evidence-check is a pass over an already-produced draft, not a codebase search
---

# Evidence Check

This skill runs on a draft answer before it is delivered. It does not produce new information, it labels what the draft already claims and flags anything unsupported.

## When to use

Run evidence-check when:
- A diagnosis or root cause is being stated (did we actually look at the code, or are we pattern-matching?)
- A review finding is being reported as blocking (is there a specific line cited, or is it inferred?)
- A DB query is being presented as correct (were column names verified against the schema?)
- Any sentence uses "it should", "it must", "it will", or "it is" about system behavior

## The three labels

Apply one of these labels to every factual claim in the draft:

| Label | Meaning |
|---|---|
| `[verified]` | A tool result, file read, SQL output, or diff hunk directly supports this claim. Cite the source. |
| `[inference]` | No direct evidence was retrieved, but the claim follows reasonably from what was found. Must state the basis. |
| `[unable to verify]` | The information needed to support this claim was not available in the context (file not in diff, query not run, schema not checked). |

## How to annotate

For each factual claim in the draft, append the label inline and the source (if verified):

```
The form status is set to Active on creation. [verified, server/controllers/forms.controller.js:142]

This would cause all submissions to fail silently. [inference, based on the submission path not validating Status before insert]

The migration script handles historical rows. [unable to verify, migration file was not included in the diff]
```

## Overclaim rules

The following patterns are overclaims: flag them for revision:

- Stating a bug exists based on a naming pattern or convention, without reading the actual code
- Stating a fix is safe without checking call sites
- Stating a backfill is unnecessary without checking whether historical rows exist
- Saying "looks correct" or "seems fine" without naming what was checked
- Using "always" or "never" about runtime behavior without a test or verified code path

For each overclaim found, produce:

```
Overclaim: "[quoted sentence]"
Problem: [why this is unsupported]
Fix: [how to restate it honestly, verified, inference, or unable to verify]
```

## Output format

```
## Evidence check

### Annotated claims
[the draft with inline labels added]

### Overclaims to fix
[list, or "None" if clean]

### Verdict
Clean, deliver as-is / Revise before delivering, [number] overclaims found
```

If the draft is clean (all claims are labeled and supportable), state "Clean, deliver as-is" and return the annotated draft.
