#!/usr/bin/env bash
# Zeph Agent Plugin — multi-agent installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/tak-bro/zeph-agent-plugin/main/install.sh | bash
#
# Flags:
#   --only <agent>   Install only for named agent (repeatable)
#   --dry-run        Preview, write nothing
#   --uninstall      Remove Zeph from all detected agents
#   --skip-config    Skip API key configuration prompt

set -euo pipefail

REPO="tak-bro/zeph-agent-plugin"
RAW_BASE="https://raw.githubusercontent.com/$REPO/main"

# ── Flags ──────────────────────────────────────────────────────────────────
DRY=0
UNINSTALL=0
SKIP_CONFIG=0
ONLY=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)      DRY=1 ;;
    --uninstall)    UNINSTALL=1 ;;
    --skip-config)  SKIP_CONFIG=1 ;;
    --only)         shift; ONLY+=("$1") ;;
    -h|--help)      sed -n '2,12p' "$0"; exit 0 ;;
    *)              echo "Unknown flag: $1"; exit 1 ;;
  esac
  shift
done

# ── Helpers ────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
skip() { echo -e "  ${YELLOW}✗${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }

should_install() {
  local agent="$1"
  if [ ${#ONLY[@]} -eq 0 ]; then return 0; fi
  for o in "${ONLY[@]}"; do
    if [ "$o" = "$agent" ]; then return 0; fi
  done
  return 1
}

# ── Detection ──────────────────────────────────────────────────────────────
echo -e "\n🔍 Detecting agents..."

HAS_CLAUDE=0
HAS_GEMINI=0
HAS_CURSOR=0
HAS_WINDSURF=0

command -v claude >/dev/null 2>&1 && HAS_CLAUDE=1
command -v gemini >/dev/null 2>&1 && HAS_GEMINI=1
[ -d "$HOME/.cursor" ] && HAS_CURSOR=1
[ -d "$HOME/.codeium" ] && HAS_WINDSURF=1

[ $HAS_CLAUDE -eq 1 ]   && ok "Claude Code"   || skip "Claude Code — not found"
[ $HAS_GEMINI -eq 1 ]   && ok "Gemini CLI"    || skip "Gemini CLI — not found"
[ $HAS_CURSOR -eq 1 ]   && ok "Cursor IDE"    || skip "Cursor — not found"
[ $HAS_WINDSURF -eq 1 ] && ok "Windsurf IDE"  || skip "Windsurf — not found"

# ── Uninstall ──────────────────────────────────────────────────────────────
if [ $UNINSTALL -eq 1 ]; then
  echo -e "\n🗑️  Uninstalling Zeph..."

  if [ $HAS_CLAUDE -eq 1 ]; then
    [ $DRY -eq 0 ] && claude plugin uninstall zeph 2>/dev/null && ok "Claude: plugin removed" || skip "Claude: not installed"
  fi

  if [ $HAS_GEMINI -eq 1 ]; then
    [ $DRY -eq 0 ] && gemini mcp remove zeph 2>/dev/null && ok "Gemini: MCP removed" || true
    [ $DRY -eq 0 ] && gemini extensions uninstall zeph 2>/dev/null && ok "Gemini: extension removed" || true
  fi

  if [ $HAS_CURSOR -eq 1 ] && [ -f "$HOME/.cursor/mcp.json" ]; then
    if command -v python3 >/dev/null 2>&1; then
      [ $DRY -eq 0 ] && python3 -c "
import json, sys
f='$HOME/.cursor/mcp.json'
try:
  d=json.load(open(f))
  if 'mcpServers' in d and 'zeph' in d['mcpServers']:
    del d['mcpServers']['zeph']
    json.dump(d, open(f,'w'), indent=2)
    print('  ✓ Cursor: MCP removed')
  else:
    print('  ✗ Cursor: zeph not in mcp.json')
except: pass
"
    fi
  fi

  echo -e "\n${GREEN}✅ Uninstall complete.${NC} Remove ZEPH_API_KEY/ZEPH_HOOK_ID from your shell profile manually."
  exit 0
fi

# ── Install ────────────────────────────────────────────────────────────────
echo ""

# Claude Code
if [ $HAS_CLAUDE -eq 1 ] && should_install "claude"; then
  echo -e "📦 Installing for Claude Code..."
  if [ $DRY -eq 0 ]; then
    claude plugin marketplace add "$REPO" 2>/dev/null && ok "Marketplace added" || ok "Marketplace already added"
    claude plugin install "zeph@zeph" 2>/dev/null && ok "Plugin installed" || ok "Plugin already installed"
  else
    echo "  [dry-run] claude plugin marketplace add $REPO"
    echo "  [dry-run] claude plugin install zeph@zeph"
  fi
fi

# Gemini CLI
if [ $HAS_GEMINI -eq 1 ] && should_install "gemini"; then
  echo -e "📦 Installing for Gemini CLI..."
  if [ $DRY -eq 0 ]; then
    gemini mcp add zeph -- npx -y @zeph-to/mcp-server 2>/dev/null && ok "MCP server added" || ok "MCP already configured"
    gemini extensions install "https://github.com/$REPO" 2>/dev/null && ok "Extension installed" || ok "Extension already installed"
  else
    echo "  [dry-run] gemini mcp add zeph -- npx -y @zeph-to/mcp-server"
    echo "  [dry-run] gemini extensions install https://github.com/$REPO"
  fi
fi

# Cursor
if [ $HAS_CURSOR -eq 1 ] && should_install "cursor"; then
  echo -e "📦 Installing for Cursor..."
  MCP_FILE="$HOME/.cursor/mcp.json"
  if [ $DRY -eq 0 ]; then
    if command -v python3 >/dev/null 2>&1; then
      python3 -c "
import json, os
f='$MCP_FILE'
d = {}
if os.path.exists(f):
  try: d = json.load(open(f))
  except: pass
if 'mcpServers' not in d: d['mcpServers'] = {}
d['mcpServers']['zeph'] = {
  'command': 'npx',
  'args': ['-y', '@zeph-to/mcp-server'],
  'env': {
    'ZEPH_API_KEY': '\${ZEPH_API_KEY}',
    'ZEPH_HOOK_ID': '\${ZEPH_HOOK_ID}',
    'ZEPH_BASE_URL': '\${ZEPH_BASE_URL}'
  }
}
json.dump(d, open(f, 'w'), indent=2)
" && ok "MCP server added to ~/.cursor/mcp.json"
    else
      fail "python3 not found — skipping Cursor MCP injection"
    fi

    # Write rule file
    mkdir -p "$HOME/.cursor/rules"
    curl -fsSL "$RAW_BASE/.cursor/rules/zeph.mdc" -o "$HOME/.cursor/rules/zeph.mdc" 2>/dev/null && ok "Rule file written" || fail "Failed to download rule file"
  else
    echo "  [dry-run] Inject zeph into $MCP_FILE"
    echo "  [dry-run] Write ~/.cursor/rules/zeph.mdc"
  fi
fi

# Windsurf
if [ $HAS_WINDSURF -eq 1 ] && should_install "windsurf"; then
  echo -e "📦 Installing for Windsurf..."
  MCP_FILE="$HOME/.codeium/windsurf/mcp_config.json"
  if [ $DRY -eq 0 ]; then
    if command -v python3 >/dev/null 2>&1; then
      python3 -c "
import json, os
f='$MCP_FILE'
d = {}
if os.path.exists(f):
  try: d = json.load(open(f))
  except: pass
if 'mcpServers' not in d: d['mcpServers'] = {}
d['mcpServers']['zeph'] = {
  'command': 'npx',
  'args': ['-y', '@zeph-to/mcp-server'],
  'env': {
    'ZEPH_API_KEY': '\${ZEPH_API_KEY}',
    'ZEPH_HOOK_ID': '\${ZEPH_HOOK_ID}',
    'ZEPH_BASE_URL': '\${ZEPH_BASE_URL}'
  }
}
json.dump(d, open(f, 'w'), indent=2)
" && ok "MCP server added to mcp_config.json"
    else
      fail "python3 not found — skipping Windsurf MCP injection"
    fi

    mkdir -p "$HOME/.windsurf/rules"
    curl -fsSL "$RAW_BASE/.windsurf/rules/zeph.md" -o "$HOME/.windsurf/rules/zeph.md" 2>/dev/null && ok "Rule file written" || fail "Failed to download rule file"
  else
    echo "  [dry-run] Inject zeph into $MCP_FILE"
    echo "  [dry-run] Write ~/.windsurf/rules/zeph.md"
  fi
fi

# ── API Key Configuration ──────────────────────────────────────────────────
if [ $SKIP_CONFIG -eq 0 ] && [ $DRY -eq 0 ]; then
  echo ""
  echo -e "🔑 ${YELLOW}Configuration${NC}"

  CURRENT_KEY="${ZEPH_API_KEY:-}"
  CURRENT_HOOK="${ZEPH_HOOK_ID:-}"

  if [ -n "$CURRENT_KEY" ]; then
    echo "  ZEPH_API_KEY already set: ${CURRENT_KEY:0:10}..."
  else
    echo "  Get your API key from Zeph → Settings → API Keys (MCP preset)"
    echo -n "  Enter ZEPH_API_KEY: "
    read -r NEW_KEY
    if [ -n "$NEW_KEY" ]; then
      CURRENT_KEY="$NEW_KEY"
    fi
  fi

  if [ -n "$CURRENT_KEY" ] && [ -z "$CURRENT_HOOK" ]; then
    echo ""
    echo "  Optional: For interactive prompts (zeph_prompt/zeph_input),"
    echo "  create a Hook at Settings → Developer → Hooks"
    echo -n "  Enter ZEPH_HOOK_ID (or press Enter to skip): "
    read -r NEW_HOOK
    if [ -n "$NEW_HOOK" ]; then
      CURRENT_HOOK="$NEW_HOOK"
    fi
  fi

  # Write to shell profile
  if [ -n "$CURRENT_KEY" ]; then
    SHELL_RC="$HOME/.zshrc"
    [ -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.bashrc"

    MARKER="# Added by Zeph"
    if ! grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
      echo "" >> "$SHELL_RC"
      echo "$MARKER" >> "$SHELL_RC"
      echo "export ZEPH_API_KEY=\"$CURRENT_KEY\"" >> "$SHELL_RC"
      [ -n "$CURRENT_HOOK" ] && echo "export ZEPH_HOOK_ID=\"$CURRENT_HOOK\"" >> "$SHELL_RC"
      echo ""
      ok "Added to $SHELL_RC"
      echo "  Run: source $SHELL_RC"
    else
      echo ""
      ok "Zeph env vars already in $SHELL_RC"
    fi
  fi
fi

# ── Done ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}✅ Done!${NC} Restart your agents to activate Zeph notifications."
echo ""
