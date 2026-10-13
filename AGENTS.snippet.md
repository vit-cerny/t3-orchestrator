## T3 Code (global, opencode harness)

When T3 orchestration tools are present (`t3_thread_launch`, `delegate_task`, `t3_thread_send`): load the `t3-orchestration` skill and follow it. Summary:
- Orchestrator (you, agent `t3-orchestrator`, xhigh): plans, writes the project AGENTS.md (structure + threads registry) and `.t3` records, dispatches with `t3_thread_launch`, oversees via completions/`t3_thread_wait`, integrates. Never implements features.
- Threads (agent `t3-thread`, high): full-project read, disjoint owned writes, max 2 temporary subagents (native task tool, `t3-subagent`), talk via `.t3/MAILBOX.md` (`FROM a TO b RE file: result evidence need`, 6 lines max).
- T3 threads are top-level conversations; each one is an opencode session with the full global config (skills, plugins, MCPs, auth).
- Token saving: brief = owned files + interfaces + Done check; STATUS.md replaces rows, no diary; reuse threads; no threads beyond the planned roster without asking.
- Small requests: answer or fix directly, spawn nothing.
