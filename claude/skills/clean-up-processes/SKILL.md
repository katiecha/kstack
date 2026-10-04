---
name: clean-up-processes
description: Diagnose and fix macOS process exhaustion caused by Cursor agent sessions leaking orphaned shell processes. Use when the user sees "fork failed: resource temporarily unavailable", "EAGAIN", "spawn ps EAGAIN", git pull failing, or dev server crashing with process errors.
---

# Clean Up Leaked Processes

Cursor agent sessions can leak orphaned zsh/utility processes over time. When the user process count approaches the macOS limit (~4,000), commands start failing with fork/EAGAIN errors.

## Diagnose

Check current process count:
```bash
ps aux | grep $USER | wc -l
```

If above ~3,000, cleanup is needed. To see what's consuming slots:
```bash
ps aux | awk '{print $1}' | sort | uniq -c | sort -rn | head -5
```

Typical culprits: thousands of `/bin/zsh`, `tail`, `printf`, `head`, `sed` processes owned by the user.

## Fix

Kill orphaned zsh and utility processes:
```bash
ps aux | grep $USER | grep '/bin/zsh' | awk '{print $2}' | head -1000 | xargs kill -9 2>/dev/null
```

Run 2–3 times until count drops below ~1,500. Then retry the failing command.

**Alternative**: Fully quit and reopen Cursor (Cmd+Q): clears all leaked processes at once.

## Notes

- macOS hard limit is 4,000 processes per user; cannot be raised past this in a session
- The kill command is safe, it only targets orphaned background shells, not active terminals
- After cleanup, also check for expired AWS tokens if the dev server was crashing with `ExpiredTokenException`: run `aws sso login` to refresh
- Monitor periodically during heavy agent use; restart Cursor once a day if running many agent sessions
