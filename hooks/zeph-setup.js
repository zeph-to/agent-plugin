#!/usr/bin/env node
'use strict';

const apiKey = process.env.ZEPH_API_KEY;
const hookId = process.env.ZEPH_HOOK_ID;

if (!apiKey) {
  console.log(JSON.stringify({
    message: 'Zeph: ZEPH_API_KEY not set. Run /zeph:setup for guided configuration.'
  }));
  process.exit(0);
}

const mode = hookId ? 'notify + prompt + input' : 'notify only';
console.log(JSON.stringify({ message: `Zeph: ${mode} ready` }));
