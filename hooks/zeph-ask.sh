#!/usr/bin/env bash
# PreToolUse(AskUserQuestion) hook — notify when Claude asks a question
ZEPH_CMD="$(command -v zeph 2>/dev/null || echo "npx -y @zeph-to/hook-sdk")"
MUTE_HASH=$(echo -n "${CLAUDE_PROJECT_DIR:-$(pwd)}" | cksum | cut -d' ' -f1)
[ -f "/tmp/zeph-muted-${MUTE_HASH}" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat)
QUESTION=$(echo "$INPUT" | jq -r '.tool_input.question // .tool_input.questions[0].question // "Question pending"' 2>/dev/null | head -c 200)

PROJECT=$(basename "$CLAUDE_PROJECT_DIR" 2>/dev/null || echo "unknown")

$ZEPH_CMD notify --title "Claude asks: $PROJECT" --body "$QUESTION" 2>/dev/null || true
