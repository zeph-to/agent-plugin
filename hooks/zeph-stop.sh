#!/usr/bin/env bash
# Stop hook — notify when real work done (tool_count >= 2)

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

TOOL_COUNT=$(grep -c '"tool_use"' "$TRANSCRIPT" 2>/dev/null || echo 0)

if [ "$TOOL_COUNT" -lt 2 ]; then
  exit 0
fi

PROJECT=$(basename "$CLAUDE_PROJECT_DIR" 2>/dev/null || echo "unknown")
BRANCH=$(git -C "$CLAUDE_PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "-")

zeph notify --title "Claude 완료: $PROJECT" --body "$BRANCH — ${TOOL_COUNT} tools" 2>/dev/null || true
