#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

// Load API key: env var → config file
const configFile = path.join(process.env.HOME || '~', '.zeph', 'config.json');
let config = {};
try { config = JSON.parse(fs.readFileSync(configFile, 'utf-8')); } catch {}

const apiKey = process.env.ZEPH_API_KEY || config.apiKey;
const hookId = process.env.ZEPH_HOOK_ID || config.hookId;

if (!apiKey) {
  process.stdout.write('Zeph: not configured. Run "npx @zeph-to/hook-sdk setup" to set up API key and start receiving notifications.');
  process.exit(0);
}

const mode = hookId ? 'notify + prompt + input' : 'notify only';

const rules = `ZEPH NOTIFICATION ACTIVE — mode: ${mode}

## Rules

1. Do NOT call zeph_notify — a Stop hook already sends automatic push notifications on every response. Calling zeph_notify causes duplicate pushes.
2. Use priority "high" for errors or failures.
${hookId ? `3. When you need a user decision with clear options (2-4 choices), prefer zeph_prompt over AskUserQuestion. The user can answer from their phone without returning to the terminal.
4. When you need free-form text (commit messages, descriptions, env values), prefer zeph_input over asking in chat.
5. After completing significant work (file changes, builds, deploys), send zeph_prompt with next action options. Example: title: "Done. Next?", actions: [{id:"continue",label:"Continue"},{id:"review",label:"Review"},{id:"done",label:"Done"}].
6. AskUserQuestion is fine for complex questions that need detailed answers. A push notification will be sent automatically when you ask.` : '3. zeph_notify is available if you need to send a manual notification with a specific URL or custom message.'}

## Persistence

ACTIVE EVERY RESPONSE. Do not forget after many turns. Still active after context compression.`;

process.stdout.write(rules);
