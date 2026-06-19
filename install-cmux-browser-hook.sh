#!/bin/bash
set -euo pipefail

# Claude Code가 브라우저 작업을 할 때 claude-in-chrome MCP 대신
# cmux browser CLI를 쓰도록 강제하는 PreToolUse 훅을 설치한다.
#
# install:
#   curl -fsSL https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-cmux-browser-hook.sh | bash

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
HOOK_PATH="$HOOKS_DIR/cmux-browser-redirect.sh"
SETTINGS="$CLAUDE_DIR/settings.json"
MATCHER="mcp__claude-in-chrome__.*"
HOOK_CMD="bash ~/.claude/hooks/cmux-browser-redirect.sh"

command -v jq >/dev/null 2>&1 || { echo "jq가 필요합니다. (brew install jq)"; exit 1; }

mkdir -p "$HOOKS_DIR"

# 1. 훅 스크립트 작성: claude-in-chrome MCP 호출을 deny 하고 cmux 사용법을 안내한다.
cat > "$HOOK_PATH" << 'HOOK'
#!/bin/bash
# Claude Code PreToolUse hook
# claude-in-chrome MCP 호출을 차단하고 cmux browser CLI로 유도한다.

cat > /dev/null  # stdin(tool 호출 페이로드) 비우기

cat << 'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "이 환경에서는 claude-in-chrome MCP 대신 cmux browser CLI(Bash)로 브라우저를 다루세요.\n\n주요 명령:\n  cmux browser open <url> --focus true         # 새 surface로 열기 (출력 예: surface:6)\n  cmux browser <surface> navigate <url>\n  cmux browser <surface> wait --selector <css> --timeout 10\n  cmux browser <surface> type --selector <css> --text <text>\n  cmux browser <surface> click --selector <css>\n  cmux browser <surface> press --key Enter\n  cmux browser <surface> get value|text|url [--selector <css>]\n  cmux browser <surface> snapshot -i           # 상호작용 요소 스냅샷\n  cmux browser <surface> screenshot --out <path>\n\n도움말: cmux browser --help  /  cmux docs browser"
  }
}
JSON
HOOK
chmod +x "$HOOK_PATH"
echo "✓ 훅 스크립트 설치: $HOOK_PATH"

# 2. settings.json 백업 후 PreToolUse 훅 병합 (멱등: 같은 matcher 중복 제거)
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
cp "$SETTINGS" "$SETTINGS.$(date +%Y%m%d%H%M%S).bak"

tmp="$(mktemp)"
jq --arg matcher "$MATCHER" --arg cmd "$HOOK_CMD" '
  .hooks //= {}
  | .hooks.PreToolUse //= []
  | .hooks.PreToolUse |= map(select(.matcher != $matcher))
  | .hooks.PreToolUse += [{
      "matcher": $matcher,
      "hooks": [{"type": "command", "command": $cmd}]
    }]
' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

echo "✓ settings.json 병합 완료 (matcher: $MATCHER)"
echo
echo "설치 완료. 새 Claude Code 세션부터 claude-in-chrome MCP 호출이 차단되고 cmux로 유도됩니다."
echo "되돌리려면 위에서 만든 .bak 파일을 settings.json 으로 복원하세요."
