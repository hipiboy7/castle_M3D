#!/usr/bin/env python3.11
"""원작 대사 뽑기(개발용 — 2026-11-12 사용자 "각 스테이지별 원작 그대로의 캐릭터들 멘트 다 넣어줘" · 원작 대사 (가) 지금 넣음).

castle_common work/text/castle1 · castle2(에이전트가 원작 컷을 보고 받아 적은 대사 — 읽기만)에서 화/컷 범위의 말 · 속말 · 내레이션을
장면 단계(src/combat/scene.gd says 줄)로 찍는다. 찍은 것을 사람이 골라 data/story/lines.json 의 scenes 에 옮긴다.

  python3.11 tools/canon_lines.py p1:022/054-070            # 1부 22화 54 ~ 70컷
  python3.11 tools/canon_lines.py p1:022/054-070 --json      # [[말하는 사람, 말], ..] (속말은 괄호, 내레이션은 @)
  python3.11 tools/canon_lines.py 088/000-030                 # 2부(화 번호만)
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CC = os.environ.get("CASTLE_COMMON", os.path.join(ROOT, "..", "castle_common"))


def load(part: str, ep: int) -> list:
    path = os.path.join(CC, "work", "text", part, "%03d.json" % ep)
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def pick(spec: str) -> list:
    m = re.match(r"(?:(p1):)?(\d+)/(\d+)-(\d+)$", spec)
    if not m:
        raise SystemExit("범위 모양: p1:022/054-070 또는 088/000-030")
    part = "castle1" if m.group(1) else "castle2"
    ep, a, b = int(m.group(2)), int(m.group(3)), int(m.group(4))
    out = []
    for x in load(part, ep):
        cut = int(re.search(r"/(\d+)", x["ref"]).group(1))
        if cut < a or cut > b or x["kind"] in ("효과음", "화면글"):
            continue
        who = x["speaker"]
        text = x["text"].strip()
        if x["kind"] == "속말":
            text = "(" + text + ")"
        if x["kind"] == "내레이션":
            who = "@"
        out.append([who, text, x["ref"]])
    return out


if __name__ == "__main__":
    rows = pick(sys.argv[1])
    if "--json" in sys.argv:
        print(json.dumps([[r[0], r[1]] for r in rows], ensure_ascii=False))
    else:
        for r in rows:
            print("%-14s %-22s %s" % (r[2], r[0], r[1]))
