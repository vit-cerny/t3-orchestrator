---
name: T3 orchestration
description: Global T3 Code workflow for the opencode harness. Use when t3-code orchestration tools are available (t3_thread_launch, delegate_task, t3_thread_send) and the request is project-scale - a new app, a feature spanning files, "make me X", a refactor. Plan, write the project AGENTS.md threads registry, launch opencode threads, oversee, integrate. Skip for small single-turn requests.
---

# T3 orchestration (opencode harness)

T3 is the master manager. Every thread is its own opencode session that loads the full global config (skills, plugins, MCPs, AGENTS.md, auth). Threads are top-level T3 conversations; subagents are temporary native opencode children.

## 0. Triage (always first)

- Small: a question, one file, one command -> answer or do it directly. No threads, no `.t3` files.
- Project-scale: new project, multi-file feature, "build me X", multi-subsystem refactor -> orchestrate.
- When the scale is genuinely unclear, ask the user once (question tool), then commit.

## 1. Plan (orchestrator thread)

- Recon: one or two native `explore` subagents (structure, stack, tests, existing AGENTS.md). Never read the whole tree inline.
- Slice into 2-6 threads. One accountable owner per disjoint file set. No two threads touch the same file.
- Ask the user before exceeding that roster later.
- Write into the target project root:
  - `AGENTS.md` - project structure + threads registry + interfaces + checks (template: references/project-agents-template.md)
  - `.t3/STATUS.md` - the current page (rows: outcome, owner, blocker, next check)
  - `.t3/threads/<id>/BRIEF.md` - one brief per thread: outcome, owned files, interfaces, done check, blockers
  - `.t3/MAILBOX.md` - header plus the line format

## 2. Dispatch

One `t3_thread_launch` call per registry row, then end the turn (completions wake you):

```
t3_thread_launch({
  title: "thread-1: core loop",
  workspaceStrategy: { type: "root" },
  interactionMode: "default",
  runtimeMode: "inherit",
  modelSelection: {
    instanceId: "opencode",
    model: "opencode-go/deepseek-v4.1-flash",
    options: [ { id: "variant", value: "high" } ]
  },
  message: "Read AGENTS.md, .t3/STATUS.md and .t3/threads/thread-1/BRIEF.md. Implement your owned files only. Report Done in .t3/MAILBOX.md and update your STATUS.md row."
})
```

- Batch with `create_threads` only when the user asks for a batch.
- Use a worktree (`workspaceStrategy: {type:"worktree", baseRef, branch}`) only for independent/parallel implementation the user asked for.
- Subagents inside a thread use the native task tool with `t3-subagent`; bounded files; max 2 at a time.

## 3. Oversee

- Async completions and thread updates wake this thread. Do not poll.
- `t3_thread_wait(threadId, timeoutMs)` only when you must block on one thread; `t3_thread_read(threadId, view:"messages", limit: 10)` to inspect a stuck thread; `t3_thread_list` for a roster sweep.
- Steer with `t3_thread_send(threadId, message, mode:"queue")`. Keep messages terse: file, result, evidence, need.
- Read `.t3/MAILBOX.md` for handoffs. Update `.t3/STATUS.md` rows; replace, never append.

## 4. Integrate and close

- Run the project check on the exact integrated source (build/test command from the registry).
- Return product defects to the owning thread; resolve interface conflicts yourself.
- Close with: outcome, evidence (exact commands), remaining gates. Never declare Done while a required check is skipped or unrun.

## Model map

Live catalog: `orchestrator_capabilities` (use it when a model id is in doubt).

| Role | Model | Variant |
|---|---|---|
| Orchestrator (this thread) | opencode-go/muse-spark-1.3-contributor | xhigh |
| Thread lead | opencode-go/deepseek-v4.1-flash | high |
| Subagent (mechanical) | opencode-go/deepseek-v4.1-flash | low |
| Verification when risk is high | opencode-go/muse-spark-1.3-contributor | high, state why |

- T3 payloads: `options: [ { id: "variant", value: "<variant>" } ]`.
- opencode agent files: `model: provider/model#variant`.

## Token rules

- Brief = outcome, owned files, interfaces, done check. Never paste history, logs or whole files.
- Mailbox line: 6 max. STATUS.md: replace rows. Child report: files, check, result, blocker.
- One thread per file set; reuse threads for follow-up work; no thread-count targets.
- If a call fails with balance/rate errors: fall back inline once, note it, stop retrying.

## Guards

- Never create threads outside the planned roster without the user's OK.
- No secrets in records. No push, merge or deploy unless the user authorized it.
- If the t3 tools are absent you are not inside T3: use plain native subagents and skip `.t3` records.
