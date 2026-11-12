#!/usr/bin/env python3.11
"""방마다 원작 대사(2026-11-12 사용자 "각 스테이지별 원작 그대로의 캐릭터들 멘트 다 넣어줘" · 원작 대사 (가) — 지금 넣음).

장 표(src/data/*.gd CANON — 방 id → fight id)의 원작 대결(castle_common canon/fights.json refs)을 따라
castle_common work/text(원작 컷을 보고 받아 적은 대사 — 읽기만)에서 말 · 속말 · 내레이션을 뽑아
data/story/lines.json 의 <장>.canon.<방> = {"open": [[말하는 사람, 말], ..], "mid": [..], "close": [..]} 로 쓴다.
  open  — 싸움 앞(대결 첫 범위 앞 PRE_CUTS 컷부터 · OPEN_MAX 줄까지) → 싸움 앞 장면(stage.gd — 누르면 넘김)
  mid   — 싸움 중(가운데 줄들 · MID_MAX) → 보스 체력 2/3 · 1/3 에서 말풍선(멈추지 않음)
  close — 끝(마지막 범위의 끝 CLOSE_MAX 줄) → 방을 깨기 전 장면
말하는 사람은 원작 id(characters) — 그 방에 없는 사람 말은 게임이 건너뛴다(scene.gd). 이름 모를 사람(?:) · 효과음 · 화면글은 뺀다.
속말은 괄호(말풍선 구름), 내레이션은 '@'(왼쪽 위 띠).

  python3.11 tools/canon_scenes.py            # 모든 장 표 → lines.json (방 표에 손으로 쓴 scene 이 있는 방도 canon 은 쓴다 — 게임이 고른다)
  python3.11 tools/canon_scenes.py --dry      # 쓰지 않고 줄 수만
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CC = os.environ.get("CASTLE_COMMON", os.path.join(ROOT, "..", "castle_common"))
LINES = os.path.join(ROOT, "data", "story", "lines.json")
PRE_CUTS = 14
OPEN_MAX = 10
MID_MAX = 4
CLOSE_MAX = 8
KEEP = ("말", "속말", "내레이션")


def fights() -> dict:
    with open(os.path.join(CC, "canon", "fights.json"), encoding="utf-8") as f:
        d = json.load(f)
    items = d if isinstance(d, list) else d.get("fights", list(d.values()))
    return {x["id"]: x for x in items}


_text_cache = {}


def text(part: str, ep: int) -> list:
    k = (part, ep)
    if k not in _text_cache:
        p = os.path.join(CC, "work", "text", part, "%03d.json" % ep)
        _text_cache[k] = json.load(open(p, encoding="utf-8")) if os.path.exists(p) else []
    return _text_cache[k]


def parse_ref(r: str):
    m = re.match(r"(?:(p1):)?(\d+)/(\d+)(?:-(\d+))?", r)
    if not m:
        return None
    a = int(m.group(3))
    return ("castle1" if m.group(1) else "castle2", int(m.group(2)), a, int(m.group(4) or a))


def cut_of(ref: str) -> int:
    m = re.search(r"/(\d+)", ref)
    return int(m.group(1)) if m else -1


def lines_in(part, ep, a, b) -> list:
    out = []
    for x in text(part, ep):
        c = cut_of(x["ref"])
        if c < a or c > b or x["kind"] not in KEEP:
            continue
        who = str(x["speaker"])
        if who.startswith("?") and x["kind"] != "내레이션":
            continue
        t = x["text"].strip()
        if t == "" or set(t) <= set(".!?…~ "):
            continue                                   # 말줄임 · 놀람표만인 줄은 뺀다
        if x["kind"] == "속말":
            t = "(" + t + ")"
        out.append(["@" if x["kind"] == "내레이션" else who, t])
    return out


def scenes_for(f: dict) -> dict:
    refs = [parse_ref(r) for r in f.get("refs", [])]
    refs = [r for r in refs if r]
    if not refs:
        return {}
    part, ep, a, b = refs[0]
    pre = lines_in(part, ep, max(0, a - PRE_CUTS), a - 1)
    body = []
    for (p2, e2, a2, b2) in refs:
        body += lines_in(p2, e2, a2, b2)
    opn = (pre + body[: max(0, OPEN_MAX - len(pre))])[-OPEN_MAX:] if pre else body[:OPEN_MAX]
    rest = body[max(0, OPEN_MAX - len(pre)):] if pre else body[OPEN_MAX:]
    close = rest[-CLOSE_MAX:] if len(rest) > 0 else []
    middle = rest[: max(0, len(rest) - CLOSE_MAX)]
    mid = [middle[i] for i in range(0, len(middle), max(1, len(middle) // MID_MAX))][:MID_MAX] if middle else []
    return {"open": opn, "mid": mid, "close": close}


def tables() -> dict:
    """장 표 파일 → (LINES 키, {방 id: fight id})"""
    out = {}
    for p in sorted(glob.glob(os.path.join(ROOT, "src", "data", "*.gd"))):
        s = open(p, encoding="utf-8").read()
        m = re.search(r'const LINES := "(\w+)"', s)
        c = re.search(r"const CANON := \{(.*?)\n\}", s, re.S)
        if not m or not c:
            continue
        rooms = dict(re.findall(r'"(\w+)": \{"fight": "([^"]*)"', c.group(1)))
        out.setdefault(m.group(1), {}).update(rooms)
    return out


def main():
    fs = fights()
    data = json.load(open(LINES, encoding="utf-8"))
    total = 0
    for key, rooms in tables().items():
        if key not in data:
            continue
        canon = {}
        for room, fid in rooms.items():
            if not fid or fid not in fs:
                continue
            sc = scenes_for(fs[fid])
            if sc and any(sc.values()):
                canon[room] = sc
                total += sum(len(v) for v in sc.values())
        if canon:
            data[key]["canon"] = canon
    print("방 대사 %d 줄" % total)
    if "--dry" in sys.argv:
        return
    with open(LINES, encoding="utf-8") as f:
        raw = f.read()
    # 장 블록마다 "canon" 한 덩어리만 바꿔 쓴다(나머지 줄 모양은 그대로)
    for key in data:
        if not isinstance(data[key], dict) or "canon" not in data[key]:
            continue
        body = '    "canon": ' + json.dumps(data[key]["canon"], ensure_ascii=False) + ",\n"
        head = '\n  "%s": {\n' % key
        i = raw.index(head) + len(head)
        j = raw.index('    "rooms": {', i)
        blk = raw[i:j]
        blk = re.sub(r'    "canon": .*\n', "", blk)
        raw = raw[:i] + blk + body + raw[j:]
    json.loads(raw)
    with open(LINES, "w", encoding="utf-8") as f:
        f.write(raw)


if __name__ == "__main__":
    main()
