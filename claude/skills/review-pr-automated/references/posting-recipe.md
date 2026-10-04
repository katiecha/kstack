# Posting recipe

Extracted from `review-pr-automated/SKILL.md`. the gh api calls that post inline review comments and set the review event.

## Posting recipe (gh api)

1. Head SHA: `gh pr view {N} --repo {owner/repo} --json headRefOid -q .headRefOid`.
2. Write the review payload to a temp JSON file (a heredoc/`echo` will mangle quotes: write the file). **Default shape: omit `event` so the review is created as PENDING (a draft only Katie can see).** Pre-fill the `body` with the friendly summary and the recommended verdict so she just has to confirm:

```json
{
  "commit_id": "<head sha>",
  "body": "lgtm! nice fix.\n\nleft a few questions and a small test nit, nothing blocking. happy to approve once those are addressed.\n\n(drafted by review-pr-automated, edit/submit when ready)",
  "comments": [
    { "path": "path/to/file.ts", "line": 93, "side": "RIGHT", "body": "question: <observation>.\n\n<the actual question>?" },
    { "path": "path/to/file.ts", "line": 63, "side": "RIGHT", "body": "check: <observation>.\n\n<the concrete ask>." }
  ]
}
```

   To submit outright instead (only when the user asked), add the event: `"event": "APPROVE"` (or `"COMMENT"` / `"REQUEST_CHANGES"`).

3. Create the review:

```bash
gh api repos/{owner}/{repo}/pulls/{N}/reviews --method POST --input /tmp/pr-{N}-review.json \
  --jq '{id: .id, state: .state, url: .html_url}'
```

   With no `event`, `state` comes back `PENDING`. Give Katie the review URL, she can edit/delete/add comments inline in GitHub and then submit with her chosen verdict.

4. (Optional) If she later tells you to submit the pending review programmatically, use its `id`:

```bash
gh api repos/{owner}/{repo}/pulls/{N}/reviews/{review_id}/events --method POST \
  -f event=APPROVE -f body="lgtm!"
```

Notes:
- `line` is the line number in the file on the PR branch and must be inside a diff hunk; a 422 almost always means the line isn't part of the diff, move it to a hunk line or into `body`.
- For a multi-line range use `start_line` + `line` (both must be in the same hunk) with `start_side`/`side`.
- Default to PENDING so the comments stay editable in GitHub before they're public. Only attach an `event` (submit immediately) when the user explicitly asks.
- Never auto-`APPROVE` over a hard blocker, if asked to submit anyway, downgrade to `COMMENT` (or `REQUEST_CHANGES` if the user wants blocking) and say why in the body.
