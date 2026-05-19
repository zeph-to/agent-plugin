#!/usr/bin/env bash
# Stop hook — notify when real work done (tool_count >= 2)
ZEPH_CMD="$(command -v zeph 2>/dev/null || echo "npx -y @zeph-to/hook-sdk")"
command -v jq >/dev/null 2>&1 || exit 0
MUTE_HASH=$(echo -n "${CLAUDE_PROJECT_DIR:-$(pwd)}" | cksum | cut -d' ' -f1)
[ -f "/tmp/zeph-muted-${MUTE_HASH}" ] && exit 0

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

TOOL_COUNT=$(grep -c '"tool_use"' "$TRANSCRIPT" 2>/dev/null || echo 0)

if [ "$TOOL_COUNT" -lt 2 ]; then
  exit 0
fi

# Skip if AI already sent zeph_ask/zeph_prompt (avoid duplicate notification)
if grep -q '"zeph_ask"\|"zeph_prompt"' "$TRANSCRIPT" 2>/dev/null; then
  exit 0
fi

PROJECT=$(basename "$CLAUDE_PROJECT_DIR" 2>/dev/null || echo "unknown")
BRANCH=$(git -C "$CLAUDE_PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "-")

SUMMARY=$(tac "$TRANSCRIPT" 2>/dev/null \
  | grep -m1 '"end_turn"' \
  | jq -r '[.message.content[] | select(.type=="text") | .text] | join(" ") | .[0:5000]' 2>/dev/null)

BODY="${BRANCH} — ${TOOL_COUNT} tools"
if [ -n "$SUMMARY" ] && [ "$SUMMARY" != "null" ]; then
  BODY="$SUMMARY"
fi

# Extract session UUID from transcript path (more reliable than tmp file)
SESSION_ID=$(echo "$TRANSCRIPT" | grep -o '[0-9a-f]\{8\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{12\}')
[ -z "$SESSION_ID" ] && SESSION_ID=$(cat "/tmp/zeph-session-${MUTE_HASH}" 2>/dev/null)
SESSION_FLAG=""
[ -n "$SESSION_ID" ] && SESSION_FLAG="--session $SESSION_ID"
$ZEPH_CMD notify --title "Claude: $PROJECT" --body "$BODY" --type hook $SESSION_FLAG 2>/dev/null || true
