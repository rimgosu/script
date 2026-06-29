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
```

```sh
/plugin install worktree-plugin@worktree-tools
```

## aws-quiz-rimnote skill

Udemy AWS SAA 연습 문제를 붙여넣으면 문제·보기(빈 체크박스)·정답/해설(토글) 형식으로
정리해 rimnote "aws saa" 프로젝트에 저장하는 Claude Code 스킬.
(rimnote MCP 서버가 연결돼 있어야 한다.)

- install (user scope — 다른 컴퓨터에서도 모든 프로젝트에 적용)

```sh
mkdir -p ~/.claude/skills/aws-quiz-rimnote
curl -fsSL https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/.claude/skills/aws-quiz-rimnote/SKILL.md \
  -o ~/.claude/skills/aws-quiz-rimnote/SKILL.md
```

- 또는 이 레포를 클론한 디렉터리 안에서는 `.claude/skills/aws-quiz-rimnote`가 자동으로 인식된다.
