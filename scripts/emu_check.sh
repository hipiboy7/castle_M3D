#!/usr/bin/env bash
# 에뮬레이터 점검 (CI emulator 잡이 부른다): APK 설치 → 실행 → 첫 화면 · 데모 스크린샷 → logcat 에 충돌 · 스크립트 오류가 없는지
# 입력: apk/castle_m3d.apk   출력: emu/*.png · emu/logcat.txt · emu/fps.txt
# 첫 화면에서 6초 동안 아무것도 안 누르면 데모(봇 대 백도찬)가 돈다 — 터치 없이도 결투 화면을 찍을 수 있다.
set -u
PKG=com.hipiboy7.castlem3d
mkdir -p emu
adb install -r apk/castle_m3d.apk || { echo "설치 실패"; exit 1; }
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null
sleep 10
adb exec-out screencap -p > emu/emu_1_title.png
sleep 16
adb exec-out screencap -p > emu/emu_2_demo.png
sleep 14
adb exec-out screencap -p > emu/emu_3_demo.png
sleep 20
adb exec-out screencap -p > emu/emu_4_demo.png
adb logcat -d > emu/logcat.txt
grep -E "FPS_LOG" emu/logcat.txt | sed 's/.*FPS_LOG/FPS_LOG/' > emu/fps.txt || true
echo "--- FPS (main.gd 가 10초마다 찍는다) ---"
cat emu/fps.txt
pid=$(adb shell pidof "$PKG" | tr -d '\r')
if grep -E "FATAL EXCEPTION|SCRIPT ERROR|USER SCRIPT ERROR" emu/logcat.txt; then
  echo "logcat 에 오류가 있다"
  exit 1
fi
if [ -z "$pid" ]; then
  echo "앱이 살아 있지 않다 (죽었다)"
  grep -iE "godot|AndroidRuntime" emu/logcat.txt | tail -40
  exit 1
fi
echo "OK — 앱이 살아 있음 (pid $pid)"
