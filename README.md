# Zeph — AI Agent Notifications

Get push notifications on your phone when your AI coding agent finishes work or needs input.

Works with Claude Code, Gemini CLI, Cursor, Windsurf, and more.

## Quick Start (Claude Code)

```bash
# 1. Install plugin
claude plugin marketplace add zeph-to/plugin
claude plugin install zeph@zeph

# 2. Configure (interactive — saves to ~/.zeph/config.json)
npx @zeph-to/hook-sdk setup
```

That's it. Restart Claude Code and you'll start getting notifications.

## What You Get

### Automatic — always works, no prompting needed

| What happens | When |
|-------------|------|
| Push: task completion summary | Claude finishes work (2+ tool calls) |
| Push: question text | Claude asks you a question |

These use hooks — shell commands that fire on Claude events. 100% reliable.

### On request — ask Claude to use them

| Tool | What it does | How to trigger |
|------|-------------|----------------|
| `zeph_notify` | Push notification | "끝나면 zeph으로 알려줘" |
| `zeph_prompt` | Pick from options (mobile-answerable) | "zeph_prompt로 물어봐" |
| `zeph_input` | Free-form text input (mobile-answerable) | "zeph_input으로 받아" |
| `zeph_clipboard` | Copy to clipboard | "클립보드에 복사해줘" |
| `zeph_file` | Send a file | "파일로 보내줘" |

These use MCP tools. Claude calls them when asked (or sometimes voluntarily).

> `zeph_prompt` and `zeph_input` require `ZEPH_HOOK_ID` — enter it during `zeph setup`.

## How It Works

```
You ──► Claude Code ──► does work ──► Stop Hook ──► zeph CLI ──► Push to phone
                    ──► asks question ──► Ask Hook ──► zeph CLI ──► Push to phone
                    ──► you say "알려줘" ──► MCP tool ──► Zeph API ──► Push to phone
```

Three layers:

| Layer | Package | What it does | Reliability |
|-------|---------|-------------|-------------|
| **Hooks** | `@zeph-to/hook-sdk` (CLI) | Auto-fires on Claude events | 100% — no AI cooperation needed |
| **MCP Server** | `@zeph-to/mcp-server` | AI-callable tools (notify, prompt, input...) | On request — AI must choose to call |
| **Plugin** | `zeph-to/plugin` | Bundles hooks + MCP + behavior rules | Installed once |

## Setup Details

### `zeph setup` — Interactive Configuration

```bash
npx @zeph-to/hook-sdk setup
```

Prompts for:
- **API Key** (required) — get from Zeph app > Settings > API Keys (MCP preset)
- **Hook ID** (optional) — for `zeph_prompt`/`zeph_input`. Create at Settings > Developer > Hooks
- **Base URL** (optional) — defaults to `https://api.zeph.to/v1`

Saves to `~/.zeph/config.json`. All Zeph tools (CLI, MCP server, plugin hooks) read this file.

### Priority: how credentials are resolved

```
--key flag  →  ZEPH_API_KEY env var  →  ~/.zeph/config.json
```

Environment variables override the config file. Flags override everything.

## Other Agents

### Gemini CLI

```bash
gemini mcp add zeph -- npx -y @zeph-to/mcp-server
```

### Cursor

Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "zeph": {
      "command": "npx",
      "args": ["-y", "@zeph-to/mcp-server"],
      "env": { "ZEPH_API_KEY": "ak_..." }
    }
  }
}
```

### Windsurf

Add to `~/.codeium/windsurf/mcp_config.json` (same format as Cursor).

### Auto-detect all agents

```bash
curl -fsSL https://raw.githubusercontent.com/zeph-to/plugin/main/install.sh | bash
```

Detects installed agents and configures each one.

## CLI Reference

The `zeph` CLI is also available standalone:

```bash
npx @zeph-to/hook-sdk <command>
```

| Command | Description |
|---------|-------------|
| `setup` | Interactive configuration |
| `notify --title "..." --body "..."` | Send a push |
| `list [--limit 5] [--type note]` | List recent pushes |
| `dismiss <push-id>` or `--all` | Dismiss pushes |
| `test` | Verify connection |

## Agent Support Matrix

| Agent | Auto Hooks | MCP Tools | Install |
|-------|:----------:|:---------:|---------|
| Claude Code | Yes | Yes | Plugin |
| Gemini CLI | — | Yes | `gemini mcp add` |
| Cursor | — | Yes | mcp.json |
| Windsurf | — | Yes | mcp_config.json |
| Cline | — | — | Rule file |
| GitHub Copilot | — | — | Instructions |
| Codex | — | — | Hooks |
| Aider | — | — | Config |

> Auto Hooks (completion/question alerts) are Claude Code only. Other agents get MCP tools.

## Uninstall

```bash
claude plugin uninstall zeph@zeph
rm ~/.zeph/config.json
```

Or remove from all agents:

```bash
curl -fsSL https://raw.githubusercontent.com/zeph-to/plugin/main/install.sh | bash -s -- --uninstall
```

## License

MIT
