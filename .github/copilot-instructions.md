# Zeph — AI Agent Notification Skill

Use Zeph MCP tools to communicate with the user across devices (mobile, browser, desktop).

## Core Tools

- `zeph_notify` — Send push notification. Use after long tasks, errors, or multi-session completion.
- `zeph_prompt` — Ask user to choose from 2-4 options. Use for decisions, confirmations.
- `zeph_input` — Request free-form text. Use for commit messages, env values.
- `zeph_clipboard` — Copy text to user's clipboard.
- `zeph_file` — Send text file to user's device.

## When NOT to Use

- Short responses visible in terminal
- Read-only operations
- Every tool call — only meaningful milestones
