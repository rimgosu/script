---
name: claude-rc-tmux
description: pve-claude-rc 서버에 새 tmux 세션을 만들고 claude --dangerously-skip-permissions 를 Remote Control 로 띄워, claude.ai/code·Claude 앱에서 바로 붙을 수 있게 한다. 사용자가 "claude rc 하나 띄워줘", "새 tmux에 claude 띄워" 등을 요청할 때 사용.
---

# claude-rc-tmux

입력: **이름**(tmux 세션명 = RC 세션명), **폴더**(기본 `/root`). 이름이 없으면 물어본다.

## 1. 바이너리 확인

```bash
ssh pve-claude-rc 'claude --version'
```

`Permission denied` / `native binary not installed` 이면 npm 업데이트 때 postinstall 이 안 돈 것이다.
떠 있는 세션에는 영향 없으니 바로 고친다:

```bash
ssh pve-claude-rc 'node /usr/lib/node_modules/@anthropic-ai/claude-code/install.cjs && claude --version'
```

## 2. 띄우기

같은 이름 세션이 이미 있으면(`tmux has-session -t <이름>`) 새로 만들지 말고 알려준다.

```bash
ssh pve-claude-rc "tmux new-session -d -s <이름> -c <폴더> \
  'claude --dangerously-skip-permissions --remote-control <이름>; exec bash -l'"
```

## 3. 확인 및 안내

```bash
ssh pve-claude-rc 'sleep 5; tmux capture-pane -p -t <이름> | tail -20'
```

화면에 뜬 세션 URL 을 그대로 전달한다. 첫 실행이라 trust 프롬프트 등에서 멈춰 있으면
`tmux send-keys -t <이름> Enter` 로 넘기고 다시 캡처한다.
최종 안내: tmux 세션명, 폴더, RC URL(또는 "claude.ai/code 목록에서 `<이름>`").
