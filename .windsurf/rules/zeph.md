---
trigger: always_on
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

### zeph_input (requires ZEPH_HOOK_ID)
Request free-form text input. Blocks until response or timeout.

**When to use:**
- Need free-form text (commit message, env var value, description)
- User is away from terminal

### zeph_clipboard
Copy text to the user's device clipboard.

### zeph_file
Send a text file to the user's device.

## When NOT to Use

- Short responses the user can see immediately in the terminal
- Read-only operations (file search, code analysis)
- Every single tool call — only notify on meaningful milestones
