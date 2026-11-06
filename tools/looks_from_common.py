"""인물 외형 다리 — 받은 castle_common data/looks.json(원작 조각을 직접 보고 적은 외형 표 · 사용자 답58)을 이 판 외형 칸으로.

    python3.11 tools/looks_from_common.py           # src/view/looks_common.gd 쓰기(생성물)
    python3.11 tools/looks_from_common.py --check   # 최신인지만(다르면 종료 코드 1 — verify 가 부른다)

- 옮기는 칸 = 겉모습만: 옷 색 · 옷 갈래(정장 · 셔츠 · 코트 · 가운) · 깃 · 넥타이 · 피부 · 머리색 · 둘째 머리색 · 머리 모양 · 안경 · 렌즈 ·
  피어싱 · 흉터 · 수염 · 금 배지 · 체인 · 홀스터. 키 · 체격 비율 · 무기 · 자세 · 이 판만의 칸(fur · rings · eye_col …)은
  src/view/looks.gd LOOKS(이 판 소유 · 폰 리뷰로 맞춘 값)가 그대로 정한다.
- 어느 외형 이름이 어느 인물 · 장 차림인가 = NAMES(아래). looks.gd look() 이 LOOKS 위에 이것을 덮는다.
- 색: 조각에서 뽑은 가운데값은 그늘 · 색 조명이 껴 흔들린다 — 3D 밤 조명에 맞게 조금 밝히고(피부는 살빛 색조에 밝기만), LOOKS 에 이미
  색이 있으면 **크게 다를 때만**(RGB 거리 > COLOR_GAP — 예: 검은 머리 ↔ 금발, 흰 셔츠 ↔ 검은 셔츠) 바꾼다(폰 리뷰로 맞춘 색을 지킨다).
"""
import colorsys
import re
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.environ.get("CASTLE_LOOKS_JSON") or os.path.join(ROOT, "data", "common", "looks.json")
OUT = os.path.join(ROOT, "src", "view", "looks_common.gd")

# 외형 이름 → (looks.json id, 공통 장 또는 period label 에 든 말 · None = 대표 차림)
NAMES = {
    "kim": ("kimshin", None), "baek": ("baekdochan", "6"), "woojin": ("woojin", "11"), "guilhwa": ("guilhwa", "11"),
    "hayabusa": ("hayabusa", "11"), "shingen": ("shingen", "11"), "guard": ("_castle_guard", None),
    "g4": ("_castle_g4", None), "g4_leader": ("_castle_g4", "리더"), "gunter": ("gunter", "0"),
    "ds_suit": ("_ds_member", None), "jintae": ("jintae", "1"), "kimhyeokju": ("kimhyeokju", "1"),
    "kimseongjun": ("kimseongjun", "1"), "kimdaegeon": ("kimdaegeon", "1"), "gangmanjae": ("gangmanjae", "1"),
    "yundeoksu": ("yundeoksu", "1"), "kim_bare": ("kimshin", "1"),
    # 2장(1부 021~036 하성 본사) — 김신은 looks.json 에 2장 차림이 없어 1장(귀국 — 터틀넥 + 정장 재킷)에 칼을 든다
    "kim_p1_blade": ("kimshin", "1"), "sintaejin": ("sintaejin", "2"), "namgunghyuk": ("namgunghyuk", "2"),
    "hwangbomincheol": ("hwangbomincheol", "2"), "iseul": ("iseul", "2"), "ojiin": ("ojiin", "2"),
    "kimjaehoon": ("kimjaehoon", "2"), "insu": ("insu", "2"), "gangchangseok": ("gangchangseok", "2"),
}
# 이 판 장면에 맞춘 칸은 덮지 않는다: 피우진 싸울 땐 상투(원작 — 대표 차림은 장발) · 서진태 검은 투블럭 + 금발(hair2 와 짝)
KEEP = {"woojin": ("hair_style",), "jintae": ("hair_style",), "ojiin": ("outfit",)}   # 오지인: 긴소매 블라우스(겉옷 없음 → shirt 는 소매 걷음) — vest 로
HAIR = {"bald": "bald", "buzz": "buzz", "crew": "crew", "short": "short", "undercut": "undercut", "spiky": "spiky",
        "messy": "curly", "slick": "slick", "slick_fringe": "slick_fringe", "parted": "parted", "fringe": "fringe",
        "wavy": "curly", "wavy_back": "wavy_back", "long": "long", "ponytail": "ponytail", "topknot": "topknot",
        "bun": "bun", "bob": "long", "afro": "curly", "mohawk": "spiky", "dreads": "long"}
SUN = {"sunglasses_square": "sun", "sunglasses_round": "sun", "goggles": "sun", "aviator": "aviator"}
HAT = {"beanie": "beanie", "bucket_hat": "bucket"}     # 그리는 모자만(챙 없는 니트 비니 · 챙이 아래로 처진 벙거지)
GOLD = (0.95, 0.75, 0.25)
COLOR_GAP = 0.42
GAP = {"hair": 0.25}            # 머리색은 짙음 ↔ 밝음이 식별 특징이라 더 쉽게 바꾼다(백도찬 — 공식 카드 · 조각 모두 짙은 갈색)
LOOKS_GD = os.path.join(ROOT, "src", "view", "looks.gd")


def hand_colors():
    """looks.gd LOOKS 의 이름 → {칸: (r, g, b)} (손 값 — 색을 덮을지 견줄 때)."""
    out, cur = {}, None
    with open(LOOKS_GD, encoding="utf-8") as f:
        text = f.read()
    body = text[text.index("const LOOKS := {"):text.index("\n}\n", text.index("const LOOKS := {"))]
    for line in body.splitlines():
        m = re.match(r'^\t"([a-z_0-9]+)": \{', line)
        if m:
            cur = out.setdefault(m.group(1), {})
        if cur is not None:
            for k, v in re.findall(r'"([a-z_0-9]+)": Color\(([-\d., ]+)\)', line):
                cur[k] = tuple(float(x) for x in v.split(","))[:3]
            for k, v in re.findall(r'"(outfit)": "([a-z_]+)"', line):
                cur[k] = v
    return out
SKIN_BASE = (0.91, 0.77, 0.65)


def rgb(h):
    if not isinstance(h, str) or not h.startswith("#"):
        return None
    return tuple(int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))


def lift(c, k=1.12):
    """어두운 색만 조금 밝힌다(밝은 옷은 그대로 — 흰색으로 날아가지 않게)."""
    if not c:
        return None
    return tuple(min(1.0, v * k + 0.02) for v in c) if max(c) < 0.6 else c


def skin(h):
    """밝기만 조각에서(색 조명의 색조는 버림) — 살빛 색조 · 채도에 얹는다."""
    c = rgb(h)
    if not c:
        return None
    _hh, ll, _ss = colorsys.rgb_to_hls(*c)
    return colorsys.hls_to_rgb(0.07, min(0.86, max(0.35, ll * 1.1)), 0.45)


def merge(base, diff):
    out = json.loads(json.dumps(base))
    for k, v in (diff or {}).items():
        out[k] = merge(out[k], v) if isinstance(v, dict) and isinstance(out.get(k), dict) else v
    return out


def pick(rec, when):
    if when is None:
        return rec["base"]
    periods = rec.get("periods") or []
    for p in periods:                     # 장 번호는 chapters 로만 맞춘다(label 의 '2부' 가 2장으로 잡히지 않게)
        if when in (p.get("chapters") or []):
            return merge(rec["base"], p.get("diff"))
    if not when.isdigit():
        for p in periods:                 # 장 번호가 아닌 말(예: '리더')은 label 에서
            if when in (p.get("label") or ""):
                return merge(rec["base"], p.get("diff"))
    return rec["base"]


def convert(lk):
    h, o = lk.get("head") or {}, lk.get("outfit") or {}
    outer, shirt, pants = o.get("outer") or {}, o.get("shirt") or {}, o.get("pants") or {}
    d = {}
    ok = outer.get("kind")
    sc = lift(rgb(shirt.get("color")))
    if ok and ok != "none":
        if lift(rgb(outer.get("color"))):
            d["suit"] = lift(rgb(outer.get("color")))
        if ok in ("long_coat", "trench_coat"):
            d["outfit"] = "coat"
        elif ok == "robe":
            d["outfit"] = "robe"
        elif ok == "vest":
            d["outfit"] = "vest"         # 조끼 — 팔은 셔츠 소매
        if ok == "leather_jacket":
            d["leather"] = True
    elif ok == "none":
        d["outfit"] = "shirt"
        if sc:
            d["suit"] = sc
    if sc:
        d["shirt"] = sc
    if shirt.get("kind") == "open_shirt":
        d["collar"] = "open"
    elif shirt.get("kind") == "turtleneck":
        d["collar"] = "turtle"
    elif shirt.get("kind") == "tshirt":
        d["collar"] = "crew"             # 둥근 목 티 — 단추 · 목 V 없음
    if lift(rgb(pants.get("color"))):
        d["pants"] = lift(rgb(pants.get("color")))
    d["skirt"] = pants.get("kind") == "skirt"
    if "tie" in o:
        d["tie"] = lift(rgb(o.get("tie")))          # None = 넥타이 없음
    if skin(h.get("skin")):
        d["skin"] = skin(h.get("skin"))
    if lift(rgb(h.get("hair_color")), 1.05):
        d["hair"] = lift(rgb(h.get("hair_color")), 1.05)
    if rgb(h.get("hair_color2")):
        d["hair2"] = rgb(h.get("hair_color2"))
    if h.get("hair_style") in HAIR:
        d["hair_style"] = HAIR[h["hair_style"]]
    g = h.get("glasses")
    if g and g.get("lens") == "clear":    # 맑은 렌즈 — 선글라스처럼 검게 그리지 않는다(테 색만)
        d["glasses"] = True
        if rgb(g.get("frame")):
            d["frame"] = rgb(g.get("frame"))
    elif g:
        lens = rgb(g.get("lens"))
        d["glasses"] = SUN.get(g.get("kind"), "sun" if lens else True)
        if lens:
            d["lens"] = lens
    else:
        d["glasses"] = False
    d["piercing"] = bool(h.get("piercings"))
    scars = [s.get("where") for s in h.get("scars") or []]
    if len([s for s in scars if s in ("left_cheek", "right_cheek")]) >= 2:
        d["scar"] = "double"
    elif "nose_bridge" in scars:
        d["scar"] = "nose"
    elif "left_eye" in scars or "right_eye" in scars:
        d["scar"] = "eye_l" if "left_eye" in scars else "eye_r"      # 눈썹 위에서 눈을 지나 뺨으로 세로 한 줄(황보민철)
    elif "forehead" in scars:
        d["scar"] = "brow"
    elif any(s in ("left_cheek", "right_cheek") for s in scars):
        d["scar"] = True
    else:
        d["scar"] = False
    fh = set(h.get("facial_hair") or [])     # 수염은 이 칸에서만(김신 — 수염 그늘 없음, 답59)
    d["stubble"] = "stubble" in fh
    d["beard"] = "beard" in fh
    d["mustache"] = "mustache" in fh
    d["goatee"] = "goatee" in fh
    if h.get("blind_eye") in ("left", "right"):
        d["blind_eye"] = h["blind_eye"][0]   # 인물 자기 쪽 — 그 눈은 흰자
    hw = h.get("headwear") or {}
    if hw.get("kind") in HAT:
        d["hat"] = HAT[hw["kind"]]
        d["hat_col"] = lift(rgb(hw.get("color"))) or (0.2, 0.2, 0.22)
    acc = {a.get("kind"): a for a in lk.get("accessories") or []}
    for a in lk.get("accessories") or []:
        if a.get("kind") == "other" and a.get("where") == "lips" and rgb(a.get("color")):
            d["lips"] = rgb(a.get("color"))
    d["badge"] = (rgb(acc["badge"].get("color")) or GOLD) if "badge" in acc else None
    d["chain"] = (rgb(acc["chain"].get("color")) or GOLD) if "chain" in acc else None
    d["holster"] = (rgb(acc["holster"].get("color")) or (0.45, 0.27, 0.14)) if "holster" in acc else None
    return d


def gd(v):
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, tuple):
        return "Color(%s)" % ", ".join("%.3g" % x for x in v)
    return json.dumps(v, ensure_ascii=False)


def keep_hand(d, hand, keep=()):
    for k in keep:
        d.pop(k, None)
    if hand.get("outfit") == "shirt" and "outfit" not in d:
        for k in ("suit", "outfit", "leather"):    # 이 판이 재킷을 벗긴 장면(김대건 노을 · 윤덕수 거리) — 겉옷 색을 얹지 않는다
            d.pop(k, None)
    for k, v in list(d.items()):
        if isinstance(v, tuple) and k in hand:
            if sum((a - b) ** 2 for a, b in zip(v, hand[k])) ** 0.5 <= GAP.get(k, COLOR_GAP):
                del d[k]
    return d


def build():
    with open(SRC, encoding="utf-8") as f:
        looks = {r["id"]: r for r in json.load(f)["looks"]}
    hands = hand_colors()
    lines = ['extends RefCounted',
             '## 생성물 — tools/looks_from_common.py 가 만든다(손으로 고치지 않는다). castle_common data/looks.json(원작 조각 대조 ·',
             '## 사용자 답58)의 겉모습 칸 — looks.gd look() 이 LOOKS 위에 덮는다. 키 · 체격 · 무기 · 자세는 LOOKS 가 정한다.',
             '', 'const BY_NAME := {']
    for name in sorted(NAMES):
        cid, when = NAMES[name]
        if cid not in looks:
            continue
        d = keep_hand(convert(pick(looks[cid], when)), hands.get(name, {}), KEEP.get(name, ()))
        body = ", ".join("%s: %s" % (json.dumps(k), gd(v)) for k, v in sorted(d.items()))
        lines.append('\t"%s": {%s},  # %s%s' % (name, body, cid, " · " + when if when else ""))
    lines += ['}', '']
    return "\n".join(lines)


def main():
    text = build()
    if "--check" in sys.argv:
        with open(OUT, encoding="utf-8") as f:
            if f.read() != text:
                print("src/view/looks_common.gd 가 data/common/looks.json 과 다르다 — python3.11 tools/looks_from_common.py")
                return 1
        print("looks_common.gd 최신")
        return 0
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("wrote", os.path.relpath(OUT, ROOT), text.count("\n"), "lines")
    return 0


if __name__ == "__main__":
    sys.exit(main())
