---
argument-hint: <이슈로 만들 UI 문제/제안 설명 (+ 대상 URL)>
description: playwright로 UI를 캡처해 assets/ 브랜치에 올리고, 그 이미지를 첨부한 GitHub 이슈를 만든다.
---

# UI 캡처 → 이슈

이슈 내용: $ARGUMENTS

전제: `gh` CLI 인증 (`gh auth status`). 안 돼 있으면 `! gh auth login` 안내.

## 1. 캡처

### 1-1. 앱 실행·로그인은 레포 문서를 먼저 찾는다

앱이 떠 있는지 확인한다. 안 떠 있거나 **로그인된 화면이 필요하면, 직접 추측해서 시도하기 전에**
레포의 프로젝트 문서를 먼저 읽는다. 로컬 인프라 주소·시드 계정·포트 제약 같은 건 레포마다 다르고,
모르고 시도하면 캡처는 시작도 못 하고 로그인 단계에서 시간을 다 쓴다.

```bash
ls .claude/skills/ 2>/dev/null          # local-dev, dev-login 류의 스킬
cat CLAUDE.md 2>/dev/null | head -50
ls docker-compose*.yml *.env.example 2>/dev/null
```

- **로그인이 막히면** (401, CORS 오류, 로그인 폼이 안 보임, 소셜 로그인만 있음 등)
  레포의 스킬/문서에서 **seed 계정으로 로그인하는 방법**을 찾아 그대로 따른다.
  보통 `prisma seed`(또는 유사한 시드 스크립트)로 만든 테스트 계정 + 세션 저장 스크립트가 준비돼 있다.
  예: rimnote → `.claude/skills/local-dev/SKILL.md` (`docker-compose.local.yml` → `local:seed` →
  `dev-login.mjs`로 `storage-state.json` 생성)
- 문서가 없으면 UI로 회원가입·로그인을 반복 시도하지 말고, **API에 직접 로그인 요청을 보내
  쿠키/토큰을 받는 경로**를 먼저 확인한다. 그것도 막히면 사용자에게 계정·절차를 물어본다.
- **이슈 자체가 로그인 문제**라면(로그인이 안 되는 게 현상) 우회하지 말고 그 실패 화면·콘솔·네트워크
  응답을 그대로 캡처해 이슈에 넣는다.

### 1-2. playwright 캡처

이슈 대상 화면을 **playwright**로 캡처한다:

```bash
# 데스크톱
npx --yes playwright screenshot --viewport-size=1440,900 --full-page \
  --wait-for-selector <css> <url> <path>-desktop.png
# 모바일 (반응형/모바일 조건이 있는 화면이면 반드시 같이 캡처)
npx --yes playwright screenshot --device="iPhone 13" --full-page \
  --wait-for-selector <css> <url> <path>-mobile.png
```

- **모바일 조건 확인**: 대상 화면에 미디어쿼리/모바일 분기(반응형 레이아웃, 모바일 전용 UI)가
  있으면 데스크톱·모바일 두 장 모두 캡처해 이슈에 첨부한다. 순수 데스크톱 전용 화면이면 데스크톱만.
- playwright 브라우저가 없으면 최초 1회 `npx --yes playwright install chromium`.
- 클릭 등 상호작용이 필요하면 임시 스크립트로 `chromium.launch()` → `page.goto` → 상호작용 → `page.screenshot()`.
- **로그인 세션이 필요하면** `--load-storage <file>` 사용. storage 파일은 `--save-storage`로 만들거나,
  레포에 seed 로그인 스크립트가 있으면 그걸로 만든다 (1-1 참고). 로그인 쿠키가 httpOnly면
  localStorage에 토큰을 주입하는 우회는 통하지 않으므로 이 방법이 사실상 유일하다.
- 문제 상황을 보여주는 화면을 정확히 잡는다. 필요하면 여러 장.

## 2. assets 브랜치에 push

현재 작업 브랜치를 건드리지 않도록 **임시 worktree**에서 커밋한다.
브랜치명: `assets/issue-<slug>` (slug는 이슈 내용에서 유추한 kebab-case).

```bash
default=$(git remote show origin | sed -n 's/.*HEAD branch: //p')
git worktree add /tmp/assets-issue-<slug> -b assets/issue-<slug> origin/$default
cp <png들> /tmp/assets-issue-<slug>/screenshots/   # mkdir -p 먼저
cd /tmp/assets-issue-<slug> && git add screenshots \
  && git commit -m "assets: issue-<slug> 스크린샷" && git push -u origin assets/issue-<slug>
sha=$(git rev-parse HEAD)
git worktree remove /tmp/assets-issue-<slug>
```

## 3. 이슈 생성

커밋 **SHA** raw URL로 인라인 임베드한다 (브랜치명 금지 — 슬래시 든 브랜치는 raw URL에서
ref/경로 구분이 모호함. SHA는 불변이라 안전. private repo도 렌더링 됨):

```markdown
![설명](https://github.com/<owner>/<repo>/raw/<sha>/screenshots/<file>.png)
```

owner/repo: `gh repo view --json nameWithOwner -q .nameWithOwner`

```bash
gh issue create --title "<이슈 제목>" --label ui \
  --body "<현상 설명 + 스크린샷 임베드 + 기대 동작>"
```

- `ui` 라벨이 없어서 실패하면 `gh label create ui --color FBCA04` 후 재시도.
- 내용상 더 맞는 라벨(`bug`, `enhancement` 등)이 repo에 있으면 함께 단다.

## 마무리

이슈 URL을 사용자에게 알려준다.
