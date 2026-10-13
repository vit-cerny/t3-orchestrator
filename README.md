# t3-orchestrator

Turn [T3 Code](https://github.com/pingdotgg/t3code) into a project orchestrator: you write one prompt,
the manager thread plans it, splits it into disjoint workstreams, launches one T3 thread per workstream,
oversees them, and integrates the result. No fork of T3. Config + agents + one skill.

Works with the **opencode** harness (`opencode` provider instance in T3).

## How T3 actually works

T3 Code is an "agent harness control surface". It does **not** call model APIs itself. It drives agent
CLIs already installed on your machine (Codex, Claude Code, Cursor, Grok Build, OpenCode, Antigravity,
plus anything from the ACP Registry).

- A **thread** in T3 is a top-level conversation bound to a provider instance, a project, and a
  workspace. Under the hood each `opencode` thread is a full `opencode` session: global config,
  skills, plugins, MCP servers, and auth all apply.
- T3 injects its own MCP endpoint into every provider session (`http://127.0.0.1:<port>/mcp`, server
  key `t3-code`). That is where the orchestration tools come from: `t3_thread_launch`,
  `t3_thread_send`, `t3_thread_read`, `t3_thread_wait`, `t3_thread_list`, `delegate_task`, and
  friends.
- Delegated work always creates an app-owned **child thread**. The child receives only the task
  prompt you send, plus an optional role instruction. Parent conversation history is **not** copied.
- Async completions and thread updates are delivered to the parent, so the manager does not poll.

So: agents do not free-chat with each other. It is a hierarchy with a shared ledger. The manager
delegates, threads report back, the manager integrates. See
`docs/orchestration-v2/orchestrator-mcp-server.md` upstream.

## The three roles

| Role | Agent | Mode | Job |
|---|---|---|---|
| Manager | `t3-orchestrator` | primary | Plan, slice, write records, dispatch, oversee, integrate. Never implements. |
| Owner | `t3-thread` | primary | Owns a disjoint file set. Full-project read, owned writes only. Up to 2 helpers. |
| Helper | `t3-subagent` | subagent | Mechanical slices. Bounded files, no children, reports files + check. |

Threads talk through files in the project, not through chat:

- `AGENTS.md` - project structure, threads registry, interfaces, checks (template in the skill).
- `.t3/threads/<id>/BRIEF.md` - one brief per thread: outcome, owned files, interfaces, done check.
- `.t3/STATUS.md` - the current page. Rows are replaced, never appended.
- `.t3/MAILBOX.md` - handoffs, one line each, 6 lines max:
  `FROM <thread> TO <thread> RE <file>: <result> <evidence> <need>`

## Install

```powershell
git clone https://github.com/vit-cerny/t3-orchestrator
cd t3-orchestrator
powershell -ExecutionPolicy Bypass -File install.ps1
```

macOS / Linux:

```sh
sh install.sh
```

The installer copies `agents/*.md` and `skills/t3-orchestration/` into your opencode config dir
(`~/.config/opencode` by default, override with `-ConfigDir` / `$OPENCODE_CONFIG_DIR`), backs up any
file it replaces, and appends the T3 section to `AGENTS.md` once (idempotent, marker-based).
Use `-DryRun` to see what it would do.

Then:

1. Restart opencode (config is not hot-reloaded).
2. In T3: **Settings -> Providers**, make sure the `opencode` instance is enabled and authenticated.
3. In T3, pick the `t3-orchestrator` agent for your conversation and describe the project.

Verification (both installers run this and print PASS/FAIL):

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -DryRun
```

## Use

Give the manager thread a project-scale prompt ("build X", "add feature Y across the app", "refactor
Z"). It will:

1. Recon with read-only subagents, slice the work, and write `AGENTS.md` + `.t3/` records.
2. Call `t3_thread_launch` once per registry row, then end its turn.
3. Wake on completions, steer stuck threads with `t3_thread_send`, read `.t3/MAILBOX.md`.
4. Run the project check on the integrated source and report outcome + evidence.

Small requests (one file, one question, one command) are answered directly. No threads are spawned
and no `.t3` files are written.

## Providers and auth

T3 "providers" are agent harnesses, not model APIs. Adding harnesses, browser sign-in, and getting
more model providers (including the ~60 providers opencode supports with browser OAuth) are covered
in [docs/providers.md](docs/providers.md).

## Known caveats

- **Agent mode duplication.** If your `opencode.jsonc` also defines `t3-orchestrator` / `t3-thread` /
  `t3-subagent` under `agent`, it can conflict with these markdown files. `t3-thread` must be
  `primary` (T3 threads are top-level conversations), so a config block that marks it `subagent`
  breaks the design. Pick one source of truth.
- **Model map.** The skill ships a model map for the `opencode-go` catalog
  (`muse-spark-1.3-contributor` for the manager, `deepseek-v4.1-flash` for threads). Edit it if your
  catalog differs.
- **No secrets, no pushes.** `.t3` records are plain text. The skill forbids push / merge / deploy
  unless you authorize it.

## Credits

Upstream: [pingdotgg/t3code](https://github.com/pingdotgg/t3code) (MIT). This repo contains only
configuration and prompts. It is not affiliated with T3 Code or Ping.

MIT - see [LICENSE](LICENSE).
