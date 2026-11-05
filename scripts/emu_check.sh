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
# 가로 고정 앱을 세로 홈에서 띄우면 느린 에뮬레이터에서는 시작 도중 화면이 돌며 액티비티가 다시 만들어지고
# Godot 가 "Force quitting Godot instance" 로 스스로 끝난다(run #5, T-6) → 먼저 가로로 돌려 두고 띄운다
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 1
sleep 5
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null
# 가로 고정 뒤에도 시작 중 액티비티가 다시 만들어지면 Godot 가 "Force quitting" 으로 끝나는 일이 있다(run #13, T-7 —
# 띄운 뒤 약 28초에 죽었다). 게임이 돌기 시작했다는 표시(main.gd 가 실제 시간 10초마다 찍는 FPS_LOG)가 뜨거나 앱이
# 죽을 때까지 최대 90초 기다리고, 죽었으면 한 번만 더 띄운다 — 두 번째 실행은 엔진이 새로 뜬다.
# 첫 시도 logcat 은 emu/logcat_try1.txt 로 남기고, 판정(아래 — 오류 · 셰이더 · 살아 있는지)은 두 번째 실행 기준이다.
# 두 번째도 죽으면 그대로 실패한다
sleep 5
up=5
while [ $up -lt 90 ] && [ -n "$(adb shell pidof "$PKG" | tr -d '\r')" ] && ! adb logcat -d | grep -q "FPS_LOG"; do
  sleep 3; up=$((up + 3))
done
if [ -z "$(adb shell pidof "$PKG" | tr -d '\r')" ]; then
  adb logcat -d > emu/logcat_try1.txt
  echo "첫 실행에서 앱이 죽었다(띄운 뒤 약 ${up}초) — 한 번 더 띄운다 (T-7)"
  grep -E "Force quitting|Engine already initialized|finishDrawing of relaunch" emu/logcat_try1.txt | head -5 || true
  adb logcat -c
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null
  up=0
else
  echo "첫 실행 — 띄운 뒤 약 ${up}초까지 살아 있음"
fi
sleep 12
adb exec-out screencap -p > emu/emu_1_title.png
waited=0
while [ $waited -lt 150 ] && ! adb logcat -d | grep -q "MODE demo"; do sleep 3; waited=$((waited + 3)); done
echo "데모 시작까지 (마지막) 실행 뒤 약 $((up + 12 + waited))초"
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
