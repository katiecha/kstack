---
name: read-paper
description: Read and analyze a research paper with Keshav's three-pass method (bird's-eye, grasp content, deep understanding), with a literature-survey mode across multiple papers, producing per-pass markdown summaries. Use when the user shares a paper, PDF, or arXiv link and wants it read, summarized, analyzed, or surveyed against related work.
purpose: Read and analyze a research paper using Keshav's three-pass method (bird's-eye → grasp content → deep understanding). Also supports literature survey mode across multiple papers in a field. Each pass builds on the previous one and has a structured output contract; the deliverable is the per-pass markdown summary, not a chat-style retelling.
inputs:
  - paper: file path (PDF) OR URL (arxiv link, paper page, hosted PDF) OR pasted abstract/text
  - optional: depth, 1 (bird's-eye, ~5–10 min), 2 (grasp content, ~1 hr), or 3 (deep, ~4–5 hr). Defaults to 2.
  - optional: prior pass summary if extending an earlier read (e.g. user did pass 1, now wants pass 2)
  - survey mode: a topic / field name instead of a single paper
outputs:
  - "single-paper mode: a markdown summary per pass executed (Pass 1: Five Cs + recommendation; Pass 2: argument structure, figure table, evidence assessment, gaps, summary; Pass 3: virtual re-implementation, assumption audit, innovations, weaknesses, future work, final assessment)"
  - "survey mode: literature survey doc with key papers, key researchers, top venues, themes, open problems, recommended reading order"
  - "explicit recommendation at the end of each pass: stop here, go deeper, set aside, skip, or need background first"
success_criteria:
  - always starts at pass 1 even when a deeper pass is requested, no skipping ahead
  - fills every section of the per-pass output contract; does not silently drop sections
  - separates verified observations (read in the paper) from inference / opinion
  - cites figure / table / section numbers when discussing evidence, not vague "the paper shows..."
  - declares an explicit recommendation at the end of each pass so the user knows whether to go deeper
  - in survey mode, identifies seed papers, shared citations, and top venues before writing the synthesis, does not invent a survey from a single paper
failure_modes:
  - jumping straight to pass 3 without doing 1 and 2 first (loses the calibration that early passes provide)
  - producing a freeform chat-style summary instead of the structured per-pass output
  - confusing "what the paper claims" with "what the paper actually shows", failing to grade evidence quality in pass 2
  - hallucinating section numbers, figure references, or citations that aren't in the source
  - skipping the assumption audit in pass 3 (the highest-value section, challenging assumptions is the point of pass 3)
  - in survey mode, summarizing one paper and calling it a survey
  - stopping at pass N without an explicit "go deeper / stop here" recommendation
judge_rubric:
  - structural_adherence (every required section of the requested pass is present and non-empty)
  - evidence_grading (claims vs evidence are clearly separated; figures/tables/sections cited specifically)
  - assumption_discipline (pass 3 audits assumptions explicitly; does not let the paper's framing go unchallenged)
  - recommendation_clarity (explicit go-deeper / stop / skip / need-background verdict at the end of each pass)
  - survey_coverage (survey mode: ≥3 seed papers, key venues identified, themes synthesized, not a single-paper recap)
  - honesty (does not invent figure numbers, citations, or content not present in the source)
tools:
  - Read: for local PDFs and pasted text
  - WebFetch: for arxiv links, paper pages, and hosted PDFs
  - WebSearch: for survey mode (find seed papers, top venues, repeated authors)
  - avoid Shell / file edits: read-paper is a read-and-summarize skill, not a code or filesystem operation
---

# Read Paper

Apply Keshav's three-pass method for efficient paper reading. Each pass builds on the previous one.

## Procedure

### 1. Determine depth

If user specifies depth (1, 2, or 3), use that. Otherwise default to pass 2.

- **Pass 1**: Bird's-eye view. Use when screening papers or outside your specialty.
- **Pass 2**: Grasp content without details. Use for papers of interest but not core research.
- **Pass 3**: Full understanding. Use for papers you need to review, reproduce, or build upon.

### 2. Execute passes sequentially

Always start with pass 1, even if targeting a deeper pass.

---

## Pass 1: Bird's-Eye View (5-10 min equivalent)

Read only:
1. Title, abstract, introduction
2. Section and sub-section headings (skip body text)
3. Conclusions
4. References (note which you recognize)

### Output: The Five Cs

```markdown
## Pass 1 Summary

### Category
What type of paper is this?
- [ ] Measurement/empirical study
- [ ] Analysis of existing system
- [ ] Research prototype description
- [ ] Survey/tutorial
- [ ] Theoretical/formal methods
- [ ] Position/vision paper

**Type:** [one sentence]

### Context
- **Related papers:** [list 2-5 key related works mentioned]
- **Theoretical basis:** [frameworks, models, or prior results this builds on]
- **Research area:** [subfield and broader field]

### Correctness
- **Assumptions appear valid?** [yes/no/unclear]
- **Red flags:** [any obvious methodological concerns, or "none noted"]

### Contributions
- **Main contribution:** [one sentence]
- **Secondary contributions:** [bullet list if any]

### Clarity
- **Well written?** [yes/partially/no]
- **Structure quality:** [clear sections, logical flow, or issues noted]

---

### Recommendation
- [ ] **Read deeper**: relevant to my work, assumptions seem sound
- [ ] **Set aside**: interesting but outside current focus
- [ ] **Skip**: invalid assumptions / not relevant / poorly written
- [ ] **Need background first**: unfamiliar terminology or techniques

### References to follow up
- [list any unread references that seem important]
```

If depth = 1, stop here.

---

## Pass 2: Grasp Content (up to 1 hour equivalent)

Read with greater care, but skip proofs and dense technical details.

Focus on:
1. **Figures, diagrams, graphs**. Are axes labeled? Error bars present? Do results support claims?
2. **Key arguments**. Jot down the logical structure
3. **Evidence quality**. How strong is the support for each claim?
4. **Unread references**. Mark important ones for background reading

### Output: Content Analysis

```markdown
## Pass 2 Analysis

### Main Argument Structure
[Outline the paper's logical flow: problem → approach → evaluation → conclusions]

### Key Figures & Results
| Figure/Table | What it shows | Supports claim? | Notes |
|--------------|---------------|-----------------|-------|
| Fig 1        | ...           | Yes/Partially/No| ...   |
| Table 2      | ...           | ...             | ...   |

### Evidence Assessment
- **Strongest evidence:** [what is most convincing]
- **Weakest evidence:** [what is least convincing or missing]
- **Unstated assumptions:** [implicit assumptions in methodology]

### Technical Gaps (for me)
[List concepts, techniques, or background I'd need to fully understand this]

### Summary
[2-3 sentences: main thrust of paper with supporting evidence, suitable for explaining to someone else]

### Updated Recommendation
- **Worth a third pass?** [yes, if I need to reproduce/review/build on this; no, pass 2 sufficient]
- **Key references to read first:** [if third pass needed, what background is missing]
```

If depth = 2, stop here.

---

## Pass 3: Deep Understanding (4-5 hours equivalent for beginners)

The goal is to **virtually re-implement** the paper: make the same assumptions as the authors and mentally recreate the work.

Focus on:
1. **Challenge every assumption**. What if this assumption is wrong?
2. **Identify hidden assumptions**. What's implicit but not stated?
3. **Compare your approach**. How would you present this idea differently?
4. **Find innovations**. What's genuinely new vs. incremental?
5. **Find weaknesses**. Missing citations, flawed experiments, logical gaps
6. **Generate ideas**. What future work does this suggest?

### Output: Deep Analysis

```markdown
## Pass 3 Deep Analysis

### Virtual Re-implementation
If I were to recreate this work:
- **I would keep:** [aspects that are well-designed]
- **I would change:** [aspects I'd approach differently]
- **Key insight I gained:** [what clicked by thinking through the approach]

### Assumption Audit
| Assumption | Stated? | Valid? | Impact if wrong |
|------------|---------|--------|-----------------|
| ...        | Yes/No  | Yes/No/Unclear | High/Medium/Low |

### Innovations vs. Incremental
- **Genuinely novel:** [what's new]
- **Incremental/expected:** [what follows naturally from prior work]

### Weaknesses & Missing Elements
- **Missing citations:** [relevant work not cited]
- **Methodological issues:** [experimental or analytical problems]
- **Logical gaps:** [arguments that don't follow]
- **Threats to validity:** [internal and external]

### Proof/Technique Inventory
[Techniques used that I can add to my repertoire]

### Future Work Ideas
[Ideas for follow-on research sparked by this paper]

### Final Assessment
- **Strong points:** [bullet list]
- **Weak points:** [bullet list]
- **Overall quality:** [excellent / good / adequate / poor]
- **Reproducible?** [yes / partially / no, and why]

### One-paragraph summary
[Comprehensive summary suitable for a literature review, covering problem, approach, key results, limitations]
```

---

## Literature Survey Mode

When the user asks to survey a field (not a single paper):

1. **Find seed papers**: Use WebSearch with well-chosen keywords to find 3-5 recent papers
2. **Pass 1 each**: Get a sense of the work, read their Related Work sections
3. **Look for surveys**: If a recent survey exists, read it and you're done
4. **Find key papers**: Identify shared citations and repeated author names in bibliographies
5. **Find top venues**: Check where key researchers publish to identify top conferences
6. **Scan proceedings**: Look through recent proceedings of top venues for related work
7. **Iterate**: If all papers cite something you missed, obtain and read it

### Output: Survey Summary

```markdown
## Literature Survey: [Topic]

### Key Papers (by influence)
1. [Paper], [one-line contribution]
2. ...

### Key Researchers
- [Name]: [affiliation, focus area]

### Top Venues
- [Conference/Journal]: [why it's relevant]

### Research Themes
- **Theme 1:** [description, key papers]
- **Theme 2:** ...

### Open Problems
- [Problem 1]
- [Problem 2]

### Recommended Reading Order
1. [Start here, foundational]
2. [Then this, builds on #1]
3. ...
```