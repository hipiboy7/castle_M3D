#!/usr/bin/env bash
# 에뮬레이터 점검 (CI emulator 잡이 부른다): APK 설치 → 실행 → 첫 화면 · 데모 스크린샷 → logcat 에 충돌 · 스크립트 오류가 없는지
# 입력: apk/castle_m3d.apk   출력: emu/*.png · emu/logcat.txt · emu/fps.txt
# 첫 화면에서 6초(게임 시간) 동안 아무것도 안 누르면 데모(봇 대 백도찬)가 돈다 — 터치 없이도 결투 화면을 찍을 수 있다.
# 소프트웨어 GPU 에뮬레이터는 느려서 게임 시간이 늦게 간다 → logcat 의 "MODE demo"(main.gd)를 기다린 뒤 찍는다.
set -u
PKG=com.hipiboy7.castlem3d
mkdir -p emu
adb install -r apk/castle_m3d.apk || { echo "설치 실패"; exit 1; }
adb shell settings put secure immersive_mode_confirmations confirmed   # 전체 화면 안내 창이 스크린샷을 가린다(castle_M android_smoke.sh 와 같게)
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null
sleep 12
adb exec-out screencap -p > emu/emu_1_title.png
waited=0
while [ $waited -lt 150 ] && ! adb logcat -d | grep -q "MODE demo"; do sleep 3; waited=$((waited + 3)); done
echo "데모 시작까지 실행 뒤 약 $((12 + waited))초"
sleep 10
adb exec-out screencap -p > emu/emu_2_demo.png
sleep 15
adb exec-out screencap -p > emu/emu_3_demo.png
sleep 15
adb exec-out screencap -p > emu/emu_4_demo.png
adb logcat -d > emu/logcat.txt
grep -E "FPS_LOG|MODE " emu/logcat.txt | sed -E 's/.*(FPS_LOG|MODE )/\1/' > emu/fps.txt || true
grep -iE "OpenGL API|Using Device|renderer" emu/logcat.txt | head -5 >> emu/fps.txt || true
echo "--- FPS (main.gd 가 실제 시간 10초마다 찍는다) · 렌더러 ---"
cat emu/fps.txt
if grep -E "Program linking failed" emu/logcat.txt | head -3 | grep .; then
  echo "3D 셰이더 링크 실패 — 화면이 안 그려진다 (docs/트러블슈팅.md T-4)"
  exit 1
fi
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
