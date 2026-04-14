# `.kyoh86-context` Rules

`.kyoh86-context/` is a repo-local, untracked buffer for cross-agent handoff.
It is not a notebook, archive, or long-term memory store.

## Files

- `.kyoh86-context/task.md`
  Current task only. Replace when task changes.
- `.kyoh86-context/state.json`
  Machine-readable current state only.
- `.kyoh86-context/handoff.md`
  Latest handoff only. No history.
- `.kyoh86-context/artifacts/`
  Temporary evidence. Delete when no longer needed.

## Handoff Style

Use caveman-style compression.

- No greeting.
- No apology.
- No self-evaluation.
- No timeline narrative.
- One fact per line.
- Keep file paths, commands, identifiers, and error strings verbatim.
- Separate facts from guesses.
- Write exactly one next action.

## Handoff Template

```md
# Goal
one line

# Done
fact

# Facts
fact

# Suspects
guess

# Next
one concrete action
```

## Limits

- Each section: at most 3 lines.
- If `handoff.md` exceeds 20 lines, compress it.
- `state.json` should contain only current status, touched files, and next action.
- Finished task artifacts should be deleted.

## Example `state.json`

```json
{
  "status": "in_progress",
  "files": ["nvim/lua/kyoh86/conf/claude.lua"],
  "next_action": "verify terminal command path",
  "updated_at": "2026-04-14T12:00:00+09:00"
}
```
