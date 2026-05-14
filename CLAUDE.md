# Zeph — AI Agent Notification Skill

Use Zeph MCP tools to communicate with the user across devices (mobile, browser, desktop).

## Core Tools

### zeph_notify
Send a one-way push notification.

**When to use:**
- Long task completed (build, test, deploy, large refactor)
- Error or failure that blocks progress
- Multi-session workflow: signal which session finished

**Format:** title under 50 chars, body under 200 chars. Include `url` for actionable links. Use `priority: "high"` for errors/blockers.

### zeph_ask (requires ZEPH_HOOK_ID) — Preferred
Ask the user with quick-reply buttons AND a text input field combined. Blocks until response or timeout.

**When to use:**
- Need user decision with option for custom input
- Task completion → offer next action choices + free-text option
- Prefer over `zeph_prompt`/`zeph_input` — handles both in one notification

### zeph_prompt (requires ZEPH_HOOK_ID)
Ask the user to choose from 2-4 options. Blocks until response or timeout.

### zeph_input (requires ZEPH_HOOK_ID)
Request free-form text input. Blocks until response or timeout.

### zeph_clipboard
Copy text to the user's device clipboard.

### zeph_file
Send a text file to the user's device.

## Utility Tools

- `zeph_list` — List recent push notifications
- `zeph_dismiss` — Mark a specific push as read
- `zeph_dismiss_all` — Clear all notifications
- `zeph_broadcast` — Send notification to a channel's subscribers

## Session Mute

Users can mute notifications for the current project:
- `/zeph-mute` — disable all notifications (hooks + MCP tools)
- `/zeph-unmute` — re-enable notifications
- `/zeph-status` — check current state

When muted, do not call any zeph MCP tools.

## When NOT to Use

- Short responses the user can see immediately in the terminal
- Read-only operations (file search, code analysis)
- Every single tool call — only notify on meaningful milestones
- Trivial confirmations that don't need user attention

## Automatic Behavior

After completing a task that took significant effort (multiple tool calls, file changes, or long analysis), automatically send `zeph_notify` with a summary. Do not ask permission — just notify.

After completing work, offer next actions via `zeph_ask` (or `zeph_prompt`) if ZEPH_HOOK_ID is available.
