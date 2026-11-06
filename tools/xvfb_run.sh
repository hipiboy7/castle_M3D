#!/usr/bin/env bash
# 가상 화면(Xvfb + Mesa llvmpipe)을 띄우고 그 위에서 명령 하나를 돌린다 — 창이 있어야 그리는 도구(tools/make_sprites.gd)용.
#   tools/xvfb_run.sh <명령> [인자..]       예) tools/xvfb_run.sh .tools/godot/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64 --path . -s res://tools/make_sprites.gd
# 준비 · 원리는 tools/xvfb_shot.sh 머리와 같다(docs/트러블슈팅.md T-8).
set -u
R=${XVFB_ROOT:-$HOME/.local-opt/xvfb/root}
OV=$(dirname "$R")/bin_overlay
W=${SHOT_W:-1280}; H=${SHOT_H:-720}
DISP=:$(( 90 + RANDOM % 9 ))
mkdir -p "$OV"
[ -x "$OV/xkbcomp" ] || cp "$R/usr/bin/xkbcomp" "$OV/"
[ -x "$OV/sh" ] || cp /usr/bin/bash "$OV/sh"
LD_LIBRARY_PATH="$R/usr/lib64" unshare -rm sh -c "mount --bind '$OV' /usr/bin && exec '$R/usr/bin/Xvfb' $DISP -screen 0 ${W}x${H}x24 -xkbdir '$R/usr/share/X11/xkb' -nolisten tcp" >/dev/null 2>&1 &
XPID=$!
trap 'kill $XPID 2>/dev/null' EXIT
for _ in $(seq 50); do [ -S /tmp/.X11-unix/X${DISP#:} ] && break; sleep 0.1; done
DISPLAY=$DISP LD_LIBRARY_PATH="$R/usr/lib64" LIBGL_DRIVERS_PATH="$R/usr/lib64/dri" \
  __EGL_VENDOR_LIBRARY_DIRS="$R/usr/share/glvnd/egl_vendor.d" "$@"
