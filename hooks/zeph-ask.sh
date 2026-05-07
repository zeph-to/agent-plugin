#!/usr/bin/env bash
# PreToolUse(AskUserQuestion) hook — notify when Claude asks a question

INPUT=$(cat)
QUESTION=$(echo "$INPUT" | jq -r '.tool_input.question // .tool_input.questions[0].question // "질문 대기"' 2>/dev/null | head -c 200)

PROJECT=$(basename "$CLAUDE_PROJECT_DIR" 2>/dev/null || echo "unknown")

zeph notify --title "Claude 질문: $PROJECT" --body "$QUESTION" 2>/dev/null || true
