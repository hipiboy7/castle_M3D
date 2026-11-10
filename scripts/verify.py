"""전체 검증 (창 없음) — 이 명령이 0 으로 끝나야 커밋 · push 한다.

    python3.11 scripts/verify.py            # 약 20초 (Windows: py -3.12)
    python3.11 scripts/verify.py --strict   # castle_common 이 앞서 있으면 실패 (마일스톤 끝 · 태그 전)
    GODOT=/path/to/godot python3 scripts/verify.py   # CI(리눅스) — Godot 실행 파일을 환경 변수로

단계:
  0. 공통 데이터  data/common/ 의 받은 파일이 도장 SOURCE.json 의 sha256(줄 끝 CRLF → LF)과 같다(손으로 고치지 않았다 —
               다르면 실패). 옆에 castle_common(환경 변수 CASTLE_COMMON, 없으면 이 저장소 옆 폴더)이 있으면 그 파일과
               같은지 — 다르면 알림(--strict 는 실패), 없으면(CI) 건너뛴다. castle_M scripts/verify.py 3-1 과 같은 방식
  0. 자산 출처    assets/ 의 파일(.import 빼고)이 모두 assets/ASSETS.md 에 있고, 목록에만 있는 파일이 없다(개발 규격 6절)
  0-1. 외형 생성물  tools/looks_from_common.py --check (castle_common looks.json → src/view/looks_common.gd)
  1. 가져오기   godot --headless --path . --import  (스크립트 문법 · 자원 가져오기)
  2. 테스트     godot --headless --path . -s res://tests/run_tests.gd  (tests/unit · tests/integration)
  2. 커버리지   함수 단위 — .tools/cov/ 에 src · tests · data 사본을 만들고 A · B 등급 파일의 함수 머리마다 표시 줄을 넣어
               테스트를 다시 돌린다(이 저장소 소스는 그대로). A ≥ 90% · B ≥ 70%(CLAUDE.md 2-1절) — 모자라면 실패
  3. 자동 결투  godot --headless --fixed-fps 60 --path . -- --autoplay --seconds 90 --seed S  (시드 1 · 2 · 3,
               게임 전체 — 무대 · 인형 · 연출 · 화면 표시까지 돌려 멈춤 · 스크립트 오류가 없는지)
  3. 11장 자동 판  같은 명령에 --mode stage (시드 1 · 2, 150초 — 첫 방 지하주차장: 버티기 · 무리 triggers · 아군 11 · 지키기)
  3. 0 · 1장 자동 판  --mode ch0 (120초 — 프롤로그를 봇이 한 번은 깬다) · --mode ch1 (360초 — 회암시 5방 · 1인 판 · 아군 서진태 · 김대건 합류)
               · --mode ch2 (300초 — 하성 본사 8방 · 방마다 조작 인물 김신 / 서진태 · 따돌리기 방 둘)
  3. 리플레이    11장 seed 2 판의 입력 기록(--save-replay .tools/replay_stage2.json)을 다른 프로세스에서 --replay 로 다시 돌려
               끝 · 중간 해시(60프레임마다)가 같은지(src/combat/replay.gd — 결정성 · 멀티 ④ 바탕)
  3. 그림 A · B   --art a · b(GLB 툰 모델 · 도트 빌보드)로 11장 신겐 방 · 1장 윤덕수 방 · 2장 로비 · 위층 · 폐차장(하성 무대 · 서진태 조작 · 따돌리기) 20초 · 성능 판 --crowd 30 20초 — 오류 없이 도는지
  4. 세이브     --save .tools/save_check.json 으로 처음 화면 그림 버튼(--events 60:art) → 파일 art=b → 다음 실행이 그것을 읽는다
  4. 흐름       ⓪ 게임 속도 ×1.5(--events 1:speed)도 ×1 과 같은 판(로직 프레임 열이 같다 — 1초에 도는 수만 다름)
               ① 일시정지 앞뒤가 같은 판 — seed 1 40초 와 42초 + 600 프레임에 2초 멈춤(--events 600:pause,720:resume)의 결과가 같다
               ③ 싸움 중 메뉴(스테이지 고르기) — 6장 싸움 → 메뉴 → 11장 → 넷째 스테이지(회장실 앞)에서 시작 → 메뉴 → 계속
               ② 뒤로 버튼 · 앱 내려감 — 처음 화면 → 데모 → 뒤로 → 처음 → 누름 → 결투 → 내려감(멈춤) → 누름(계속) → 뒤로(멈춤) →
               뒤로(처음 화면) 순서가 --trace 줄에 나온다 (src/ui/nav.gd · main.gd _back · _app_hidden)
               ④ 장 차례 — 새 세이브에서 이어하기로 0 ~ 13장을 깬다(--events autowin) → 장이 차례대로 열리고 세이브에 모두 깸
               ⑤ 중간 스테이지 깸 — 7장까지 깬 세이브 → 8장 → 메뉴로 셋째 스테이지 → 깸 → 이어하기 9장
출력에 SCRIPT ERROR · ERROR: · WARNING: · Leaked 가 하나라도 있으면 실패.
"""
import fnmatch
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
# CLAUDE.md 2-1절 TDD 등급 — 함수 단위 커버리지를 재는 파일 (main.gd 흐름은 노드가 있어 자동 결투 단계가 본다)
COV_FILES = {
    "A": ["src/data/common.gd", "src/data/skills.gd", "src/data/moves.gd", "src/data/addendum.gd", "src/data/lines.gd", "src/combat/world.gd", "src/combat/fighter.gd", "src/combat/fighter_body.gd", "src/combat/replay.gd",
          "src/data/campaign.gd", "src/data/save.gd", "src/data/skill_kit.gd"],
    "B": ["src/combat/duel.gd", "src/combat/boss_ai.gd", "src/combat/bot.gd", "src/combat/stage.gd", "src/combat/enemy_ai.gd"],
}
REPLAY_FILE = ".tools/replay_stage2.json"
COV_MIN = {"A": 0.90, "B": 0.70}
FUNC_RE = re.compile(r"^(\s*)(?:static\s+)?func\s+(\w+)\s*\(")
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
    try:
        p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace",
                           stdin=subprocess.DEVNULL, timeout=timeout)
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or b"").decode("utf-8", "replace") if isinstance(e.stdout, bytes) else (e.stdout or "")
        print(f"[FAIL] {name} — {timeout}초 안에 끝나지 않았다\n" + "\n".join("     " + ln for ln in out.strip().splitlines()[-25:]))
        return False
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
        print("[FAIL] 공통 데이터 — data/common/SOURCE.json 이 없다: python3.11 ../castle_common/tools/sync.py castle_M3D")
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
                    "python3.11 ../castle_common/tools/sync.py castle_M3D 로 받고 테스트")
        else:
            msg += " · castle_common 과 같다"
    else:
        msg += " · castle_common 폴더 없음 — 비교 건너뜀"
    print(f"[{'ok' if ok else 'FAIL'}] 공통 데이터 ({time.time() - t0:.1f}s) — {msg}")
    return ok


def step_looks():
    """원작 대조 겉모습 생성물(src/view/looks_common.gd)이 받은 data/common/looks.json · looks.gd 와 맞는지 (castle_common 73차 · 답58)."""
    t0 = time.time()
    p = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "looks_from_common.py"), "--check"], cwd=ROOT,
                       capture_output=True, text=True, timeout=60)
    ok = p.returncode == 0
    print(f"[{'ok' if ok else 'FAIL'}] 외형 생성물 ({time.time() - t0:.1f}s) — {(p.stdout + p.stderr).strip()}")
    return ok


def step_techniques():
    """원작 기술 표(data/story/techniques.json — 인물 기술 묶음 src/data/skill_kit.gd 가 읽는다)가 받은 canon 과 맞는지"""
    t0 = time.time()
    p = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "bake_techniques.py"), "--check"], cwd=ROOT,
                       capture_output=True, text=True, timeout=60)
    ok = p.returncode == 0
    print(f"[{'ok' if ok else 'FAIL'}] 원작 기술 표 ({time.time() - t0:.1f}s) — {(p.stdout + p.stderr).strip()}")
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
    # 줄 첫 칸에 * 가 있으면 무리 줄(명부 그림 roster/models/*_a.glb 처럼 같은 도구가 만든 파일 여럿 — 2026-11-06 전인물 외형)
    pats = {x for x in listed if "*" in x}
    hit = {x for x in files for q in pats if fnmatch.fnmatchcase(x, q)}
    missing = sorted(files - listed - hit)
    stale = sorted((listed - pats - files) | {q for q in pats if not any(fnmatch.fnmatchcase(x, q) for x in files)})
    ok = not missing and not stale
    msg = f"파일 {len(files)}개 출처 있음" if ok else (
        (f"출처 없는 파일: {', '.join(missing)}" if missing else "") + (f" · 목록에만 있음: {', '.join(stale)}" if stale else ""))
    print(f"[{'ok' if ok else 'FAIL'}] 자산 출처 — {msg}")
    return ok


def _instrument(text, rel):
    """함수마다 몸 첫 줄 앞에 커버리지 표시 줄을 넣는다. 돌려주는 값: (새 글, 함수 이름 목록)."""
    lines = text.split("\n")
    out, names, i = [], [], 0
    while i < len(lines):
        m = FUNC_RE.match(lines[i])
        if not m:
            out.append(lines[i])
            i += 1
            continue
        names.append(m.group(2))
        depth = 0
        while True:                                   # 여러 줄 머리: 괄호가 닫히고 ':' 로 끝나는 줄까지
            ln = lines[i]
            out.append(ln)
            depth += ln.count("(") - ln.count(")")
            i += 1
            if depth <= 0 and ln.rstrip().endswith(":"):
                break
        j = i
        while j < len(lines) and (not lines[j].strip() or lines[j].lstrip().startswith("#")):
            j += 1
        indent = re.match(r"^(\s*)", lines[j]).group(1) if j < len(lines) else "\t"
        out.append(f'{indent}if Engine.has_meta("cov"): Engine.get_meta("cov")["{rel}:{m.group(2)}"] = 1')
    return "\n".join(out), names


def step_coverage(g):
    import shutil
    t0 = time.time()
    dst = os.path.join(ROOT, ".tools", "cov")
    shutil.rmtree(dst, ignore_errors=True)
    os.makedirs(dst)
    shutil.copy(os.path.join(ROOT, "project.godot"), dst)
    for d in ("src", "tests", "data"):
        shutil.copytree(os.path.join(ROOT, d), os.path.join(dst, d))
    funcs = {}
    for grade, files in COV_FILES.items():
        for rel in files:
            with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
                text, names = _instrument(f.read(), rel)
            with open(os.path.join(dst, rel), "w", encoding="utf-8") as f:
                f.write(text)
            funcs[rel] = (grade, names)
    out_json = os.path.join(dst, "cov.json")
    p = subprocess.run([g, "--headless", "--path", dst, "-s", "res://tests/run_tests.gd", "--", "--cov", out_json],
                       capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=600, stdin=subprocess.DEVNULL)
    if not os.path.exists(out_json):
        print(f"[FAIL] 커버리지 — 결과 파일이 없다\n" + "\n".join("     " + ln for ln in (p.stdout + p.stderr).splitlines()[-15:]))
        return False
    with open(out_json, encoding="utf-8") as f:
        hit = set(json.load(f))
    ok, parts, missed = True, [], []
    for grade in COV_FILES:
        tot = sum(len(funcs[r][1]) for r in COV_FILES[grade])
        got = sum(1 for r in COV_FILES[grade] for n in funcs[r][1] if f"{r}:{n}" in hit)
        k = got / tot if tot else 1.0
        ok = ok and k >= COV_MIN[grade]
        parts.append(f"{grade} {got}/{tot} {k:.0%} (기준 {COV_MIN[grade]:.0%})")
        missed += [f"{os.path.basename(r)}:{n}" for r in COV_FILES[grade] for n in funcs[r][1] if f"{r}:{n}" not in hit]
    msg = " · ".join(parts) + (f" · 안 불린 함수: {', '.join(missed)}" if missed else "")
    print(f"[{'ok' if ok else 'FAIL'}] 커버리지 ({time.time() - t0:.1f}s) — {msg}")
    return ok


FLOW_EVENTS = "400:back,500:press,700:hide,760:show,800:press,900:back,960:back"
MENU_EVENTS = "30:press,120:menu,150:menupick_ch11,180:menupick_room4,400:menu,430:menupick_resume"   # 11장 다섯째 방 = 71층 회장실 앞(hotel.gd ROOMS)
MENU_WANT = ["STAGE ch0 room=0", "MODE title", "STAGE ch0 room=0", "MODE fight", "MENU on", "MENU off", "STAGE ch11 room=4",
             "MODE fight", "MENU on", "MENU off"]
CHAIN_EVENTS = "1:autowin," + ",".join(f"{i * 150}:press" for i in range(1, 360))   # 900초(2026-11-10 — 7 · 9장 관전 · 대화 방이 늘어 600초를 넘었다)
MID_EVENTS = "30:press,120:menu,150:menupick_room2,200:autowin,1000:press,1300:press"
FLOW_WANT = ["MODE title", "MODE demo", "MODE title", "MODE fight", "PAUSE on", "PAUSE off", "PAUSE on", "PAUSE off", "MODE title"]


def playable_ids():
    """할 수 있는 장 id(차례대로) — campaign.gd CHAPTERS 에서 읽는다(준비 중 soon 빼고)"""
    with open(os.path.join(ROOT, "src", "data", "campaign.gd"), encoding="utf-8") as f:
        return re.findall(r'\{"id": "(\w+)", "no": \d+, "kind": "(?:duel|stage)"', f.read())


def save_file(name, ids, last=""):
    """ids 를 깬 세이브(.tools/<name>) — 없던 파일이면 새로. ids 가 비면 파일을 지운다(새 세이브로 시작)"""
    path = os.path.join(ROOT, ".tools", name)
    if os.path.exists(path):
        os.remove(path)
    if ids:
        with open(path, "w", encoding="utf-8") as f:
            json.dump({"v": 1, "cleared": {i: {"count": 1, "best": 1} for i in ids}, "last": last}, f)
    return path


def open_all_save():
    """모든 장을 깬 세이브 — 배포판(campaign.gd OPEN_ALL false)은 차례대로 열리므로, 싸움 중 메뉴로 먼 장(11장)에 가는 흐름 시험은 이 세이브로"""
    return save_file("save_open.json", playable_ids())


def read_save(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def step_flow(g):
    base = [g, "--headless", "--fixed-fps", "60", "--path", "."]
    got = {}

    def grab(key, extra):
        def chk(out):
            m = re.search(r"^RESULT (.*)$", out, re.M)
            got[key] = (json.loads(m.group(1)) if m else None, re.findall(r"^(MODE \w+|PAUSE \w+)", out, re.M),
                        re.findall(r"^(MODE \w+|MENU \w+|STAGE \w+ room=\d+)", out, re.M))
            return m is not None, ""
        return run(f"흐름 {key}", base + ["--"] + extra, chk, timeout=300)
    ok = grab("멈춤 없음", ["--autoplay", "--seconds", "40", "--seed", "1"])
    ok &= grab("2초 멈춤", ["--autoplay", "--seconds", "42", "--seed", "1", "--trace", "--events", "600:pause,720:resume"])
    ok &= grab("속도 ×1.5", ["--autoplay", "--seconds", "40", "--seed", "1", "--events", "1:speed"])
    ok &= grab("뒤로 · 내려감", ["--seconds", "16", "--trace", "--events", FLOW_EVENTS])
    ok &= grab("메뉴 · 스테이지", ["--seconds", "12", "--trace", "--save", open_all_save(), "--events", MENU_EVENTS])
    # 장 차례(rc.4 폰 "8장 깨도 9장으로 안넘어가"): 새 세이브 → 이어하기로 0 ~ 13장을 깬다(autowin — 적을 바로 쓰러뜨림, 방 넘기 · 깸 · 세이브는 그대로)
    ids = playable_ids()
    chain = save_file("save_chain.json", [])
    ok &= grab("장 차례", ["--seconds", "900", "--trace", "--save", chain, "--events", CHAIN_EVENTS])
    # 중간 스테이지부터(싸움 중 메뉴로 고름 · 난이도 바꿔 다시) 깨도 다음 장이 열린다
    i8 = ids.index("ch8")
    mid = save_file("save_mid.json", ids[:i8], ids[i8 - 1])
    ok &= grab("중간 스테이지 깸", ["--seconds", "30", "--trace", "--save", mid, "--events", MID_EVENTS])
    if not ok:
        return False
    order = []
    for line in got["장 차례"][2]:
        if line.startswith("STAGE ") and (not order or order[-1] != line.split()[1]):
            order.append(line.split()[1])
    chain_ok = order == ids and sorted(read_save(chain)["cleared"]) == sorted(ids)
    mid_seq = [x for x in got["중간 스테이지 깸"][2] if x.startswith("STAGE")]
    mid_ok = read_save(mid)["cleared"].get("ch8") is not None and mid_seq[-1:] == ["STAGE ch9 room=0"] and "STAGE ch8 room=2" in mid_seq
    a, b = got["멈춤 없음"][0], got["2초 멈춤"][0]
    same = a["last"] == b["last"] and a["fights"] == b["fights"] and a["wins"] == b["wins"]
    c = got["속도 ×1.5"][0]
    same_speed = all(c[k] == a[k] for k in ("frames", "fights", "wins", "last")) and c["draws"] < a["draws"] * 0.75
    seq = got["뒤로 · 내려감"][1]
    seq_ok = seq == FLOW_WANT
    menu_seq = got["메뉴 · 스테이지"][2]
    menu_ok = menu_seq == MENU_WANT and got["메뉴 · 스테이지"][0]["last"].get("room") == "office_door"
    good = same and same_speed and seq_ok and menu_ok and chain_ok and mid_ok and got["2초 멈춤"][1].count("PAUSE on") == 1
    msg = ("멈춘 앞뒤 같은 판" if same else f"멈춘 판이 다르다 {a['last']} / {b['last']}") + " · " + \
        ("속도 ×1.5 도 같은 판" if same_speed else f"속도를 바꾸니 판이 다르다 {c} / {a}") + " · " + \
        ("뒤로 · 내려감 순서 맞음" if seq_ok else f"순서가 다르다: {seq}") + " · " + \
        ("메뉴로 11장 회장실 앞" if menu_ok else f"메뉴 순서가 다르다: {menu_seq}") + " · " + \
        (f"장 차례 {len(ids)}장 깸 → 다음 장" if chain_ok else f"장 차례가 다르다: {order}") + " · " + \
        ("8장 중간 스테이지 깸 → 9장" if mid_ok else f"중간 스테이지 깸이 다음 장을 안 연다: {mid_seq}")
    print(f"[{'ok' if good else 'FAIL'}] 흐름 — {msg}")
    return good


def step_save(g):
    """세이브 파일 앞뒤 — 처음 화면 그림 버튼(--events art)이 .tools/save_check.json 에 쓰이고, 다음 실행이 그것을 읽는다.
    깬 장 기록 · 이어하기 · 옛 · 깨진 · 새 형식은 tests/unit/test_campaign.gd 가 본다"""
    path = os.path.join(ROOT, ".tools", "save_check.json")
    if os.path.exists(path):
        os.remove(path)
    base = [g, "--headless", "--fixed-fps", "60", "--path", ".", "--", "--save", path, "--trace"]
    ok = run("세이브 쓰기 (그림 A → B)", base + ["--seconds", "3", "--events", "60:art"], lambda out: ("SAVE new art=a" in out, ""))
    try:
        with open(path, encoding="utf-8") as f:
            art = json.load(f).get("art")
    except (OSError, ValueError):
        art = None
    ok &= run("세이브 읽기", base + ["--seconds", "1"], lambda out: ("SAVE ok art=b" in out, f"파일 art={art}"))
    return ok and art == "b"


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")      # 윈도우 콘솔(cp1252)에서 한글 출력에 죽지 않게
    except (AttributeError, ValueError):
        pass
    strict = "--strict" in sys.argv[1:]
    g = godot()
    t0 = time.time()
    results = [step_common(strict), step_assets(), step_looks(), step_techniques()]
    if not os.path.isdir(os.path.join(ROOT, ".godot", "imported")):
        # 새로 받은 저장소(CI): 첫 가져오기는 프로젝트 글꼴을 가져오기 전에 읽으려 해 ERROR 를 낸다(run #1) — 한 번 돌리고 다시 본다
        p = subprocess.run([g, "--headless", "--path", ".", "--import"], cwd=ROOT, capture_output=True, timeout=600, stdin=subprocess.DEVNULL)
        print(f"[..] 첫 가져오기 (종료 코드 {p.returncode}, 출력은 다음 가져오기에서 본다)")
    results.append(run("가져오기", [g, "--headless", "--path", ".", "--import"]))

    def tests_ok(out):
        m = re.search(r"tests: (\d+) passed, (\d+) failed", out)
        return (m is not None and m.group(2) == "0"), (m.group(0) if m else "결과 줄 없음")
    results.append(run("테스트", [g, "--headless", "--path", ".", "-s", "res://tests/run_tests.gd"], tests_ok, timeout=180))
    results.append(step_coverage(g))
    for seed in (1, 2, 3):
        def auto_ok(out):
            m = re.search(r"^RESULT (.*)$", out, re.M)
            return m is not None, (m.group(1)[:150] if m else "RESULT 줄 없음")
        results.append(run(f"자동 결투 seed {seed} · 90초",
                           [g, "--headless", "--fixed-fps", "60", "--path", ".", "--", "--autoplay", "--seconds", "90",
                            "--seed", str(seed)] + (["--art", "puppet"] if seed == 3 else []), auto_ok))
    for seed in (1, 2):
        def stage_ok(out):
            m = re.search(r"^RESULT (.*)$", out, re.M)
            if m is None:
                return False, "RESULT 줄 없음"
            last = json.loads(m.group(1))["last"]
            return True, f"{last['over'] or 'time'} · 방 {last['room']} · 넘은 방 {last['cleared']} · {last['times']}"
        results.append(run(f"11장 자동 판 seed {seed} · 150초",
                           [g, "--headless", "--fixed-fps", "60", "--path", ".", "--", "--autoplay", "--mode", "stage",
                            "--seconds", "150", "--seed", str(seed)]
                           + (["--save-replay", REPLAY_FILE] if seed == 2 else []), stage_ok))
    for ch, secs, need_win in (("ch0", 120, True), ("ch1", 360, False), ("ch2", 300, False)):
        def p1_ok(out, need_win=need_win):
            m = re.search(r"^RESULT (.*)$", out, re.M)
            if m is None:
                return False, "RESULT 줄 없음"
            r = json.loads(m.group(1))
            last = r["last"]
            ok = r.get("wins", 0) >= 1 or not need_win
            return ok, f"이김 {r.get('wins', 0)} · 끝 판 {last['over'] or 'time'} · 방 {last['room']} · {last['times']}"
        results.append(run(f"{ch[2:]}장 자동 판 seed 1 · {secs}초",
                           [g, "--headless", "--fixed-fps", "60", "--path", ".", "--", "--autoplay", "--mode", ch,
                            "--seconds", str(secs), "--seed", "1"], p1_ok))
    if os.path.exists(os.path.join(ROOT, REPLAY_FILE)):
        def replay_ok(out):
            m = re.search(r"^REPLAY (.*)$", out, re.M)
            return (m is not None and m.group(1).startswith("ok=true")), (m.group(1)[:100] if m else "REPLAY 줄 없음")
        results.append(run("리플레이 (11장 seed 2 기록 → 다른 프로세스에서 재생)",
                           [g, "--headless", "--path", ".", "--", "--replay", REPLAY_FILE], replay_ok))
    else:
        print(f"[FAIL] 리플레이 — {REPLAY_FILE} 가 안 생겼다")
        results.append(False)
    for art in ("a", "b"):
        results.append(run(f"그림 {art.upper()} (11장 회장실 앞 · 20초)",
                           [g, "--headless", "--fixed-fps", "60", "--path", ".", "--", "--autoplay", "--mode", "stage",
                            "--room", "4", "--art", art, "--seconds", "20"], lambda out: (("RESULT" in out), "")))
    for art in ("a", "b"):
        results.append(run(f"그림 {art.upper()} (1장 회암시 거리 · 강만재 → 윤덕수 · 20초)",
                           [g, "--headless", "--fixed-fps", "60", "--path", ".", "--", "--autoplay", "--mode", "ch1",
                            "--room", "3", "--art", art, "--seconds", "20"], lambda out: (("RESULT" in out), "")))
    for art, room, name in (("a", "1", "2장 1층 · 서진태"), ("b", "5", "2장 위층 복도 · 남궁혁"), ("a", "6", "2장 폐차장 · 신태진")):
        results.append(run(f"그림 {art.upper()} ({name} · 20초)",
                           [g, "--headless", "--fixed-fps", "60", "--path", ".", "--", "--autoplay", "--mode", "ch2",
                            "--room", room, "--art", art, "--seconds", "20"], lambda out: (("RESULT" in out), "")))
    results.append(run("성능 판 (11장 지하주차장 · 경호원 36명 + 이름 있는 적 · 아군 11명 · 20초)",
                       [g, "--headless", "--fixed-fps", "60", "--path", ".", "--", "--autoplay", "--mode", "stage",
                        "--crowd", "30", "--seconds", "20"], lambda out: (("RESULT" in out), "")))
    results.append(step_flow(g))
    results.append(step_save(g))
    n_ok = sum(results)
    print(f"verify: {n_ok}/{len(results)} 통과 · {time.time() - t0:.0f}초 — {'OK' if n_ok == len(results) else 'FAIL'}")
    return 0 if n_ok == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
