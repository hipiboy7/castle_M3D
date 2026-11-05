"""전체 검증 (창 없음) — 이 명령이 0 으로 끝나야 커밋 · push 한다.

    py -3.12 scripts/verify.py            # 약 20초
    py -3.12 scripts/verify.py --strict   # castle_common 이 앞서 있으면 실패 (마일스톤 끝 · 태그 전)
    GODOT=/path/to/godot python3 scripts/verify.py   # CI(리눅스) — Godot 실행 파일을 환경 변수로

단계:
  0. 공통 데이터  data/common/ 의 받은 파일이 도장 SOURCE.json 의 sha256(줄 끝 CRLF → LF)과 같다(손으로 고치지 않았다 —
               다르면 실패). 옆에 castle_common(환경 변수 CASTLE_COMMON, 없으면 이 저장소 옆 폴더)이 있으면 그 파일과
               같은지 — 다르면 알림(--strict 는 실패), 없으면(CI) 건너뛴다. castle_M scripts/verify.py 3-1 과 같은 방식
  0. 자산 출처    assets/ 의 파일(.import 빼고)이 모두 assets/ASSETS.md 에 있고, 목록에만 있는 파일이 없다(개발 규격 6절)
  1. 가져오기   godot --headless --path . --import  (스크립트 문법 · 자원 가져오기)
  2. 테스트     godot --headless --path . -s res://tests/run_tests.gd  (전투 규칙 — tests/test_combat.gd)
  3. 자동 결투  godot --headless --fixed-fps 60 --path . -- --autoplay --seconds 90 --seed S  (시드 1 · 2 · 3,
               게임 전체 — 무대 · 인형 · 연출 · 화면 표시까지 돌려 멈춤 · 스크립트 오류가 없는지)
출력에 SCRIPT ERROR · ERROR: · WARNING: · Leaked 가 하나라도 있으면 실패.
"""
import glob
import hashlib
import json
import os
import re
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts"))
import get_godot  # noqa: E402

COMMON_DIR = os.path.join(ROOT, "data", "common")
COMMON_SRC = os.environ.get("CASTLE_COMMON") or os.path.join(os.path.dirname(ROOT), "castle_common")
ASSETS = os.path.join(ROOT, "assets")
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


def _digest(path):
    """sha256 — 줄 끝 CRLF 를 LF 로 바꾼 내용으로 (castle_common tools/sync.py 와 같은 방법)."""
    with open(path, "rb") as f:
        return hashlib.sha256(f.read().replace(b"\r\n", b"\n")).hexdigest()


def _src_path(rel):
    """받은 파일의 castle_common 쪽 경로 — data/ 의 것은 받는 폴더 바로 아래로 왔다(sync.py sources)."""
    return os.path.join(COMMON_SRC, *(rel.split("/") if "/" in rel else ["data", rel]))


def step_common(strict):
    t0 = time.time()
    stamp_path = os.path.join(COMMON_DIR, "SOURCE.json")
    if not os.path.exists(stamp_path):
        print("[FAIL] 공통 데이터 — data/common/SOURCE.json 이 없다: py -3.12 ../castle_common/tools/sync.py castle_M3D")
        return False
    with open(stamp_path, encoding="utf-8") as f:
        stamp = json.load(f)
    want = stamp["files"]
    have = {}
    for p in glob.glob(os.path.join(COMMON_DIR, "**", "*"), recursive=True):
        rel = os.path.relpath(p, COMMON_DIR).replace(os.sep, "/")
        if os.path.isfile(p) and rel != "SOURCE.json":
            have[rel] = _digest(p)
    edited = sorted(k for k in set(want) | set(have) if want.get(k) != have.get(k))
    if edited:
        print("[FAIL] 공통 데이터 — 도장과 다른 파일(손으로 고치지 않는다 — castle_common 에서 고치고 받는다): " + ", ".join(edited))
        return False
    ok, msg = True, f"castle_common {stamp['castle_common'][:7]} 받음 · 파일 {len(want)}개 도장과 같다"
    if os.path.isdir(os.path.join(COMMON_SRC, "data")):
        up = {rel: (_digest(_src_path(rel)) if os.path.isfile(_src_path(rel)) else None) for rel in want}
        for pat, pre in (("data/*.json", ""), ("cases/*.json", "cases/"), ("docs/개발규격/*.md", "docs/개발규격/")):
            for p in glob.glob(os.path.join(COMMON_SRC, *pat.split("/"))):
                up.setdefault(pre + os.path.basename(p), _digest(p))
        behind = sorted(k for k in up if up[k] != want.get(k))
        if behind:
            ok = not strict
            msg += (f" · {'[실패]' if strict else '[알림]'} castle_common 이 앞섰다({', '.join(behind)}) — "
                    "py -3.12 ../castle_common/tools/sync.py castle_M3D 로 받고 테스트")
        else:
            msg += " · castle_common 과 같다"
    else:
        msg += " · castle_common 폴더 없음 — 비교 건너뜀"
    print(f"[{'ok' if ok else 'FAIL'}] 공통 데이터 ({time.time() - t0:.1f}s) — {msg}")
    return ok


def step_assets():
    path = os.path.join(ASSETS, "ASSETS.md")
    if not os.path.exists(path):
        print("[FAIL] 자산 출처 — assets/ASSETS.md 가 없다")
        return False
    with open(path, encoding="utf-8") as f:
        listed = set(re.findall(r"^\|\s*`([^`]+)`", f.read(), re.M))
    files = set()
    for p in glob.glob(os.path.join(ASSETS, "**", "*"), recursive=True):
        rel = os.path.relpath(p, ASSETS).replace(os.sep, "/")
        if os.path.isfile(p) and not rel.endswith(".import") and rel != "ASSETS.md":
            files.add(rel)
    missing, stale = sorted(files - listed), sorted(listed - files)
    ok = not missing and not stale
    msg = f"파일 {len(files)}개 출처 있음" if ok else (
        (f"출처 없는 파일: {', '.join(missing)}" if missing else "") + (f" · 목록에만 있음: {', '.join(stale)}" if stale else ""))
    print(f"[{'ok' if ok else 'FAIL'}] 자산 출처 — {msg}")
    return ok


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")      # 윈도우 콘솔(cp1252)에서 한글 출력에 죽지 않게
    except (AttributeError, ValueError):
        pass
    strict = "--strict" in sys.argv[1:]
    g = godot()
    t0 = time.time()
    results = [step_common(strict), step_assets()]
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
