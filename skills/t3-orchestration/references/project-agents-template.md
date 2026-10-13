# <project> - agent protocol (T3 orchestration)

Orchestrator: the manager thread. Threads: one accountable owner per disjoint file set.
Subagents: temporary, bounded, report to their parent thread only. This file is the source of truth for the roster.

## Project structure

```
<folder>/          # <purpose>            (thread-N)
<folder>/<file>    # <purpose>            (thread-N)
```

## Threads registry

| ID | Task | Owns (disjoint files) | Model | Status |
|---|---|---|---|---|
| thread-1 | <outcome> | <paths> | deepseek-v4.1-flash#high | Ready |
| thread-2 | <outcome> | <paths> | deepseek-v4.1-flash#high | Ready |

Status values: Ready | Running | Blocked | Integration-ready | Done.

## Interfaces between threads

- <shared function/format/contract>: owner thread, consumer thread, exact shape.

## Checks

- Build: `<command>`
- Test: `<command>`
- Done = owned behavior works + its exact check passed + STATUS.md row updated + one mailbox line.

## Brief format (`.t3/threads/<id>/BRIEF.md`)

```
Outcome:
Owned files:
Interfaces (in/out):
Done check (exact command):
Blockers / escalations:
```

## Rules

- Read the whole project, write only owned files. Never touch another thread's files.
- Handoffs: `.t3/MAILBOX.md`, `FROM <thread> TO <thread> RE <file>: <result> <evidence> <need>`, 6 lines max.
- Subagents: native task tool, `t3-subagent`, max 2 at a time, bounded files.
- No pushes, merges, deploys or new top-level threads without the user's OK.
- Replace STATUS.md rows; never append a diary.
