#!/usr/bin/env bash
# 작업 서버(리눅스, root 없음)에서 가상 화면(Xvfb + Mesa llvmpipe)으로 게임을 띄워 스크린샷을 찍는다 — CI '화면 찍기'와 같은 인자.
#
#   tools/xvfb_shot.sh 출력폴더 [프레임목록] [초] [시드] [추가 게임 인자..]
#   tools/xvfb_shot.sh /tmp/shots 300,420,900 20 2
#   AUTOPLAY= tools/xvfb_shot.sh /tmp/shots 280,330 8 1 --events 30:press,300:pause --safe 90,0,0,40   # 사람 판 · 멈춤 · 여백
#
# 준비(한 번): Xvfb · Mesa 를 RPM 으로 받아 사용자 폴더에 푼다(sudo 없음) — docs/트러블슈팅.md T-리눅스.
#   XVFB_ROOT(기본 ~/.local-opt/xvfb/root) 에 usr/bin/Xvfb · usr/lib64(mesa · libGL · X 라이브러리) · usr/share/X11/xkb
#   Xvfb 는 /usr/bin/xkbcomp 를 고정 경로로 부른다 → 사용자 이름공간(unshare -rm)에서 /usr/bin 위에 xkbcomp · sh 만 든
#   폴더(XVFB_ROOT/../bin_overlay)를 덮어 띄운다. 게임(Godot)은 바깥에서 그 화면(DISPLAY)에 붙는다.
set -u
OUT=${1:?출력폴더}
FRAMES=${2:-300,420,900}
SECS=${3:-20}
SEED=${4:-2}
shift $(( $# < 4 ? $# : 4 ))
HERE=$(cd "$(dirname "$0")/.." && pwd)
R=${XVFB_ROOT:-$HOME/.local-opt/xvfb/root}
OV=$(dirname "$R")/bin_overlay
GODOT=${GODOT:-$(python3.11 "$HERE/scripts/get_godot.py")}
W=${SHOT_W:-2340}; H=${SHOT_H:-1080}
DISP=:$(( 70 + RANDOM % 20 ))
mkdir -p "$OUT" "$OV"
[ -x "$OV/xkbcomp" ] || cp "$R/usr/bin/xkbcomp" "$OV/"
[ -x "$OV/sh" ] || cp /usr/bin/bash "$OV/sh"
export LD_LIBRARY_PATH="$R/usr/lib64"
unshare -rm sh -c "mount --bind '$OV' /usr/bin && exec '$R/usr/bin/Xvfb' $DISP -screen 0 ${W}x${H}x24 -xkbdir '$R/usr/share/X11/xkb' -nolisten tcp" >/dev/null 2>&1 &
XPID=$!
trap 'kill $XPID 2>/dev/null' EXIT
for _ in $(seq 50); do [ -S /tmp/.X11-unix/X${DISP#:} ] && break; sleep 0.1; done
DISPLAY=$DISP LIBGL_DRIVERS_PATH="$R/usr/lib64/dri" __EGL_VENDOR_LIBRARY_DIRS="$R/usr/share/glvnd/egl_vendor.d" \
  timeout 600 "$GODOT" --path "$HERE" --rendering-driver opengl3 --audio-driver Dummy --resolution ${W}x${H} --fixed-fps 60 \
  -- ${AUTOPLAY---autoplay} --touch --seed "$SEED" --seconds "$SECS" --shots "$OUT:$FRAMES" "$@" 2>&1 | grep -vE "^\s*$|V-Sync|set_use_vsync"
ls "$OUT"
