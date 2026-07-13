---
argument-hint: <이슈로 만들 UI 문제/제안 설명 (+ 대상 URL)>
description: playwright로 UI를 캡처해 assets/ 브랜치에 올리고, 그 이미지를 첨부한 GitHub 이슈를 만든다.
---

# UI 캡처 → 이슈

이슈 내용: $ARGUMENTS

전제: `gh` CLI 인증 (`gh auth status`). 안 돼 있으면 `! gh auth login` 안내.

## 1. 캡처

앱이 떠 있는지 확인하고(안 떠 있으면 로컬 서버 실행), 이슈 대상 화면을 **playwright**로 캡처한다:

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
