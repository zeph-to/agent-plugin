# Zeph Agent Plugin

Push notifications, interactive prompts, and text input for AI coding agents — across all your devices.

## What it does

When your AI agent (Claude Code, Gemini CLI, Cursor, etc.) finishes a long task or needs your input, it sends a notification to your phone/browser/desktop via [Zeph](https://zeph.to).

## Features

### Automatic (via hooks — always works)

| Feature | Trigger | What happens |
|---------|---------|--------------|
| Task completion alert | Claude stops after 2+ tool calls | Push: "Claude 완료: {project} / {branch} — {N} tools" |
| Question alert | Claude calls AskUserQuestion | Push: "Claude 질문: {project} / {question}" |

These fire automatically via hooks. No agent cooperation needed — 100% reliable.

### MCP Tools (via agent — on request)

| Tool | What it does | Reliability |
|------|-------------|-------------|
| `zeph_notify` | Push notification with summary | Works when asked ("끝나면 zeph으로 알려줘") |
| `zeph_prompt` | Ask user to pick from options | Works when asked. Requires `ZEPH_HOOK_ID` |
| `zeph_input` | Request free-form text input | Works when asked. Requires `ZEPH_HOOK_ID` |
| `zeph_clipboard` | Copy text to clipboard | Works when asked |
| `zeph_file` | Send file to device | Works when asked |

> **Note:** MCP tools require the agent to voluntarily call them. Behavior rules (SKILL.md) encourage usage, but agents may not always follow. For guaranteed notifications, rely on the automatic hooks above.

### What doesn't work automatically

- **Agent auto-notify on completion** — SKILL.md rules tell the agent to notify after work, but agents don't reliably follow tool-calling instructions injected via hooks. Sometimes they do, sometimes they don't.
- **Mobile response to questions** — `zeph_prompt`/`zeph_input` let you answer from your phone, but only if the agent chooses to use them instead of `AskUserQuestion`. You can request this explicitly: "질문 있으면 zeph_prompt로 물어봐".

## Install

**One line:**

```bash
curl -fsSL https://raw.githubusercontent.com/tak-bro/zeph-agent-plugin/main/install.sh | bash
```

Detects your installed agents and configures each one automatically.

**Manual (Claude Code only):**

```bash
claude plugin marketplace add tak-bro/zeph-agent-plugin
claude plugin install zeph@zeph
```

**Manual (Gemini CLI):**

```bash
gemini mcp add zeph -- npx -y @zeph-to/mcp-server
gemini extensions install https://github.com/tak-bro/zeph-agent-plugin
```

## Configuration

Set these environment variables (the installer will prompt you):

```bash
export ZEPH_API_KEY="ak_..."       # Required — get from Settings > API Keys
export ZEPH_HOOK_ID="hook_..."     # Optional — for prompt/input features
export ZEPH_BASE_URL="https://api.zeph.to/v1"  # Optional — default is prod
```

Add to your shell profile (`~/.zshrc`, `~/.bashrc`, `~/.profile`, etc.) for persistence.

Or run `/zeph:setup` inside Claude Code for guided configuration.

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ZEPH_API_KEY` | Yes | API key from Settings > API Keys (MCP preset) |
| `ZEPH_HOOK_ID` | No | Hook ID for `zeph_prompt`/`zeph_input`. Create at Settings > Developer > Hooks |
| `ZEPH_BASE_URL` | No | API base URL. Default: `https://api.zeph.to/v1`. Use `/d1` for dev |
| `ZEPH_DEVICE_ID` | No | Target device. Omit to send to all devices |

## Supported Agents

| Agent | Auto Hooks | MCP Tools | Behavior Rules | Install Method |
|-------|:----------:|:---------:|:--------------:|----------------|
| Claude Code | ✓ | ✓ | ✓ | Plugin |
| Gemini CLI | — | ✓ | ✓ | Extension + MCP |
| Cursor | — | ✓ | ✓ | mcp.json + rule |
| Windsurf | — | ✓ | ✓ | mcp_config.json + rule |
| Cline | — | — | ✓ | Rule file |
| GitHub Copilot | — | — | ✓ | Instructions |
| Codex | — | — | ✓ | Hooks |
| Others (Zed, etc.) | — | — | ✓ | AGENTS.md |

> Auto Hooks (Stop/AskUserQuestion) are Claude Code plugin only. Other agents get MCP tools and/or behavior rules.

## How it works

```
┌─────────────────────────────────────────────────┐
│ Claude Code Session                             │
│                                                 │
│  Hook: Stop ──────────► zeph CLI ──► Push       │
│  Hook: AskUserQuestion ► zeph CLI ──► Push      │
│  MCP: zeph_notify ─────► Zeph API ──► Push      │
│  MCP: zeph_prompt ─────► Zeph API ──► Push+Wait │
│  MCP: zeph_input ──────► Zeph API ──► Push+Wait │
└─────────────────────────────────────────────────┘
```

1. **Hooks** (automatic) — Shell commands fire on Stop/AskUserQuestion events. Uses `zeph` CLI (`@zeph-to/hook-sdk`). Always works.
2. **MCP server** (on request) — `@zeph-to/mcp-server` registers tools. Agent calls them voluntarily or when asked.
3. **Behavior rules** (SKILL.md) — Tell the agent when to use tools. Soft guidance, not enforced.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/tak-bro/zeph-agent-plugin/main/install.sh | bash -s -- --uninstall
```

Remove env vars (`ZEPH_API_KEY`, `ZEPH_HOOK_ID`) from your shell profile manually.

## License

MIT
