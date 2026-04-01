아래 statusline 스크립트를 `~/.claude/statusline-command.sh`에 저장하고, `~/.claude/settings.json`의 `statusLine` 설정을 업데이트해줘.

## 스크립트

```sh
#!/bin/sh
input=$(cat)

# ctx used %
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_str=""
[ -n "$used" ] && ctx_str="ctx:$(printf '%.0f' "$used")%"

# 5h rate limit with reset countdown
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
five_str=""
if [ -n "$five_pct" ] && [ -n "$five_reset" ]; then
  now=$(date +%s)
  diff=$((five_reset - now))
  if [ "$diff" -le 0 ]; then
    time_str="now"
  else
    h=$((diff / 3600))
    m=$(((diff % 3600) / 60))
    if [ "$h" -gt 0 ]; then
      time_str="${h}h${m}m"
    else
      time_str="${m}m"
    fi
  fi
  five_str="5h:$(printf '%.0f' "$five_pct")%(rst:${time_str})"
fi

# 7d rate limit
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_str=""
[ -n "$week_pct" ] && week_str="7d:$(printf '%.0f' "$week_pct")%"

# account (Claude Code logged-in email)
acct=$(claude auth status 2>/dev/null | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')

# project folder (basename)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
[ -z "$cwd" ] && cwd=$(echo "$input" | jq -r '.cwd // empty')
dir=$(basename "$cwd")

# model
model=$(echo "$input" | jq -r '.model.display_name // empty')

# assemble — skip empty parts
parts=""
for p in "$ctx_str" "$five_str" "$week_str" "$acct" "$dir" "$model"; do
  [ -n "$p" ] && parts="${parts:+$parts | }$p"
done

printf '%s' "$parts"
```

## settings.json 설정

`statusLine` 키를 아래로 설정:

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh ~/.claude/statusline-command.sh"
  }
}
```

기존 statusLine 설정이 있으면 덮어쓰고, 다른 설정은 건드리지 마.
