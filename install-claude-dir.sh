#!/bin/bash
set -euo pipefail

# 이 레포의 .claude/commands, .claude/skills 를 ~/.claude 로 복사(덮어쓰기)한다.
# 항목 단위로만 덮어쓰므로, 레포에 없는 로컬 전용 커맨드/스킬은 그대로 남는다.
#
# install (clone 없이):
#   curl -fsSL https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-claude-dir.sh | bash
#
# clone 한 상태에서 실행하면 원격 다운로드 없이 로컬 파일을 쓴다:
#   ./install-claude-dir.sh
#
# 옵션:
#   --dry-run        무엇이 바뀌는지만 출력하고 실제로 쓰지 않음
#   --diff           덮어쓸 항목의 diff 를 함께 출력 (--dry-run 과 같이 쓰면 안전하게 미리보기)
#   --ref <branch>   가져올 브랜치 (기본 main)
#   --local <dir>    지정한 디렉토리의 .claude 를 소스로 사용
#   --dest <dir>     설치 대상 (기본 ~/.claude)
#
# 주의: 동기화 방향은 레포 → ~/.claude 한쪽뿐이다. ~/.claude 에서 직접 고친 내용이 있으면
# 구버전으로 덮여쓰므로, 먼저 `--dry-run --diff` 로 확인하는 것을 권한다.
# (덮어쓴 항목은 ~/.claude/.install-backup/<타임스탬프>/ 에 백업된다)

REPO="rimgosu/script"
REF="main"
DEST="$HOME/.claude"
LOCAL_SRC=""
DRY_RUN=0
SHOW_DIFF=0

# 순회할 하위 디렉토리. 여기 이름만 추가하면 hooks 등도 같은 방식으로 동기화된다.
SUBDIRS=(commands skills)

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --diff) SHOW_DIFF=1; shift ;;
    --ref) REF="${2:?--ref 뒤에 브랜치명이 필요합니다}"; shift 2 ;;
    --local) LOCAL_SRC="${2:?--local 뒤에 디렉토리가 필요합니다}"; shift 2 ;;
    --dest) DEST="${2:?--dest 뒤에 디렉토리가 필요합니다}"; shift 2 ;;
    -h|--help)
      # curl | bash 로 실행되면 $0 를 읽을 수 없으므로 한 줄 usage 로 대체한다.
      if [ -r "${BASH_SOURCE[0]:-/nonexistent}" ]; then
        awk 'NR==1 { next } /^#/ { sub(/^# ?/, ""); print; started=1; next } started { exit }' "${BASH_SOURCE[0]}"
      else
        echo "usage: install-claude-dir.sh [--dry-run] [--diff] [--ref <branch>] [--local <dir>] [--dest <dir>]"
      fi
      exit 0 ;;
    *) echo "알 수 없는 옵션: $1" >&2; exit 1 ;;
  esac
done

shopt -s nullglob

TMPDIR_CLEANUP=""
# EXIT 트랩의 반환값이 스크립트 exit code가 되므로 명시적으로 0을 돌려준다.
cleanup() { [ -n "$TMPDIR_CLEANUP" ] && rm -rf "$TMPDIR_CLEANUP"; return 0; }
trap cleanup EXIT

# 1. 소스 .claude 디렉토리 결정: --local > 스크립트 옆의 .claude(=clone) > 원격 tarball
resolve_src() {
  if [ -n "$LOCAL_SRC" ]; then
    [ -d "$LOCAL_SRC/.claude" ] || { echo "$LOCAL_SRC/.claude 가 없습니다." >&2; exit 1; }
    ( cd "$LOCAL_SRC/.claude" && pwd )
    return
  fi

  # curl | bash 로 실행되면 BASH_SOURCE 가 실제 파일이 아니므로 이 분기를 건너뛴다.
  local self="${BASH_SOURCE[0]:-}"
  if [ -f "$self" ]; then
    local dir
    dir="$( cd "$(dirname "$self")" && pwd )"
    if [ -d "$dir/.claude" ]; then
      echo "$dir/.claude"
      return
    fi
  fi

  TMPDIR_CLEANUP="$(mktemp -d)"
  echo "↓ $REPO@$REF 다운로드..." >&2
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/$REF.tar.gz" \
    | tar -xzf - -C "$TMPDIR_CLEANUP"
  local found
  found="$(find "$TMPDIR_CLEANUP" -maxdepth 2 -type d -name .claude | head -1)"
  [ -n "$found" ] || { echo "tarball 안에서 .claude 를 찾지 못했습니다." >&2; exit 1; }
  echo "$found"
}

SRC="$(resolve_src)"
echo "source: $SRC"
echo "dest:   $DEST"
[ "$DRY_RUN" = 1 ] && echo "(dry-run — 실제로 쓰지 않습니다)"
echo

BACKUP_DIR="$DEST/.install-backup/$(date +%Y%m%d%H%M%S)"
n_new=0 n_upd=0 n_same=0 n_backup=0

# 2. 항목 단위 복사. 대상 디렉토리를 통째로 지우지 않으므로 로컬 전용 항목은 보존된다.
for sub in "${SUBDIRS[@]}"; do
  [ -d "$SRC/$sub" ] || continue
  echo "[$sub]"

  for item in "$SRC/$sub"/*; do
    name="$(basename "$item")"
    dest_item="$DEST/$sub/$name"

    if [ ! -e "$dest_item" ]; then
      status="new"
    elif diff -rq "$item" "$dest_item" >/dev/null 2>&1; then
      status="same"
    else
      status="upd"
    fi

    case "$status" in
      same) echo "  = $name"; n_same=$((n_same + 1)); continue ;;
      new)  echo "  + $name"; n_new=$((n_new + 1)) ;;
      upd)  echo "  ✓ $name (덮어씀)"; n_upd=$((n_upd + 1)) ;;
    esac

    # < 가 레포, > 가 현재 ~/.claude. > 쪽에만 있는 내용은 이 설치로 사라진다.
    if [ "$SHOW_DIFF" = 1 ] && [ "$status" = "upd" ]; then
      diff -ru "$item" "$dest_item" 2>/dev/null | sed 's/^/      /' || true
    fi

    [ "$DRY_RUN" = 1 ] && continue

    mkdir -p "$DEST/$sub"
    # 기존 항목은 백업해두고 지운 뒤 복사한다.
    # (스킬은 디렉토리이므로, 지우지 않으면 레포에서 삭제된 파일이 남는다)
    if [ -e "$dest_item" ]; then
      mkdir -p "$BACKUP_DIR/$sub"
      cp -R "$dest_item" "$BACKUP_DIR/$sub/"
      rm -rf "$dest_item"
      n_backup=$((n_backup + 1))
    fi
    cp -R "$item" "$dest_item"
  done
  echo
done

echo "완료: 신규 $n_new / 갱신 $n_upd / 변경없음 $n_same"
if [ "$n_backup" -gt 0 ]; then
  echo "덮어쓴 항목 $n_backup 개 백업: $BACKUP_DIR"
fi
if [ "$DRY_RUN" = 0 ] && [ $((n_new + n_upd)) -gt 0 ]; then
  echo "새 Claude Code 세션부터 반영됩니다."
fi
