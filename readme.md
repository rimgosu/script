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

## install-claude-dir

이 레포의 `.claude/commands`, `.claude/skills` 를 `~/.claude` 로 복사(덮어쓰기).
항목 단위로만 덮어쓰므로 레포에 없는 **로컬 전용 커맨드/스킬은 그대로 남는다.**
덮어쓴 항목은 `~/.claude/.install-backup/<타임스탬프>/` 에 백업된다.

- install (clone 불필요)

```sh
curl -fsSL https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-claude-dir.sh | bash
```

- 먼저 무엇이 바뀌는지 확인 (권장)

```sh
curl -fsSL https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-claude-dir.sh | bash -s -- --dry-run --diff
```

> 동기화 방향은 **레포 → `~/.claude` 한쪽뿐**이다. `~/.claude` 에서 직접 고친 커맨드/스킬이 있으면
> 레포의 구버전으로 덮여쓰므로, 고친 내용은 이 레포에 먼저 커밋해두는 게 좋다.

clone 한 상태면 원격 다운로드 없이 로컬 파일을 쓴다. 그 외 옵션은 `--help` 참고
(`--ref <branch>`, `--local <dir>`, `--dest <dir>`).

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
