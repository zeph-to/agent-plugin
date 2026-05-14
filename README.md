# Zeph — AI Agent Notifications

Get push notifications on your phone when your AI coding agent finishes work or needs input.

Works with Claude Code, Gemini CLI, Cursor, Windsurf, and more.

## Quick Start (Claude Code)

```bash
# 1. Install plugin
claude plugin marketplace add zeph-to/plugin
claude plugin install zeph@zeph

# 2. Configure — pick one:
npx @zeph-to/hook-sdk install                              # interactive
npx @zeph-to/hook-sdk install --key ak_... --hook hook_... # non-interactive (from Zeph app)
```

That's it. Restart Claude Code and you'll start getting notifications.

## What You Get

### Automatic — always works, no prompting needed

| What happens | When |
|-------------|------|
| Push: task completion summary | Claude finishes work (2+ tool calls) |
| Push: question text | Claude asks you a question |

These use hooks — shell commands that fire on Claude events. 100% reliable.

### On request — Claude calls when appropriate

With `ZEPH_HOOK_ID` configured, Claude prefers `zeph_ask` for decisions and input — showing buttons and a text field together. You can answer from your phone without returning to the terminal.

| Tool | What it does | When Claude uses it |
|------|-------------|---------------------|
| `zeph_ask` | Buttons + text input combined | Decisions, next steps, custom input |
| `zeph_prompt` | Pick from 2-4 options | Simple yes/no choices |
| `zeph_input` | Free-form text input | Text-only input |
| `zeph_notify` | Manual push notification | When explicitly asked |
| `zeph_clipboard` | Copy to clipboard | When explicitly asked |
| `zeph_file` | Send a file | When explicitly asked |

> `zeph_ask`, `zeph_prompt`, and `zeph_input` require `ZEPH_HOOK_ID` — enter it during `zeph install`.

## Mute / Unmute

Too many notifications? Mute them for the current session:

```
/zeph-mute      — Disable notifications for this project
/zeph-unmute    — Re-enable notifications
/zeph-status    — Check current state
```

Muting creates a temp file in `/tmp` — cleared on reboot. Both hooks (auto-notifications) and CLI calls are silenced.

## How It Works

### Session Flow

```
SessionStart hook
  ├─ ~/.zeph/config.json 읽기
  ├─ HOOK_ID 있음 → ask/prompt/input 규칙 주입
  └─ HOOK_ID 없음 → notify only 규칙 주입

Working...
  │
  ├─ 선택지+입력 필요 → zeph_ask → 모바일에서 버튼 or 텍스트 응답
  │   버튼 탭 or 커스텀 입력 → Claude 이어서 작업
  │
  ├─ 복잡한 질문 → AskUserQuestion → Ask hook 자동 push
  │   "Xcode 로그 보이는지?" → 모바일 알림 → 터미널로 이동
  │
  └─ 작업 완료
      └─ Stop hook → transcript 파싱 → push: 응답 요약
```

### Notification Summary

| Event | Source | Reliability | Duplicates |
|-------|--------|-------------|------------|
| Task completed | Stop hook | 100% | No (notify rule removed) |
| Question asked | Ask hook | 100% | No |
| Decision/input needed | MCP zeph_ask | ~80% | No |
| Decision only | MCP zeph_prompt | ~80% | No |
| Text input only | MCP zeph_input | ~80% | No |
| Manual notification | MCP zeph_notify | On request | No |

### Three Layers

```
zeph-to/plugin (Claude Code plugin)
  ├─ hooks/zeph-setup.js    → SessionStart: 규칙 주입
  ├─ hooks/zeph-stop.sh     → Stop: 자동 완료 알림
  ├─ hooks/zeph-ask.sh      → PreToolUse: 질문 알림
  ├─ .mcp.json              → MCP server 등록
  └─ uses:
      ├─ @zeph-to/hook-sdk     → CLI (notify/list/dismiss/test/setup)
      └─ @zeph-to/mcp-server   → MCP tools (ask/prompt/input/clipboard/file...)
```

| Layer | Package | What it does | Reliability |
|-------|---------|-------------|-------------|
| **Hooks** | `@zeph-to/hook-sdk` (CLI) | Auto-fires on Claude events | 100% — no AI cooperation needed |
| **MCP Server** | `@zeph-to/mcp-server` | AI-callable tools (ask, prompt, input...) | Depends on AI following rules |
| **Plugin** | `zeph-to/plugin` | Bundles hooks + MCP + behavior rules | Installed once |

### Config Priority

```
--key flag  →  ZEPH_API_KEY env var  →  ~/.zeph/config.json
    (CLI)         (shell)               (zeph setup)
```

## Setup Details

### `zeph install` — One-Command Setup

```bash
npx @zeph-to/hook-sdk install
```

Detects installed agents, prompts for credentials, installs hooks + MCP + rules for each agent.

- **API Key** (required) — get from Zeph app > Settings > API Keys (MCP preset)
- **Hook ID** (optional) — for `zeph_ask`/`zeph_prompt`/`zeph_input`. Create at Settings > Developer > Hooks

Saves to `~/.zeph/config.json`. All Zeph tools (CLI, MCP server, plugin hooks) read this file.

## Other Agents

### Quick Install (All Agents)

```bash
npm exec -y -- skills add zeph-to/plugin
```

Installs Zeph skill guide to any supported agent via the [skills ecosystem](https://github.com/vercel-labs/skills). For MCP + auto-notifications, use `install.sh` below.

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

```bash
npx @zeph-to/hook-sdk <command>
```

| Command | Description |
|---------|-------------|
| `install` | One-command setup for all agents |
| `notify --title "..." --body "..."` | Send a push |
| `list [--limit 5] [--type note]` | List recent pushes |
| `dismiss <push-id>` or `--all` | Dismiss pushes |
| `test` | Verify connection |

**Session commands (Claude Code only):**

| Command | Description |
|---------|-------------|
| `/zeph-mute` | Mute notifications for this project |
| `/zeph-unmute` | Re-enable notifications |
| `/zeph-status` | Check mute status |

## Agent Support Matrix

| Agent | Auto Notify | MCP Tools | How |
|-------|:-----------:|:---------:|-----|
| Claude Code | Yes (Stop hook) | Yes | Plugin |
| Cursor | Yes (stop hook) | Yes | MCP + hook + rules |
| Windsurf | Yes (response hook) | Yes | MCP + hook |
| Gemini CLI | Yes (AfterAgent hook) | Yes | MCP + hook |
| Codex CLI | Yes (Stop hook) | — | Hook |
| Copilot CLI | Yes (sessionEnd hook) | — | Hook |
| Cline | LLM-based | — | Skills |
| Aider | LLM-based | — | Skills |

All agents get skill guides via `npm exec -y -- skills add zeph-to/plugin`. For auto-notifications + MCP, use `install.sh`.

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
