"""원작 기술 표 굽기 — castle_common 받은 사본 data/common/canon/techniques.json(0층 정사 — APK 에 안 들어간다)에서
인물마다 기술 이름 · 갈래 · 근거를 뽑아 data/story/techniques.json(APK 에 들어간다)으로.

    python3.11 tools/bake_techniques.py          # 다시 굽기
    python3.11 tools/bake_techniques.py --check  # 사본과 맞는지만(verify '원작 기술 표' 가 부른다 — 다르면 1)

인물마다 기술 수(사용자 2026-11-10: 재앙 전부 · 톱 7 · 내성 5 · 외성 4 · 그 아래 3)는 게임이 정한다(src/data/skill_kit.gd).
여기서는 차례만: conf user → guess → ai, 같은 conf 안에서는 원작에 나온 횟수(count) 많은 순, 같으면 원본 차례.
갈래(kind)는 이름 → 다른 이름 → 실행 묘사의 낱말로 정한다(KINDS 차례대로 처음 맞는 것) — 게임이 갈래로 동작을 고른다(3층).
conf ai 는 연출(기술 이름 띄우기)에만 쓴다(CLAUDE.md 2-1 도메인 품질).
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "data", "common", "canon", "techniques.json")
OUT = os.path.join(ROOT, "data", "story", "techniques.json")

# 갈래 → 낱말 (앞 갈래가 먼저). 총 · 잡기는 '발사' · '잡아 치기'처럼 다른 낱말과 겹쳐도 먼저 본다
KINDS = [
    ("gun", ["총", "사격", "권총", "리볼버", "샷건", "라이플", "우지", "연사"]),
    ("grab", ["메치", "던지", "던져", "조르", "관절", "태클", "업어", "꺾", "잡아", "잡고", "붙잡", "내리꽂"]),
    ("counter", ["카운터", "받아치", "맞받", "반격", "되받"]),
    ("kick", ["차기", "킥", "발차", "무릎", "발등", "뒤꿈치", "각법"]),
    ("blade", ["칼", "베기", "베어", "찌르", "찌름", "검술", "장검", "단검", "나이프", "카람빗", "도끼", "낫", "곡도"]),
    ("head", ["박치기", "머리로", "이마", "들이받"]),
    ("flurry", ["연타", "난타", "러시", "몰아", "연속", "난무"]),
    ("evade", ["스텝", "위빙", "회피", "피하", "흘리", "비키"]),
]
CONF_ORDER = {"user": 0, "guess": 1, "ai": 2}
# 싸움 동작이 아닌 것(수련 장면) — 기술 묶음에 넣지 않는다
NOT_MOVE = ["단련", "트레이닝", "훈련", "수련"]


def kind_of(t):
    """이름 → 다른 이름 → 실행 묘사 차례로 보고 처음 맞는 글에서 갈래를 정한다(묘사에는 상대의 총 · 칼도 나와 이름이 먼저)"""
    for text in [t.get("name", ""), " ".join(t.get("aliases", [])), str(t.get("stages", {}).get("exec", ""))]:
        for k, words in KINDS:
            if any(w in text for w in words):
                return k
    return "strike"


def bake():
    with open(SRC, encoding="utf-8") as f:
        src = json.load(f)
    by = {}
    for i, t in enumerate(src["techniques"]):
        if any(w in t.get("name", "") for w in NOT_MOVE):
            continue
        for u in t.get("users", []):
            by.setdefault(u, []).append((CONF_ORDER.get(t.get("conf"), 3), -int(t.get("count", 0) or 0), i, t))
    out = {"_about": "tools/bake_techniques.py 가 castle_common canon/techniques.json 에서 구운 것 — 손으로 고치지 않는다. "
                     "인물 id → [기술 id · 이름 · 갈래(kind) · conf · count] (차례: conf user → guess → ai, count 많은 순)",
           "chars": {}}
    for u in sorted(by):
        rows = sorted(by[u], key=lambda r: r[:3])
        out["chars"][u] = [{"id": t["id"], "name": t["name"], "kind": kind_of(t), "conf": t.get("conf", ""),
                            "count": int(t.get("count", 0) or 0)} for _, _, _, t in rows]
    return json.dumps(out, ensure_ascii=False, indent=1) + "\n"


def main():
    text = bake()
    if "--check" in sys.argv:
        old = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
        ok = old == text
        print("원작 기술 표 맞음" if ok else "원작 기술 표가 사본과 다르다 — python3.11 tools/bake_techniques.py")
        sys.exit(0 if ok else 1)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"구움 {OUT}")


if __name__ == "__main__":
    main()
