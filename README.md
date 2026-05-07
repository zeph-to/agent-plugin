# Zeph Agent Plugin

Push notifications, interactive prompts, and text input for AI coding agents — across all your devices.

## What it does

When your AI agent (Claude Code, Gemini CLI, Cursor, etc.) finishes a long task or needs your input, it sends a notification to your phone/browser/desktop via [Zeph](https://zeph.to).

**Tools available:**
- `zeph_notify` — Push notification (build done, error alert)
- `zeph_prompt` — Ask you to pick from options (deploy? which branch?)
- `zeph_input` — Request text input (commit message, env value)
- `zeph_clipboard` — Copy to your clipboard
- `zeph_file` — Send a file to your device

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

Or run `/zeph:setup` inside Claude Code for guided configuration.

## Supported Agents

| Agent | MCP Tools | Behavior Rules | Install Method |
|-------|:---------:|:--------------:|----------------|
| Claude Code | ✓ | ✓ | Plugin |
| Gemini CLI | ✓ | ✓ | Extension + MCP |
| Cursor | ✓ | ✓ | mcp.json + rule |
| Windsurf | ✓ | ✓ | mcp_config.json + rule |
| Cline | — | ✓ | Rule file |
| GitHub Copilot | — | ✓ | Instructions |
| Codex | — | ✓ | Hooks |
| Others (Zed, etc.) | — | ✓ | AGENTS.md |

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/tak-bro/zeph-agent-plugin/main/install.sh | bash -s -- --uninstall
```

Remove `ZEPH_API_KEY` and `ZEPH_HOOK_ID` from your shell profile manually.

## How it works

1. Plugin registers the `@zeph-to/mcp-server` as an MCP server
2. Behavior rules (SKILL.md) tell the agent *when* to use each tool
3. Agent calls MCP tools → Zeph API → push to your devices
4. For `zeph_prompt`/`zeph_input`: agent waits for your response via polling

## License

MIT
