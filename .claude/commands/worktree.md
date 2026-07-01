---
argument-hint: <branch>
description: git worktree를 따서 작업하고 target branch로 PR을 올린다. UI 작업이면 스크린샷을 assets/ 브랜치에 올려 PR에 첨부.
---

# Worktree → PR

target branch: `$1` (없으면 아래 규칙으로 판단)
작업 내용: $ARGUMENTS

`<branch>`(target branch)와 작업 내용(프롬프트)을 받아
worktree를 만들고 → 작업하고 → target branch로 PR을 올린다.

전제: `gh` CLI가 인증돼 있어야 한다 (`gh auth status`). 안 돼 있으면 사용자에게 `! gh auth login` 안내.

## 1. target branch 결정

우선순위대로 판단한다:

1. **`$1` 인자가 주어지면** → 그게 target branch. (아래 remote clone/current 판단 건너뜀)
2. 인자가 없을 때:
   - **git clone 해서 작업하라는 요청이면** → clone 후 remote의 default branch를 target으로.
   - **폴더가 지정됐거나 현재 디렉토리가 git repo 안이면** → 현재 브랜치를 target으로.
     단, **현재 브랜치가 `main`/`master`/`dev`/`prod` 중 하나가 아니면** → remote default branch를 target으로.

remote default branch 구하기:

```bash
git remote show origin | sed -n 's/.*HEAD branch: //p'
# 또는 (fetch 필요 없을 때 로컬에서):
git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||'
```

현재 브랜치: `git rev-parse --abbrev-ref HEAD`

## 2. target branch pull

worktree를 따기 전에 target branch를 최신화한다. 로컬에 checkout하지 않고도:

```bash
git fetch origin <target>
# 현재 target이 checkout된 상태면
git pull --ff-only origin <target>
```

## 3. worktree 생성

**작업 브랜치 이름**: `<target>` 기준으로 새 브랜치를 만든다. 작업 내용에서 유추한 kebab-case
이름을 쓴다 (예: `feat/login-button`, `fix/null-guard`). 사용자가 이름을 줬으면 그걸 쓴다.

**위치 결정** — repo의 `.gitignore`에 `.claude/worktrees`가 등록돼 있는지 확인:

```bash
git check-ignore -q .claude/worktrees && echo "IN_GITIGNORE" || echo "NOT"
```

- 등록돼 있으면 → `<repo>/.claude/worktrees/<work-branch>`
- 아니면 → `/private/tmp/worktrees/<repo>-<work-branch>` (macOS는 `/private/tmp`, 없으면 `/tmp`)

생성:

```bash
git worktree add -b <work-branch> <worktree-path> origin/<target>
```

이후 모든 작업은 `<worktree-path>` 안에서 수행한다.

## 4. 작업 수행

프롬프트에 나온 작업을 worktree 안에서 진행한다. 커밋은 논리 단위로 나눠서 한다.

## 5. UI 작업이면 스크린샷 첨부 (특이사항 1)

주로 UI(화면/컴포넌트/스타일)를 바꾼 작업이면 변경 결과를 스크린샷으로 PR에 넣는다.
GitHub에서 이미지가 보이려면 **레포에 실제 커밋된 raw URL**이 필요하므로, 작업 브랜치가 아닌
**`assets/` prefix 브랜치**에 이미지만 올린다 (작업 diff를 이미지로 오염시키지 않기 위해).

절차:
1. 앱을 띄우고 변경된 화면을 스크린샷으로 캡처한다 (`claude-in-chrome`의 `computer`/`gif_creator`,
   또는 프로젝트의 스크린샷 방법). png 또는 jpg로 저장.
2. `assets/<work-branch>` 브랜치를 default branch에서 따서 이미지만 커밋·push:
   ```bash
   git switch -c assets/<work-branch> origin/<target>
   mkdir -p screenshots && cp <png들> screenshots/
   git add screenshots && git commit -m "assets: <work-branch> 스크린샷"
   git push -u origin assets/<work-branch>
   ```
3. raw URL을 만든다 (owner/repo는 `gh repo view --json nameWithOwner -q .nameWithOwner`):
   ```
   https://raw.githubusercontent.com/<owner>/<repo>/assets/<work-branch>/screenshots/<file>.png
   ```
4. 이 raw URL을 PR 본문에 `![설명](URL)` 로 넣는다.

UI 작업이 아니면 이 단계 전체를 건너뛴다.

## 6. PR 생성 (특이사항 2: 이어서 작업 vs 새 PR)

이어서 작업(보강/수정) 요청이면 **커밋하기 전에 반드시** 직전 브랜치의 머지 여부를
먼저 확인한다. 이 명령을 실행하지 않고 기존 브랜치에 이어서 push하는 것을 금지한다:

```bash
gh pr view <직전-work-branch> --json state,mergedAt,url
```

출력에 따라 분기한다:

- **`state`가 `MERGED` (또는 `mergedAt`이 null 아님)** → 이미 머지됐으므로 그 브랜치에
  절대 이어서 push하지 않는다. 최신 `<target>`을 fetch(2단계)한 뒤 **새 worktree를 따고**(3단계)
  **새 PR**을 만든다.
- **`state`가 `OPEN` + 이번 요청이 그 작업의 연속(보강/수정)** →
  기존 worktree에서 이어서 커밋하고 push만 한다. PR은 새로 만들지 않고 기존 PR이 갱신된다.
- **`state`가 `OPEN` + 이번 요청이 별개의 새 작업** →
  새 worktree(3단계)에서 새 PR을 만든다.
- **직전 브랜치의 PR이 없으면**(`gh pr view`가 실패) → 새 작업으로 보고 새 worktree/새 PR.

애매하면 사용자에게 "기존 PR #N에 이어서 할까요, 새 PR로 갈까요?" 한 줄로 확인한다.

새 PR 생성:

```bash
git push -u origin <work-branch>
gh pr create --base <target> --head <work-branch> \
  --title "<작업 제목>" --body "<본문>"
```

PR 본문에는 변경 요약 + (UI면) 스크린샷 이미지를 포함한다.

## 마무리

- worktree 경로, PR URL을 사용자에게 알려준다.
- 작업이 끝나 필요 없어진 worktree는 사용자 확인 후 `git worktree remove <path>`로 정리한다.
