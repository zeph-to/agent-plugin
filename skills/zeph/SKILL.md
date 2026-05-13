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

### zeph_prompt (requires ZEPH_HOOK_ID)
Ask the user to choose from 2-4 options. Blocks until response or timeout.

**When to use:**
- Need user decision (deploy target, confirm destructive action)
- Task completion → offer next action choices
- Include `fallback` for timeout auto-selection

### zeph_input (requires ZEPH_HOOK_ID)
Request free-form text input. Blocks until response or timeout.

**When to use:**
- Need free-form text (commit message, env var value, description)
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

## Patterns

**Task completion:**
```
zeph_notify(title: "Build complete", body: "All 42 tests passed. Bundle: 1.2MB")
```

**Decision gate:**
```
zeph_prompt(title: "Deploy to production?", actions: [{id:"yes", label:"Deploy"}, {id:"no", label:"Cancel"}], fallback: "no")
```

**Next action after work:**
```
zeph_prompt(title: "Done. Next?", actions: [{id:"/review", label:"Review"}, {id:"/ship", label:"Ship"}, {id:"done", label:"End"}])
```
