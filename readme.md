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

## install-hidpi (mac)

BetterDisplay 없이 HiDPI(레티나식) 스케일 모드를 켜고 끄는 `hidpi` 커맨드.
`~/.local/bin/hidpi` 에 설치한다.

- install

```sh
curl -fsSL https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-hidpi.sh | bash
```

- 사용

```sh
hidpi status      # 현재 모드 (HiDPI면 exit 0, 아니면 1)
hidpi toggle      # HiDPI <-> 네이티브 1x
hidpi on          # HiDPI 켜기 (기본 1920x1080)
hidpi on 1600x900 # 더 넓게
hidpi off         # 네이티브 해상도로
hidpi list        # 선택 가능한 전체 모드
```

기본 논리 해상도는 `HIDPI_LOGICAL` 환경변수로, 멀티 모니터는 `-d <id>` 로 지정한다.
제거는 `install-hidpi.sh --uninstall`.

### 왜 되는지

macOS는 외장 모니터용 HiDPI 모드를 **이미 만들어두고 감춰둔다**. 공개 API
`CGDisplayCopyAllDisplayModes` 는 일부만 돌려주지만(예: 1440p 모니터에서 106개),
비공개 CGS API 로 열거하면 훨씬 많다(같은 모니터 247개). BetterDisplay·SwitchResX·RDM 도
같은 방식이며, 이 스크립트는 아래 3개만 쓴다.

- `CGSGetNumberOfDisplayModes`, `CGSGetDisplayModeDescriptionOfLength` — 숨은 모드까지 열거
- `CGSConfigureDisplayMode` — `kCGConfigurePermanently` 로 적용 (재부팅 후에도 유지)

SIP 해제·kext·EDID override·가상 디스플레이가 전부 필요 없다. bash 스크립트 안에 C 헬퍼
소스가 들어 있고, 최초 1회 clang 으로 컴파일해 `~/.cache/hidpi` 에 캐싱한다
(**Xcode Command Line Tools 필요**).

모드는 번호가 아니라 (해상도, 배율, 주사율) 속성으로 매번 다시 찾으므로 모니터를 바꿔 꽂아도
깨지지 않고, 조건에 맞는 것 중 최고 주사율을 고른다.

예를 들어 2560x1440 / 180Hz 모니터라면:

| 모드 | 논리 해상도 | 렌더링 | 패널 출력 |
|---|---|---|---|
| `hidpi on` | 1920x1080 @2x | 3840x2160 | 2560x1440 으로 다운스케일 |
| `hidpi on 1280x720` | 1280x720 @2x | 2560x1440 | 1:1 (스케일링 없음) |
| `hidpi off` | 2560x1440 @1x | 2560x1440 | 1:1 |

> 숨은 모드라 모니터를 뽑았다 꽂거나 재부팅했을 때 macOS 가 되돌리는 경우가 있다.
> 그러면 `hidpi on` 을 다시 실행하면 된다.

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

- 외장 모니터 HiDPI: [install-hidpi](#install-hidpi-mac) 참고
