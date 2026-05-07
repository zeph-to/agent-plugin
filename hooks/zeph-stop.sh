#!/usr/bin/env bash
# Stop hook — notify when real work done (tool_count >= 2)
# Includes last assistant response summary in push body

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

# Extract last assistant text from transcript JSONL
SUMMARY=$(tac "$TRANSCRIPT" 2>/dev/null \
  | grep -m1 '"assistant"' \
  | python3 -c "
import sys, json
try:
    line = sys.stdin.readline()
    msg = json.loads(line)
    parts = msg.get('message', {}).get('content', [])
    texts = [p.get('text','') for p in parts if p.get('type') == 'text']
    out = ' '.join(texts).replace('\n', ' ').strip()
    print(out[:200] if out else '')
except:
    print('')
" 2>/dev/null)

BODY="${BRANCH} — ${TOOL_COUNT} tools"
if [ -n "$SUMMARY" ]; then
  BODY="$SUMMARY"
fi

zeph notify --title "Claude: $PROJECT" --body "$BODY" 2>/dev/null || true
