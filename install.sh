#!/usr/bin/env bash
# Zeph Agent Plugin — multi-agent installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lemoncloud-io/zeph-plugin/main/install.sh | bash
#
# Flags:
#   --only <agent>   Install only for named agent (repeatable)
#   --dry-run        Preview, write nothing
#   --uninstall      Remove Zeph from all detected agents
#   --skip-config    Skip API key configuration prompt
#   --check-update   Check if a newer version is available
#   --verify         Verify installation health

set -euo pipefail

REPO="lemoncloud-io/zeph-plugin"
RAW_BASE="https://raw.githubusercontent.com/$REPO/main"

# ── Flags ──────────────────────────────────────────────────────────────────
DRY=0
UNINSTALL=0
SKIP_CONFIG=0
CHECK_UPDATE=0
VERIFY=0
ONLY=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)        DRY=1 ;;
    --uninstall)      UNINSTALL=1 ;;
    --skip-config)    SKIP_CONFIG=1 ;;
    --check-update)   CHECK_UPDATE=1 ;;
    --verify)         VERIFY=1 ;;
    --only)           shift; ONLY+=("$1") ;;
    -h|--help)        sed -n '2,14p' "$0"; exit 0 ;;
    *)                echo "Unknown flag: $1"; exit 1 ;;
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

inject_mcp_json() {
  local mcp_file="$1"
  if ! command -v python3 >/dev/null 2>&1; then
    fail "python3 not found — skipping MCP injection into $mcp_file"
    return 1
  fi
  python3 -c "
import json, os
f = '$mcp_file'
d = {}
if os.path.exists(f):
    try: d = json.load(open(f))
    except: pass
if 'mcpServers' not in d: d['mcpServers'] = {}
d['mcpServers']['zeph'] = {
    'command': 'npx',
    'args': ['-y', '@zeph-to/mcp-server'],
    'env': {'ZEPH_API_KEY': '\${ZEPH_API_KEY}'}
}
json.dump(d, open(f, 'w'), indent=2)
"
}

LOCAL_VERSION="0.1.0"

# ── Check Update ──────────────────────────────────────────────────────────
if [ $CHECK_UPDATE -eq 1 ]; then
  echo -e "\n🔄 Checking for updates..."
  REMOTE_VERSION=$(curl -fsSL "https://raw.githubusercontent.com/$REPO/main/.claude-plugin/plugin.json" 2>/dev/null \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('version','unknown'))" 2>/dev/null || echo "unknown")
  if [ "$REMOTE_VERSION" = "unknown" ]; then
    fail "Could not fetch remote version"
  elif [ "$REMOTE_VERSION" = "$LOCAL_VERSION" ]; then
    ok "Up to date (v$LOCAL_VERSION)"
  else
    echo -e "  ${YELLOW}⬆${NC}  Update available: v$LOCAL_VERSION → v$REMOTE_VERSION"
    echo "  Re-run the installer to update."
  fi
  exit 0
fi

# ── Detection ──────────────────────────────────────────────────────────────
echo -e "\n🔍 Detecting agents..."

HAS_CLAUDE=0
HAS_GEMINI=0
HAS_CURSOR=0
HAS_WINDSURF=0
HAS_CLINE=0
HAS_CODEX=0
HAS_AIDER=0

command -v claude >/dev/null 2>&1 && HAS_CLAUDE=1
command -v gemini >/dev/null 2>&1 && HAS_GEMINI=1
[ -d "$HOME/.cursor" ] && HAS_CURSOR=1
[ -d "$HOME/.codeium" ] && HAS_WINDSURF=1
{ command -v cline >/dev/null 2>&1 || [ -d "$HOME/.cline" ]; } && HAS_CLINE=1
command -v codex >/dev/null 2>&1 && HAS_CODEX=1
command -v aider >/dev/null 2>&1 && HAS_AIDER=1

[ $HAS_CLAUDE -eq 1 ]   && ok "Claude Code"   || skip "Claude Code — not found"
[ $HAS_GEMINI -eq 1 ]   && ok "Gemini CLI"    || skip "Gemini CLI — not found"
[ $HAS_CURSOR -eq 1 ]   && ok "Cursor IDE"    || skip "Cursor — not found"
[ $HAS_WINDSURF -eq 1 ] && ok "Windsurf IDE"  || skip "Windsurf — not found"
[ $HAS_CLINE -eq 1 ]    && ok "Cline"         || skip "Cline — not found"
[ $HAS_CODEX -eq 1 ]    && ok "Codex CLI"     || skip "Codex CLI — not found"
[ $HAS_AIDER -eq 1 ]    && ok "Aider"         || skip "Aider — not found"

# ── Verify ─────────────────────────────────────────────────────────────────
if [ $VERIFY -eq 1 ]; then
  echo -e "\n🩺 Verifying Zeph installation..."
  PASS=0
  TOTAL=0

  # Check env vars
  TOTAL=$((TOTAL + 1))
  if [ -n "${ZEPH_API_KEY:-}" ]; then
    ok "ZEPH_API_KEY is set"; PASS=$((PASS + 1))
  else
    fail "ZEPH_API_KEY not set"
  fi

  TOTAL=$((TOTAL + 1))
  if [ -n "${ZEPH_HOOK_ID:-}" ]; then
    ok "ZEPH_HOOK_ID is set (interactive features enabled)"; PASS=$((PASS + 1))
  else
    skip "ZEPH_HOOK_ID not set (prompt/input disabled)"
    PASS=$((PASS + 1))  # optional, not a failure
  fi

  # Check MCP server availability
  TOTAL=$((TOTAL + 1))
  if command -v npx >/dev/null 2>&1; then
    ok "npx available (MCP server can start)"; PASS=$((PASS + 1))
  else
    fail "npx not found — MCP server cannot start"
  fi

  # Check per-agent configs
  if [ $HAS_CLAUDE -eq 1 ]; then
    TOTAL=$((TOTAL + 1))
    if claude plugin list 2>/dev/null | grep -q "zeph"; then
      ok "Claude Code: plugin installed"; PASS=$((PASS + 1))
    else
      fail "Claude Code: plugin not installed"
    fi
  fi

  if [ $HAS_CURSOR -eq 1 ]; then
    TOTAL=$((TOTAL + 1))
    if [ -f "$HOME/.cursor/mcp.json" ] && python3 -c "import json; d=json.load(open('$HOME/.cursor/mcp.json')); assert 'zeph' in d.get('mcpServers',{})" 2>/dev/null; then
      ok "Cursor: MCP configured"; PASS=$((PASS + 1))
    else
      fail "Cursor: zeph not in mcp.json"
    fi
  fi

  if [ $HAS_WINDSURF -eq 1 ]; then
    TOTAL=$((TOTAL + 1))
    MCP_FILE="$HOME/.codeium/windsurf/mcp_config.json"
    if [ -f "$MCP_FILE" ] && python3 -c "import json; d=json.load(open('$MCP_FILE')); assert 'zeph' in d.get('mcpServers',{})" 2>/dev/null; then
      ok "Windsurf: MCP configured"; PASS=$((PASS + 1))
    else
      fail "Windsurf: zeph not in mcp_config.json"
    fi
  fi

  if [ $HAS_CODEX -eq 1 ]; then
    TOTAL=$((TOTAL + 1))
    if [ -f "$HOME/.codex/hooks.json" ]; then
      ok "Codex: hooks.json exists"; PASS=$((PASS + 1))
    else
      fail "Codex: hooks.json not found"
    fi
  fi

  echo ""
  if [ $PASS -eq $TOTAL ]; then
    echo -e "${GREEN}✅ All checks passed ($PASS/$TOTAL)${NC}"
  else
    echo -e "${YELLOW}⚠️  $PASS/$TOTAL checks passed${NC}"
  fi
  exit 0
fi

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

  # Remove MCP from JSON config files
  remove_mcp_json() {
    local f="$1" label="$2"
    if [ -f "$f" ] && command -v python3 >/dev/null 2>&1; then
      [ $DRY -eq 0 ] && python3 -c "
import json
f='$f'
try:
    d=json.load(open(f))
    if 'mcpServers' in d and 'zeph' in d['mcpServers']:
        del d['mcpServers']['zeph']
        json.dump(d, open(f,'w'), indent=2)
        print('  ✓ $label: MCP removed')
    else:
        print('  ✗ $label: zeph not configured')
except: pass
"
    fi
  }

  [ $HAS_CURSOR -eq 1 ] && remove_mcp_json "$HOME/.cursor/mcp.json" "Cursor"
  [ $HAS_WINDSURF -eq 1 ] && remove_mcp_json "$HOME/.codeium/windsurf/mcp_config.json" "Windsurf"

  # Remove rule/config files
  [ -f "$HOME/.cursor/rules/zeph.mdc" ] && rm "$HOME/.cursor/rules/zeph.mdc" && ok "Cursor: rule removed"
  [ -f "$HOME/.windsurf/rules/zeph.md" ] && rm "$HOME/.windsurf/rules/zeph.md" && ok "Windsurf: rule removed"
  [ -f "$HOME/.cline/rules/zeph.md" ] && rm "$HOME/.cline/rules/zeph.md" && ok "Cline: rule removed"
  [ -f "$HOME/.codex/hooks.json" ] && rm "$HOME/.codex/hooks.json" && ok "Codex: hooks removed"

  if [ -f "$HOME/.aider.conf.yml" ] && grep -q "# Added by Zeph" "$HOME/.aider.conf.yml" 2>/dev/null; then
    sed -i.bak '/# Added by Zeph/,/^$/d' "$HOME/.aider.conf.yml" && rm -f "$HOME/.aider.conf.yml.bak"
    ok "Aider: config cleaned"
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
  if [ $DRY -eq 0 ]; then
    inject_mcp_json "$HOME/.cursor/mcp.json" && ok "MCP server added to ~/.cursor/mcp.json"
    mkdir -p "$HOME/.cursor/rules"
    curl -fsSL "$RAW_BASE/.cursor/rules/zeph.mdc" -o "$HOME/.cursor/rules/zeph.mdc" 2>/dev/null && ok "Rule file written" || fail "Failed to download rule file"
  else
    echo "  [dry-run] Inject zeph into ~/.cursor/mcp.json"
    echo "  [dry-run] Write ~/.cursor/rules/zeph.mdc"
  fi
fi

# Windsurf
if [ $HAS_WINDSURF -eq 1 ] && should_install "windsurf"; then
  echo -e "📦 Installing for Windsurf..."
  if [ $DRY -eq 0 ]; then
    inject_mcp_json "$HOME/.codeium/windsurf/mcp_config.json" && ok "MCP server added to mcp_config.json"
    mkdir -p "$HOME/.windsurf/rules"
    curl -fsSL "$RAW_BASE/.windsurf/rules/zeph.md" -o "$HOME/.windsurf/rules/zeph.md" 2>/dev/null && ok "Rule file written" || fail "Failed to download rule file"
  else
    echo "  [dry-run] Inject zeph into ~/.codeium/windsurf/mcp_config.json"
    echo "  [dry-run] Write ~/.windsurf/rules/zeph.md"
  fi
fi

# Cline
if [ $HAS_CLINE -eq 1 ] && should_install "cline"; then
  echo -e "📦 Installing for Cline..."
  if [ $DRY -eq 0 ]; then
    mkdir -p "$HOME/.cline/rules"
    curl -fsSL "$RAW_BASE/.clinerules/zeph.md" -o "$HOME/.cline/rules/zeph.md" 2>/dev/null && ok "Rule file written" || fail "Failed to download rule file"
  else
    echo "  [dry-run] Write ~/.cline/rules/zeph.md"
  fi
fi

# Codex CLI
if [ $HAS_CODEX -eq 1 ] && should_install "codex"; then
  echo -e "📦 Installing for Codex CLI..."
  if [ $DRY -eq 0 ]; then
    mkdir -p "$HOME/.codex"
    curl -fsSL "$RAW_BASE/.codex/hooks.json" -o "$HOME/.codex/hooks.json" 2>/dev/null && ok "Hooks config written" || fail "Failed to download hooks config"
  else
    echo "  [dry-run] Write ~/.codex/hooks.json"
  fi
fi

# Aider
if [ $HAS_AIDER -eq 1 ] && should_install "aider"; then
  echo -e "📦 Installing for Aider..."
  AIDER_CONF="$HOME/.aider.conf.yml"
  if [ $DRY -eq 0 ]; then
    if [ ! -f "$AIDER_CONF" ] || ! grep -q "zeph" "$AIDER_CONF" 2>/dev/null; then
      cat >> "$AIDER_CONF" <<'AIDER_EOF'

# Added by Zeph
read: AGENTS.md
AIDER_EOF
      ok "Aider config updated ($AIDER_CONF)"
    else
      ok "Aider: zeph already configured"
    fi
  else
    echo "  [dry-run] Append zeph config to $AIDER_CONF"
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
    if [ -f "$HOME/.zshrc" ]; then SHELL_RC="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then SHELL_RC="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then SHELL_RC="$HOME/.bash_profile"
    elif [ -f "$HOME/.profile" ]; then SHELL_RC="$HOME/.profile"
    else SHELL_RC="$HOME/.zshrc"; fi

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
