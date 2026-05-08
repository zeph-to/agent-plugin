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
${hookId ? `3. ALWAYS use zeph_prompt when you need a user decision. Examples: choosing between options, confirming actions, selecting next steps. Do NOT use AskUserQuestion — the user may not be at the terminal.
4. ALWAYS use zeph_input when you need free-form text from the user. Examples: commit messages, descriptions, env values. Do NOT ask in chat.
5. After completing significant work (file changes, builds, deploys), send zeph_prompt with next action options. Example: title: "Done. Next?", actions: [{id:"continue",label:"Continue"},{id:"review",label:"Review"},{id:"done",label:"Done"}].
6. When uncertain about approach, ask via zeph_prompt with 2-4 concrete options instead of open-ended chat questions.` : '3. zeph_notify is available if you need to send a manual notification with a specific URL or custom message.'}

## Persistence

ACTIVE EVERY RESPONSE. Do not forget after many turns. Still active after context compression.`;

process.stdout.write(rules);
