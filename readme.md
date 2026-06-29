자주 사용하는 명령어 묶음

## user 추가

```bash
sudo useradd -m rimgosu
sudo passwd rimgosu
sudo usermod -aG sudo rimgosu # docker 같이 자주 사용하는 것도 권한 추가
```

## install-docker-ubuntu

ubuntu 22.04, 24.04에서 docker 설치

- install

```sh
curl https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-docker-ubuntu.sh | bash
```

## install-zsh

- install (ubuntu)

```sh
curl https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-zsh.sh | bash
```

- install (mac)

```sh
curl https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-zsh-mac.sh | bash
```

## install-nvm

zsh 환경에서 nvm 설치 및 `.nvmrc` 자동 로드 설정

- install

```sh
curl https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-nvm.sh | zsh
```

## install-cmux-browser-hook

Claude Code가 브라우저 작업 시 `claude-in-chrome` MCP 대신 `cmux browser` CLI를 쓰도록
강제하는 PreToolUse 훅 설치 (`~/.claude/settings.json` 병합, 기존 설정 백업)

- install

```sh
curl -fsSL https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-cmux-browser-hook.sh | bash
```

## install another apps

- install claude code

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

- install tailscale

```sh
curl -fsSL https://tailscale.com/install.sh | sh
```

## mac 환경 설정

- 한영키 매핑: <https://soobysu.tistory.com/175>
- right cmd -> f18, application -> fn (globe)

```sh
curl https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/mac-f18.sh | bash
```

## worktree skill

```sh
/plugin marketplace add rimgosu/worktree-marketplace
/plugin install worktree-plugin@worktree-tools
```
