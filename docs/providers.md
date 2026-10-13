# Providers in T3 Code

## The category rule

T3 and opencode mean different things by "provider".

- In **opencode**, a provider is a **model API**: Anthropic, OpenAI, xAI, DeepSeek, OpenRouter, NVIDIA,
  Vercel AI Gateway, Ollama, and so on. There are ~60 built in. Auth methods include browser OAuth
  (`/connect`), device-code OAuth, personal access tokens, cloud CLI identity, and plain API keys.
- In **T3 Code**, a provider is an **agent harness**: Codex, Claude Code, Cursor, Grok Build,
  OpenCode, Antigravity, or any ACP agent.

So "more model providers in T3" is not something you add to T3. You add them to a harness, and T3
inherits them. The `opencode` instance in T3 gives you every provider opencode supports, with
opencode's own auth flows.

## Getting more model providers (opencode route)

1. In a terminal, run `opencode auth login` (or `/connect` inside the TUI) and complete the flow for
   the provider you want. Browser OAuth, device code, and API keys are all supported.
2. Restart the `opencode` provider instance from T3 (Settings -> Providers), or reconnect it.
3. The new models show up in T3's model picker for any `opencode` thread, and are usable as the
   `model` in `t3_thread_launch` / `modelSelection`.

Because the manager dispatches threads as opencode sessions, the model map in the skill can pick any
of those providers per thread. T3 does not need to know about them.

## Adding a harness (ACP route)

T3's intended extension point for new agents is ACP (Agent Client Protocol). Upstream rule, from
`docs/internals/adding-a-provider.md`: ACP agents start as ACP Registry entries, and a dedicated
driver is added only when the agent needs behavior the spec does not cover. Never fork just to bolt
on one more agent.

**From the registry:**

1. **Settings -> Providers -> Add provider**.
2. Search the ACP Registry for the agent.
3. Select **Add**, confirm the name and instance ID.
4. Complete the agent's sign-in step.

**Local binary, no registry entry:**

1. **Settings -> Providers -> Add provider -> Local ACP command**.
2. Enter the executable name or path on the server machine, one literal argument per row, and a
   display name. Example from upstream docs, DeepSeek Harness: `dsh` with args `--profile` and `acp`.
3. T3 launches the executable directly. No shell expansion.

Registry agents install under `tools/<agent-id>/<version>/` inside T3 home and are verified by
SHA-256 when the registry provides a checksum. Removing an instance removes T3-managed binaries but
keeps package installs.

## Browser sign-in (the "web OAuth" flow)

For an installed ACP agent, open **Settings -> Providers -> Provider accounts** and choose
**Sign in**. If the agent offers several methods, pick one.

- Browser methods show the agent's URL and wait for you to open or copy it. The page opens in *your*
  browser, while the agent keeps running on the T3 server machine.
- Terminal methods run in an in-app terminal on that machine.
- T3 reconnects after the login and waits for the agent to confirm before reporting success.

## Harnesses with a CLI login

| Harness | Install | Authenticate |
|---|---|---|
| Codex | Codex CLI | `codex login` |
| Claude | Claude Code | `claude auth login` |
| Cursor | Cursor CLI | `agent login` |
| Grok Build | Grok Build CLI | `grok login` |
| OpenCode | `opencode` | `opencode auth login` |
| Antigravity | none required | Settings -> Install Antigravity -> Sign in with Google |
| ACP Registry agents | in-app | in-app sign-in |

## Cross-harness delegation

Delegation is not limited to the harness you are talking to. The orchestration MCP tool
`delegate_task` (and the thread tools) can create a child thread **on any supported provider
instance**. A Codex manager can delegate to an opencode thread, and vice versa.

That means this repo's model is a starting point, not a constraint: if you enable several instances,
the registry in the project `AGENTS.md` can assign each thread a different `instanceId` and model.
T3 stays the master manager; the harnesses stay workers.

## What not to do

- Do not fork T3 to add a single agent. Use ACP.
- Do not add agent-id special cases to the generic registry adapter upstream.
- Do not put API keys in `.t3` records or in the project `AGENTS.md`. Credentials belong to the
  provider instance.
