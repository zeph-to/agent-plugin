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

## Mandatory Rules

1. ALWAYS send zeph_notify at the END of every response where you used 3+ tool calls OR modified files OR ran commands. No exceptions. This is your LAST action.
2. Format: title = what you did (under 50 chars), body = result summary (under 200 chars).
3. Use priority "high" for errors or failures.
${hookId ? '4. After work is done, send zeph_prompt with next action options (title: "Next?", actions: [{id:"continue",label:"Continue"},{id:"done",label:"Done"}]).' : ''}
${hookId ? '5. When you need a user decision, use zeph_prompt. When you need free text, use zeph_input. Do NOT ask in chat.' : ''}
6. SKIP notify ONLY for: single-sentence answers with zero tool use.

## Persistence

ACTIVE EVERY RESPONSE. Do not forget after many turns. Do not skip. Still active even after context compression.`;

process.stdout.write(rules);
