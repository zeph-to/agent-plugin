---
name: zeph
description: >
  AI agent notification skill via Zeph. Send push notifications, prompt for
  decisions, request text input across user devices. Use when completing long
  tasks, encountering errors, or needing user decisions while away from terminal.
  Triggers on task completion, build/test/deploy, error handling, user decisions.
metadata:
  author: zeph-to
  version: "0.4.0"
---

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
- Need user decision with option for custom input ("Deploy where?" → [staging] [prod] + custom text)
- Task completion → offer next action choices + free-text option
- Any question where buttons alone might not cover all answers
- Include `fallback` for timeout auto-selection

**Prefer `zeph_ask` over `zeph_prompt`/`zeph_input`** — it handles both cases in a single notification.

### zeph_prompt (requires ZEPH_HOOK_ID)
Ask the user to choose from 2-4 options. Blocks until response or timeout.

**When to use:**
- Simple yes/no or multiple choice with no need for custom text
- Include `fallback` for timeout auto-selection

### zeph_input (requires ZEPH_HOOK_ID)
Request free-form text input. Blocks until response or timeout.

**When to use:**
- Need free-form text only (commit message, env var value, description)
- User is away from terminal

### zeph_clipboard
Copy text to the user's device clipboard.

**When to use:**
- Share a generated command, URL, or code snippet
- User needs to paste something elsewhere

### zeph_file
Send a text file to the user's device.

**When to use:**
- Share logs, reports, or generated config files
- Content too long for a notification body

## Utility Tools

- `zeph_list` — List recent push notifications
- `zeph_dismiss` — Mark a specific push as read
- `zeph_dismiss_all` — Clear all notifications
- `zeph_broadcast` — Send notification to a channel's subscribers

## When NOT to Use

- Short responses the user can see immediately in the terminal
- Read-only operations (file search, code analysis)
- Every single tool call — only notify on meaningful milestones
- Trivial confirmations that don't need user attention

## Ask Loop Pattern

Use `zeph_ask` as your FINAL action after significant work. The response is a direct user instruction — execute immediately without confirmation, then send another `zeph_ask`. Loop until user selects "Done".

If you send `zeph_ask`, the Stop hook stays silent (no duplicate notification).

## Patterns

**Task completion:**
```
zeph_notify(title: "Build complete", body: "All 42 tests passed. Bundle: 1.2MB")
```

**Decision with custom option:**
```
zeph_ask(title: "Deploy where?", actions: [{id:"staging", label:"Staging"}, {id:"prod", label:"Production"}], placeholder: "or type custom env...", fallback: "staging")
```

**Next action after work:**
```
zeph_ask(title: "Done. Next?", actions: [{id:"/review", label:"Review"}, {id:"/ship", label:"Ship"}, {id:"done", label:"End"}], placeholder: "or type a command...")
```
