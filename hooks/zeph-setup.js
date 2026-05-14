#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

// Load API key: env var → config file
const configFile = path.join(process.env.HOME || '~', '.zeph', 'config.json');
let config = {};
try { config = JSON.parse(fs.readFileSync(configFile, 'utf-8')); } catch {}

const envOr = (key) => { const v = process.env[key]; return v && !v.startsWith('${') ? v : undefined; };
const apiKey = envOr('ZEPH_API_KEY') || config.apiKey;
const hookId = envOr('ZEPH_HOOK_ID') || config.hookId;

if (!apiKey) {
  process.stdout.write('Zeph: not configured. Run "npx @zeph-to/hook-sdk setup" to set up API key and start receiving notifications.');
  process.exit(0);
}

const { execSync } = require('child_process');
const hasJq = (() => { try { execSync('command -v jq', { stdio: 'pipe' }); return true; } catch { return false; } })();

const mode = hookId ? 'notify + ask + prompt + input' : 'notify only';

const rules = `ZEPH NOTIFICATION ACTIVE — mode: ${mode}

## Rules

1. Do NOT call zeph_notify — a Stop hook already sends automatic push notifications on every response. Calling zeph_notify causes duplicate pushes.
2. Use priority "high" for errors or failures.
${hookId ? `3. PREFER zeph_ask for ANY question to the user — it shows buttons AND a text input field together. The user is on their phone and can only respond via push notifications. ALWAYS include a fallback action ID so timeout auto-selects a safe default.
4. Use zeph_prompt for simple yes/no choices, zeph_input for text-only input. But zeph_ask covers both cases — prefer it.
5. After completing significant work (file changes, builds, deploys), ALWAYS send zeph_ask with next action options and a text field for custom instructions. Example: title: "Done. Next?", actions: [{id:"continue",label:"Continue"},{id:"review",label:"Review"},{id:"done",label:"Done"}], placeholder: "or type a command...", fallback: "done".
6. Only use AskUserQuestion when the question requires sharing code/logs that cannot fit in a push notification body.
7. If zeph_ask times out and no fallback was set, proceed with the safest default action. Do NOT re-ask via AskUserQuestion.` : '3. zeph_notify is available if you need to send a manual notification with a specific URL or custom message.'}

## Persistence

ACTIVE EVERY RESPONSE. Do not forget after many turns. Still active after context compression.`;

if (!hasJq) {
  process.stdout.write(rules + '\n\n⚠️ jq not found — auto-notifications (Stop/Ask hooks) are disabled. Install: brew install jq (macOS) or apt install jq (Linux).');
} else {
  process.stdout.write(rules);
}
