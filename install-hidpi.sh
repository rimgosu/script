#!/bin/bash
set -euo pipefail

# BetterDisplay 없이 macOS HiDPI 모드를 켜고 끄는 `hidpi` 커맨드를 설치한다.
#
# install (clone 없이):
#   curl -fsSL https://raw.githubusercontent.com/rimgosu/script/refs/heads/main/install-hidpi.sh | bash
#
# clone 한 상태에서 실행하면 원격 다운로드 없이 옆의 hidpi.sh 를 쓴다:
#   ./install-hidpi.sh
#
# 옵션:
#   --ref <branch>   가져올 브랜치 (기본 main)
#   --dest <dir>     설치 대상 디렉토리 (기본 ~/.local/bin)
#   --uninstall      설치한 커맨드와 빌드 캐시를 제거
#
# macOS 전용이며 Xcode Command Line Tools(clang)가 필요하다.

REPO="rimgosu/script"
REF="main"
DEST="$HOME/.local/bin"
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --ref) REF="${2:?--ref 뒤에 브랜치명이 필요합니다}"; shift 2 ;;
    --dest) DEST="${2:?--dest 뒤에 디렉토리가 필요합니다}"; shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)
      # curl | bash 로 실행되면 $0 를 읽을 수 없으므로 한 줄 usage 로 대체한다.
      if [ -r "${BASH_SOURCE[0]:-/nonexistent}" ]; then
        awk 'NR==1 { next } /^#/ { sub(/^# ?/, ""); print; started=1; next } started { exit }' "${BASH_SOURCE[0]}"
      else
        echo "usage: install-hidpi.sh [--ref <branch>] [--dest <dir>] [--uninstall]"
      fi
      exit 0 ;;
    *) echo "알 수 없는 옵션: $1" >&2; exit 1 ;;
  esac
done

TARGET="$DEST/hidpi"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hidpi"

if [ "$UNINSTALL" = "1" ]; then
  rm -f "$TARGET" && echo "✓ 제거: $TARGET"
  rm -rf "$CACHE_DIR" && echo "✓ 빌드 캐시 제거: $CACHE_DIR"
  echo
  echo "디스플레이 모드는 되돌리지 않았습니다. 네이티브로 돌리려면 제거 전에 'hidpi off' 를 실행하거나,"
  echo "시스템 설정 > 디스플레이에서 해상도를 다시 고르세요."
  exit 0
fi

[ "$(uname -s)" = "Darwin" ] || { echo "macOS 전용 스크립트입니다." >&2; exit 1; }

# 1. 소스 결정: 스크립트 옆의 hidpi.sh(=clone) > 원격 다운로드
TMP=""
cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; return 0; }
trap cleanup EXIT

SRC=""
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  CANDIDATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/hidpi.sh"
  [ -r "$CANDIDATE" ] && SRC="$CANDIDATE"
fi

if [ -z "$SRC" ]; then
  TMP="$(mktemp -d)"
  SRC="$TMP/hidpi.sh"
  URL="https://raw.githubusercontent.com/$REPO/refs/heads/$REF/hidpi.sh"
  curl -fsSL "$URL" -o "$SRC" || { echo "다운로드 실패: $URL" >&2; exit 1; }
  echo "✓ 다운로드: $URL"
else
  echo "✓ 로컬 파일 사용: $SRC"
fi

# 2. 설치
mkdir -p "$DEST"
install -m 755 "$SRC" "$TARGET"
echo "✓ 설치: $TARGET"

# 3. 헬퍼 선빌드 — CLT가 없으면 여기서 바로 알려준다.
if ! command -v clang >/dev/null 2>&1; then
  echo
  echo "! Xcode Command Line Tools 가 없어 헬퍼를 빌드하지 못했습니다."
  echo "  xcode-select --install 후 'hidpi status' 를 실행하면 자동으로 빌드됩니다."
else
  "$TARGET" status >/dev/null 2>&1 || true   # 최초 빌드 유도 (모드 상태는 무시)
  echo "✓ 헬퍼 빌드 완료: $CACHE_DIR/hidpi-helper"
fi

# 4. PATH 안내
case ":$PATH:" in
  *":$DEST:"*) ;;
  *)
    echo
    echo "! $DEST 가 PATH에 없습니다. 쉘 설정에 아래를 추가하세요:"
    echo "    echo 'export PATH=\"$DEST:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
    ;;
esac

echo
echo "사용법:"
echo "  hidpi status      # 현재 모드"
echo "  hidpi toggle      # HiDPI <-> 네이티브 1x"
echo "  hidpi on          # HiDPI 켜기 (기본 1920x1080, HIDPI_LOGICAL 로 변경)"
echo "  hidpi on 1600x900 # 더 넓게"
echo "  hidpi off         # 네이티브 해상도로"
echo "  hidpi list        # 선택 가능한 전체 모드"
