"""전체 검증 (창 없음) — 이 명령이 0 으로 끝나야 커밋 · push 한다.

    py -3.12 scripts/verify.py            # 약 20초
    GODOT=/path/to/godot python3 scripts/verify.py   # CI(리눅스) — Godot 실행 파일을 환경 변수로

단계:
  1. 가져오기   godot --headless --path . --import  (스크립트 문법 · 자원 가져오기)
  2. 테스트     godot --headless --path . -s res://tests/run_tests.gd  (전투 규칙 — tests/test_combat.gd)
  3. 자동 결투  godot --headless --fixed-fps 60 --path . -- --autoplay --seconds 90 --seed S  (시드 1 · 2 · 3,
               게임 전체 — 무대 · 인형 · 연출 · 화면 표시까지 돌려 멈춤 · 스크립트 오류가 없는지)
출력에 SCRIPT ERROR · ERROR: · WARNING: · Leaked 가 하나라도 있으면 실패.
"""
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
import get_godot  # noqa: E402

BAD = re.compile(r"SCRIPT ERROR|^ERROR:|^WARNING:|Leaked|Parse Error", re.M)


def godot():
    exe = os.environ.get("GODOT")
    if exe:
        return exe
    if get_godot.main() != 0:
        sys.exit("Godot 를 받지 못했다")
    return get_godot.EXE


def run(name, cmd, check_out=None, timeout=600):
    t0 = time.time()
    p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace",
                       timeout=timeout)
    out = (p.stdout or "") + (p.stderr or "")
    dt = time.time() - t0
    bad = BAD.findall(out)
    msg = ""
    ok = p.returncode == 0 and not bad
    if check_out is not None:
        good, msg = check_out(out)
        ok = ok and good
    print(f"[{'ok' if ok else 'FAIL'}] {name} ({dt:.1f}s){' — ' + msg if msg else ''}")
    if not ok:
        print("\n".join("     " + ln for ln in out.strip().splitlines()[-25:]))
    return ok


def main():
    g = godot()
    t0 = time.time()
    results = []
    if not os.path.isdir(os.path.join(ROOT, ".godot", "imported")):
        # 새로 받은 저장소(CI): 첫 가져오기는 프로젝트 글꼴을 가져오기 전에 읽으려 해 ERROR 를 낸다(run #1) — 한 번 돌리고 다시 본다
        p = subprocess.run([g, "--headless", "--path", ".", "--import"], cwd=ROOT, capture_output=True, timeout=600)
        print(f"[..] 첫 가져오기 (종료 코드 {p.returncode}, 출력은 다음 가져오기에서 본다)")
    results.append(run("가져오기", [g, "--headless", "--path", ".", "--import"]))

    def tests_ok(out):
        m = re.search(r"tests: (\d+) passed, (\d+) failed", out)
        return (m is not None and m.group(2) == "0"), (m.group(0) if m else "결과 줄 없음")
    results.append(run("테스트", [g, "--headless", "--path", ".", "-s", "res://tests/run_tests.gd"], tests_ok))
    for seed in (1, 2, 3):
        def auto_ok(out):
            m = re.search(r"^RESULT (.*)$", out, re.M)
            return m is not None, (m.group(1)[:150] if m else "RESULT 줄 없음")
        results.append(run(f"자동 결투 seed {seed} · 90초",
                           [g, "--headless", "--fixed-fps", "60", "--path", ".", "--", "--autoplay", "--seconds", "90",
                            "--seed", str(seed)], auto_ok))
    n_ok = sum(results)
    print(f"verify: {n_ok}/{len(results)} 통과 · {time.time() - t0:.0f}초 — {'OK' if n_ok == len(results) else 'FAIL'}")
    return 0 if n_ok == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
