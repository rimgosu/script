#!/usr/bin/env bash
#
# hidpi — BetterDisplay 없이 macOS HiDPI(레티나식) 스케일 모드를 켜고 끈다.
#
# macOS는 대부분의 외장 모니터용 HiDPI 모드를 이미 만들어두고도 시스템 설정과
# 공개 API(CGDisplayCopyAllDisplayModes)에서는 감춰둔다. 이 스크립트는
# BetterDisplay·SwitchResX·RDM 이 쓰는 것과 같은 비공개 CoreGraphics/SkyLight
# 호출로 그 숨은 목록에 접근한다. SIP 해제, kext, EDID override, 가상 디스플레이
# 전부 필요 없다.
#
# 사용법:
#   hidpi status              현재 모드 출력 (HiDPI면 exit 0, 아니면 1)
#   hidpi list                선택 가능한 모드 목록 (--all 이면 숨은 모드까지)
#   hidpi on [WxH]            논리 해상도 WxH 로 HiDPI 켜기 (기본 $HIDPI_LOGICAL)
#   hidpi off                 네이티브 1x 로 복귀 (가능한 최고 주사율)
#   hidpi toggle              둘 사이를 전환
#
# 옵션:
#   -d, --display <id>        대상 디스플레이 id (기본: 메인 디스플레이)
#       --all                 list 에서 macOS가 pseudo로 표시한 모드까지 출력
#
# 환경변수:
#   HIDPI_LOGICAL             on 의 기본 논리 해상도 (기본값: 1920x1080)
#
# 요구사항: Xcode Command Line Tools (clang). 최초 1회 헬퍼를 컴파일해
# ~/.cache/hidpi 에 캐싱한다.
#
set -euo pipefail

HIDPI_LOGICAL="${HIDPI_LOGICAL:-1920x1080}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hidpi"
HELPER="$CACHE_DIR/hidpi-helper"
SOURCE="$CACHE_DIR/hidpi-helper.c"

die() { printf 'hidpi: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 헬퍼. $CACHE_DIR 에 한 번만 컴파일해서 재사용하고, 아래 소스가 바뀌면 다시 빌드한다.
# ---------------------------------------------------------------------------
write_source() {
	mkdir -p "$CACHE_DIR"
	cat >"$SOURCE" <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>
#include <ApplicationServices/ApplicationServices.h>

/* 비공개 CGSDisplayModeDescription(212바이트)의 레이아웃. 아래 필드만 알려져 있고
   나머지는 건드리지 않는 패딩이다. */
typedef struct {
	uint32_t modeNumber;
	uint32_t flags;
	uint32_t width;
	uint32_t height;
	uint32_t depth;
	uint32_t pad1[42];
	uint16_t pad2;
	uint16_t freq;
	uint32_t pad3[4];
	float    density;
} ModeDesc;

typedef CGError (*NumModesFn)(CGDirectDisplayID, int *);
typedef CGError (*DescFn)(CGDirectDisplayID, int, ModeDesc *, int);
typedef CGError (*CurModeFn)(CGDirectDisplayID, int *);
typedef CGError (*ConfModeFn)(CGDisplayConfigRef, CGDirectDisplayID, int);

static NumModesFn  gNumModes;
static DescFn      gGetDesc;
static CurModeFn   gCurMode;
static ConfModeFn  gConfMode;

static void resolve(void) {
	gNumModes = (NumModesFn) dlsym(RTLD_DEFAULT, "CGSGetNumberOfDisplayModes");
	gGetDesc  = (DescFn)     dlsym(RTLD_DEFAULT, "CGSGetDisplayModeDescriptionOfLength");
	gCurMode  = (CurModeFn)  dlsym(RTLD_DEFAULT, "CGSGetCurrentDisplayMode");
	gConfMode = (ConfModeFn) dlsym(RTLD_DEFAULT, "CGSConfigureDisplayMode");
	if (!gNumModes || !gGetDesc || !gCurMode || !gConfMode) {
		fprintf(stderr, "hidpi-helper: 이 macOS 빌드에서는 비공개 display-mode API를 "
		                "찾을 수 없습니다\n");
		exit(3);
	}
}

/* 모드 한 줄에 하나씩 TSV 출력:
   displayID modeNum w h pxW pxH freq density scale pseudo current isMain */
static int cmd_modes(void) {
	CGDirectDisplayID displays[32];
	uint32_t count = 0;
	if (CGGetOnlineDisplayList(32, displays, &count) != kCGErrorSuccess) return 1;

	CGDirectDisplayID main = CGMainDisplayID();
	for (uint32_t d = 0; d < count; d++) {
		int n = 0, cur = -1;
		if (gNumModes(displays[d], &n) != kCGErrorSuccess) continue;
		gCurMode(displays[d], &cur);
		for (int i = 0; i < n; i++) {
			ModeDesc m;
			memset(&m, 0, sizeof m);
			if (gGetDesc(displays[d], i, &m, (int)sizeof m) != kCGErrorSuccess) continue;
			printf("%u\t%u\t%u\t%u\t%u\t%u\t%u\t%.1f\t%d\t%d\t%d\t%d\n",
			       displays[d], m.modeNumber, m.width, m.height,
			       (uint32_t)(m.width * m.density), (uint32_t)(m.height * m.density),
			       m.freq, m.density,
			       m.density > 1.5f ? 2 : 1,
			       (m.flags & 0x40000000u) ? 1 : 0,
			       (int)m.modeNumber == cur ? 1 : 0,
			       displays[d] == main ? 1 : 0);
		}
	}
	return 0;
}

static int cmd_apply(CGDirectDisplayID display, int modeNum) {
	CGDisplayConfigRef config;
	if (CGBeginDisplayConfiguration(&config) != kCGErrorSuccess) {
		fprintf(stderr, "hidpi-helper: display configuration을 시작하지 못했습니다\n");
		return 1;
	}
	CGError err = gConfMode(config, display, modeNum);
	if (err != kCGErrorSuccess) {
		CGCancelDisplayConfiguration(config);
		fprintf(stderr, "hidpi-helper: 디스플레이 %u 가 모드 %d 를 거부했습니다 (error %d)\n",
		        display, modeNum, err);
		return 1;
	}
	/* Permanently: 시스템 설정에서 바꾼 것과 같이 로그아웃·재부팅 후에도 유지된다. */
	err = CGCompleteDisplayConfiguration(config, kCGConfigurePermanently);
	if (err != kCGErrorSuccess) {
		fprintf(stderr, "hidpi-helper: 모드 적용 실패 (error %d)\n", err);
		return 1;
	}
	return 0;
}

int main(int argc, char **argv) {
	resolve();
	if (argc >= 2 && strcmp(argv[1], "modes") == 0) return cmd_modes();
	if (argc == 4 && strcmp(argv[1], "apply") == 0)
		return cmd_apply((CGDirectDisplayID)strtoul(argv[2], NULL, 10),
		                 (int)strtol(argv[3], NULL, 10));
	fprintf(stderr, "usage: hidpi-helper modes | apply <displayID> <modeNumber>\n");
	return 2;
}
EOF
}

ensure_helper() {
	local want have
	write_source
	want="$(shasum -a 256 "$SOURCE" | cut -d' ' -f1)"
	have="$(cat "$CACHE_DIR/.build-hash" 2>/dev/null || true)"
	if [[ -x $HELPER && $want == "$have" ]]; then
		return
	fi
	command -v clang >/dev/null 2>&1 ||
		die "clang 이 없습니다. Xcode Command Line Tools 를 설치하세요: xcode-select --install"
	printf 'hidpi: 헬퍼 빌드 중 (최초 1회)...\n' >&2
	clang -O2 -o "$HELPER" "$SOURCE" -framework ApplicationServices ||
		die "헬퍼 컴파일 실패"
	printf '%s' "$want" >"$CACHE_DIR/.build-hash"
}

# ---------------------------------------------------------------------------
# 모드 테이블
# ---------------------------------------------------------------------------
# 컬럼: 1 display  2 modeNum  3 w  4 h  5 pxW  6 pxH  7 freq  8 density
#        9 scale  10 pseudo  11 current  12 isMain
modes() { "$HELPER" modes; }

main_display() {
	modes | awk -F'\t' '$12 == 1 { print $1; exit }'
}

# pick <displayID> <scale> [WxH]
# 최고 주사율을 고르고, 같으면 더 작은 모드 번호를 택한다.
# WxH 를 주지 않으면 해당 배율에서 가장 큰 논리 해상도를 고른다.
pick() {
	local display="$1" scale="$2" size="${3:-}" w=0 h=0
	if [[ -n $size ]]; then
		[[ $size =~ ^([0-9]+)x([0-9]+)$ ]] || die "잘못된 해상도 '$size' (WxH 형식, 예: 1920x1080)"
		w="${BASH_REMATCH[1]}"; h="${BASH_REMATCH[2]}"
	fi
	modes | awk -F'\t' -v d="$display" -v s="$scale" -v w="$w" -v h="$h" '
		$1 != d || $9 != s || $10 == 1 { next }
		w > 0 && ($3 != w || $4 != h)  { next }
		{
			area = $3 * $4
			if (area > bestArea ||
			    (area == bestArea && ($7 > bestFreq ||
			                          ($7 == bestFreq && $2 < bestMode)))) {
				bestArea = area; bestFreq = $7; bestMode = $2
				best = $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7
			}
		}
		END { if (best != "") print best }'
}

current_row() {
	modes | awk -F'\t' -v d="$1" '$1 == d && $11 == 1 { print; exit }'
}

describe() {  # stdin 으로 모드 행을 받는다: modeNum w h pxW pxH freq
	awk -F'\t' '{
		if ($4 == $2) printf "%sx%s @ %sHz (네이티브 1x)\n", $2, $3, $6
		else printf "%sx%s HiDPI @ %sHz (%sx%s 프레임버퍼)\n", $2, $3, $6, $4, $5
	}'
}

apply() {  # apply <displayID> <row>
	local display="$1" row="$2"
	[[ -n $row ]] || die "일치하는 모드를 찾지 못했습니다"
	"$HELPER" apply "$display" "$(cut -f1 <<<"$row")"
	printf 'hidpi: display %s -> %s\n' "$display" "$(describe <<<"$row")"
}

# ---------------------------------------------------------------------------
# 커맨드
# ---------------------------------------------------------------------------
cmd_status() {
	local display="$1" row
	row="$(current_row "$display")"
	[[ -n $row ]] || die "디스플레이 $display 의 현재 모드를 읽지 못했습니다"
	printf 'display %s: ' "$display"
	cut -f2-7 <<<"$row" | describe
	# HiDPI 면 exit 0, 아니면 1 — 다른 스크립트에서 조건문으로 쓰기 위함
	[[ $(cut -f9 <<<"$row") == 2 ]]
}

cmd_list() {
	local display="$1" all="$2"
	printf '%-9s %-13s %-13s %-7s %-6s %s\n' MODE LOGICAL FRAMEBUFFER REFRESH SCALE ''
	modes | awk -F'\t' -v d="$display" -v all="$all" '
		$1 != d { next }
		$10 == 1 && all != "1" { next }
		{
			printf "%-9s %-13s %-13s %-7s %-6s %s\n", \
			       $2, $3 "x" $4, $5 "x" $6, $7 "Hz", $9 "x", \
			       ($11 == 1 ? "<- current" : "")
		}'
}

cmd_on() {
	local display="$1" size="${2:-$HIDPI_LOGICAL}" row
	row="$(pick "$display" 2 "$size")"
	[[ -n $row ]] || die "디스플레이 $display 에 ${size} HiDPI 모드가 없습니다 — hidpi list 로 확인하세요"
	apply "$display" "$row"
}

cmd_off() {
	local display="$1" row
	row="$(pick "$display" 1)"
	[[ -n $row ]] || die "디스플레이 $display 에 1x 모드가 없습니다"
	apply "$display" "$row"
}

cmd_toggle() {
	local display="$1" row
	row="$(current_row "$display")"
	if [[ -n $row && $(cut -f9 <<<"$row") == 2 ]]; then
		cmd_off "$display"
	else
		cmd_on "$display"
	fi
}

usage() {
	awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; started = 1; next } started { exit }' "$0"
}

main() {
	local display="" all=0 args=()
	while (($#)); do
		case "$1" in
			-d|--display) display="${2:?-d 뒤에 디스플레이 id 가 필요합니다}"; shift 2 ;;
			--all)        all=1; shift ;;
			-h|--help)    usage; exit 0 ;;
			--)           shift; args+=("$@"); break ;;
			-*)           die "알 수 없는 옵션 '$1'" ;;
			*)            args+=("$1"); shift ;;
		esac
	done

	ensure_helper
	[[ -n $display ]] || display="$(main_display)"
	[[ -n $display ]] || die "온라인 상태인 디스플레이가 없습니다"

	case "${args[0]:-status}" in
		status) cmd_status "$display" ;;
		list)   cmd_list "$display" "$all" ;;
		on)     cmd_on "$display" "${args[1]:-$HIDPI_LOGICAL}" ;;
		off)    cmd_off "$display" ;;
		toggle) cmd_toggle "$display" ;;
		help)   usage ;;
		*)      die "알 수 없는 커맨드 '${args[0]}' (hidpi help 참고)" ;;
	esac
}

main "$@"
