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
        "bun": "bun", "bob": "bob", "afro": "curly", "mohawk": "spiky", "dreads": "long"}
SUN = {"sunglasses_square": "sun", "sunglasses_round": "sun", "goggles": "sun", "aviator": "aviator"}
HAT = {"beanie": "beanie", "bucket_hat": "bucket", "cap": "cap", "fedora": "fedora", "headband": "headband",
       "bandana": "bandana", "hood": "hood", "helmet": "helmet"}     # 그리는 모자(make_models · puppet3d _hat)
# 전인물 외형(2026-11-06) — looks.json 의 모든 id 가 외형 이름을 갖는다. 위 NAMES 에 없는 id 는 이름 = id · 대표 차림(None)이고
# 장 표에 쓰이지 않는 '명부(roster)' 인물이라 그림은 assets/roster/ 에 둔다(APK 에서 뺀다 — export_presets.cfg exclude_filter).
# 키 · 체격 · 무기 · 자세(이 판 소유 칸)는 looks.json build · weapons 에서 기본값을 셈한다(game_fields()) — 손 값(LOOKS)이 있는 이름은 손 값.
# 여성: looks.json 인물 gender(m · f — castle_common 76차). gender 가 없는 기록(무리 인물)만 아래 목록(75차까지 look 글로 고른 것)으로
FEMALE = {"chasumin", "iriwon", "lingling", "marina", "ojiin", "risa", "yusehui"}


def is_female(rec):
    g = rec.get("gender")
    return g == "f" if g in ("m", "f") else rec.get("id") in FEMALE
# looks.json weapon kind → 이 판 무기(src/view/puppet3d.gd _attach). 맞는 것이 없으면 맨손("")
WEAPON = {"knuckles": "knuckles", "combat_knife": "combat", "knife": "gerber", "karambit": "combat", "sashimi_knife": "sashimi",
          "dagger": "tanto", "tanto": "tanto", "katana": "katana", "tachi": "tachi", "sword": "katana", "machete": "sashimi",
          "pipe": "pipe", "bat": "bat", "baton": "baton", "pistol": "pistol", "revolver": "revolver", "smg": "uzi"}
GUNS = ("pistol", "revolver", "uzi")
LONG = ("katana", "tachi", "pipe", "bat")
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


def skin(h, roster=False):
    """밝기만 조각에서(색 조명의 색조는 버림) — 살빛 색조 · 채도에 얹는다. 명부 인물(roster)은 살빛 범위 안의 조각 색조를 남기고
    밝기 위 · 아래를 좁힌다(밝은 살빛이 모두 같은 분필색으로 모이고 · 짙은 살빛이 주황으로 뜨던 것 — 전인물 외형 검토 2026-11-06)."""
    c = rgb(h)
    if not c:
        return None
    hh, ll, ss = colorsys.rgb_to_hls(*c)
    if roster:
        hue = hh if 0.0 <= hh <= 0.11 else 0.07
        return colorsys.hls_to_rgb(hue, min(0.8, max(0.28, ll * 1.06)), min(0.42, max(0.25, ss)))
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


def convert(lk, cid="", roster=False, female=False):
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
        if roster and ok in ("bomber", "track_jacket", "hoodie", "parka", "padded", "cardigan"):
            d["outfit"] = "jacket"       # 캐주얼 겉옷 — 깃 · 넥타이 없이 좁은 앞섶
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
    elif shirt.get("kind") == "tshirt" or (roster and (shirt.get("kind") in ("knit", "tank") or (shirt.get("kind") == "none" and ok not in (None, "none")))):
        d["collar"] = "crew"             # 둥근 목 티 · 니트 · 민소매 — 단추 · 목 V 없음
    if roster and shirt.get("kind") == "tank" and (not ok or ok == "none"):
        d["sleeveless"] = True           # 민소매 — 팔 맨살
    if roster and shirt.get("kind") == "none" and (not ok or ok == "none"):
        d["shirt"] = d["suit"] = skin(h.get("skin"), True) or SKIN_BASE    # 웃통을 벗음
    if lift(rgb(pants.get("color"))):
        d["pants"] = lift(rgb(pants.get("color")))
    d["skirt"] = pants.get("kind") in ("skirt", "dress")
    if roster and pants.get("kind") == "shorts":
        d["shorts"] = True
    if "tie" in o:
        d["tie"] = lift(rgb(o.get("tie")))          # None = 넥타이 없음
    if skin(h.get("skin"), roster):
        d["skin"] = skin(h.get("skin"), roster)
    if lift(rgb(h.get("hair_color")), 1.05):
        d["hair"] = lift(rgb(h.get("hair_color")), 1.05)
    if rgb(h.get("hair_color2")):
        d["hair2"] = rgb(h.get("hair_color2"))
    if h.get("hair_style") in HAIR:
        d["hair_style"] = HAIR[h["hair_style"]]
    if roster:
        hs, hl = h.get("hair_style"), h.get("hair_len")
        if hs == "messy":
            d["hair_style"] = "messy"     # 흐트러진 가닥(곱슬 뭉치 아님 — 검토 2026-11-06)
        elif hs == "wavy":
            d["hair_style"] = "long" if hl in ("medium", "long") else "wavy_back"
        elif hs == "dreads":
            d["hair_style"] = "undercut"  # 옆을 민 정수리 드레드 + 뒤로 묶은 꼬리(hair_long)
            d["hair2"] = lift(rgb(h.get("hair_color")), 0.8) or (0.1, 0.1, 0.1)
        elif hs == "bald" and hl == "shaved" and rgb(h.get("hair_color")):
            d["hair_style"] = "buzz"      # 짧게 민 머리(회색 대머리 — 샤이어)
        d["hair_long"] = hl == "long" or (hs == "dreads")
    g = h.get("glasses")
    fr = rgb((g or {}).get("frame")) or (rgb((g or {}).get("frame_color")) if roster else None)
    if g and g.get("lens") == "clear":    # 맑은 렌즈 — 선글라스처럼 검게 그리지 않는다(테 색만)
        d["glasses"] = True
        if fr:
            d["frame"] = fr
    elif g:
        lens = rgb(g.get("lens"))
        d["glasses"] = SUN.get(g.get("kind"), "sun" if lens else True)
        if g.get("kind") == "rimless":
            d["glasses"] = True           # 무테 — 맑은 안경 모양에 테 = 알 색(백도찬 — 빛 반사로 하얀 알)
            d["frame"] = lens or (0.9, 0.92, 0.94)
        if roster and g.get("kind") == "goggles":
            d["glasses"] = "goggles"      # 두 눈을 한 띠로 덮는 스포츠 고글
        if lens:
            d["lens"] = lens
        if roster and fr:
            d["frame"] = fr
    else:
        d["glasses"] = False
    d["piercing"] = bool(h.get("piercings"))
    sl = h.get("scars") or []
    scars = [s.get("where") for s in sl]
    two = any("두 줄" in str(s.get("note", "")) for s in sl if s.get("where") in ("left_cheek", "right_cheek"))
    # 흉터 자리(+ 로 여럿 — make_models · puppet3d _scar 가 가는 선으로 그린다): double 왼뺨 두 줄 · nose 콧등 ~ 왼뺨 + 턱 ·
    # eye_l · eye_r 눈 세로 · brow 이마 · cheek_l · cheek_r 뺨 사선 한 줄 · chin 입술 아래 ~ 턱
    kinds = []
    if len([s for s in scars if s in ("left_cheek", "right_cheek")]) >= 2 or two:
        kinds.append("double")
    elif "nose_bridge" in scars:
        kinds.append("nose")
        if roster and "right_cheek" in scars:
            kinds.append("cheek_r")
    elif "left_cheek" in scars:
        kinds.append("cheek_l")
    elif "right_cheek" in scars:
        kinds.append("cheek_r")
    if "left_eye" in scars or "right_eye" in scars:
        kinds.append("eye_l" if "left_eye" in scars else "eye_r")    # 눈썹 위에서 눈을 지나 뺨으로 세로 한 줄(황보민철)
        if roster and "left_eye" in scars and "right_eye" in scars:
            kinds.append("eye_r")
    if "forehead" in scars:
        kinds.append("brow")
    if ("lip" in scars or "chin" in scars) and "nose" not in kinds:
        kinds.append("chin")
    if roster and "head" in scars:
        kinds.append("head")              # 정수리 · 옆머리 흉터
    d["scar"] = "+".join(kinds) if kinds else False
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
    if rgb((h.get("makeup") or {}).get("lips")):       # 입술 색(76차 head.makeup.lips — 링링 · 리사 · 오지인)
        d["lips"] = rgb(h["makeup"]["lips"])
    if rgb(h.get("facial_hair_color")):                 # 수염 색(76차 — 없으면 머리색)
        d["beard_col"] = lift(rgb(h["facial_hair_color"]), 1.05)
    if h.get("blank_eyes"):
        d["blank_eyes"] = True                           # 동공 없이 흰자(샤모)
    inner = o.get("inner") or {}
    if inner.get("kind") not in (None, "none") and ok in ("long_coat", "trench_coat", "robe", "leather_jacket", "suit_jacket"):
        d["inner"] = lift(rgb(inner.get("color"))) or (0.2, 0.22, 0.28)   # 겉옷 안 정장(76차 outfit.inner — 크로트 · 구스타프 11장)
    if female:
        d["female"] = True
        d.setdefault("lips", (0.72, 0.32, 0.34))
    if roster:
        shoes = o.get("shoes") or {}
        if rgb(shoes.get("color")):
            d["shoe"] = lift(rgb(shoes.get("color")))
            if shoes.get("kind") == "sneakers" and max(rgb(shoes["color"])) > 0.7:
                d["sole"] = rgb(shoes["color"])
        if rgb(o.get("gloves")):
            d["gloves"] = lift(rgb(o.get("gloves")))
        if pants.get("color") is None and ok in ("suit_jacket", "blazer") and "suit" in d:
            d["pants"] = d["suit"]        # 바지 색 미상 — 정장 위아래(김황 · 김용성)
        if shirt.get("kind") == "none" and ok not in (None, "none") and "suit" in d:
            d["shirt"] = d["suit"]        # 안에 입은 것 없음 — 흰 깃을 그리지 않는다(남일호)
        if d.get("outfit") == "shirt" and shirt.get("kind") in ("knit", "turtleneck"):
            d["long_sleeve"] = True       # 긴소매 니트 — 소매를 걷지 않는다(이환)
        if ok == "vest" and "걷" in str(shirt.get("shirt_note") or ""):
            d["rolled"] = True            # 조끼 + 소매 걷은 셔츠(사인진 — 팔뚝 문신)
        for a in lk.get("accessories") or []:
            w, nt = str(a.get("where") or ""), str(a.get("note") or "")
            if a.get("kind") == "mask" and ("mouth" in w or "lower_face" in w or "코" in nt):
                d["mouth_mask"] = rgb(a.get("color")) or (0.08, 0.08, 0.09)
            if a.get("kind") == "other" and "안대" in nt:
                d["eyepatch"] = "l" if "left" in w else "r"
            if a.get("kind") == "other" and (w in ("suspenders", "shoulders") or "멜빵" in nt):
                d["suspenders"] = rgb(a.get("color")) or (0.1, 0.1, 0.11)
        if rgb((acc.get("belt_buckle") or {}).get("color")):
            d["buckle"] = rgb(acc["belt_buckle"]["color"])   # 버클 색(불곰 금 버클)
        if "necklace" in acc and d["chain"] is None:
            d["chain"] = rgb(acc["necklace"].get("color")) or GOLD
        if "cigar" in acc:
            d["cigar"] = True
        for k in ("bracelet", "watch"):
            if k in acc:
                d["bracelet_l"] = rgb(acc[k].get("color")) or GOLD
        if "tattoo" in acc:
            w = str(acc["tattoo"].get("where") or "")
            d["tattoo"] = rgb(acc["tattoo"].get("color")) or (0.18, 0.2, 0.26)
            d["tattoo_side"] = "both" if ("both" in w or "arms" in w) else ("l" if "left" in w else "r")
        if "bandage" in acc and "head" in str(acc["bandage"].get("where") or ""):
            d["bandage"] = (0.95, 0.95, 0.93)
        if any(p.get("where") in ("lip", "brow", "nose") for p in h.get("piercings") or []):
            d["face_ring"] = rgb((h.get("piercings") or [{}])[0].get("color")) or (0.8, 0.66, 0.3)
    return d


def game_fields(lk, cid, fem=False):
    """명부 인물의 이 판 소유 칸(키 · 체격 · 무기 · 자세) 기본값 — build.rel_height · rel_bulk · frame 을 김신(1.0 · 1.0 = scale 1.04 ·
    shoulder 1.12 · depth 1.1 · limb 1.15 — looks.gd LOOKS kim)에 견준다. 무기는 weapons 의 첫 근접 무기(없으면 총)를 오른손,
    양손(hands both) · 왼손 무기가 있으면 왼손에도."""
    b = lk.get("build") or {}
    h = float(b.get("rel_height") or 1.0)
    k = float(b.get("rel_bulk") or 1.0)
    frame = b.get("frame") or "normal"
    cl = lambda v, lo, hi: round(max(lo, min(hi, v)), 3)
    wide = cl(1.0 + (k - 1.0) * 1.5 + (0.1 if frame == "fat" else 0.0), 0.8, 1.55)
    sh = {"broad": 0.1, "narrow": -0.08}.get(b.get("shoulders"), 0.03)
    limb = 1.15 + (k - 1.0) * 1.3 + {"thick": 0.06, "thin": -0.08}.get(b.get("limbs"), 0.0)
    eyes = (lk.get("head") or {}).get("eyes")
    out = {"scale": cl(1.04 * h, 0.8, 1.3), "wide": wide, "shoulder": cl(wide + sh - (0.06 if fem else 0.0), 0.78, 1.6),
           "depth": cl(1.1 + (k - 1.0) * 1.6 + (0.15 if frame == "fat" else 0.0), 0.82, 1.6), "limb": cl(limb, 0.72, 1.6),
           "head": 0.95 if frame in ("huge", "fat") else (1.0 if h < 0.85 else 0.93), "big": frame in ("huge", "fat"),
           "jaw": not fem and (lk.get("head") or {}).get("jaw") in ("square", None) and frame != "slim",
           "eye_h": {"narrow": 0.005, "closed": 0.005, "sharp": 0.008}.get(eyes, 0.011),
           "brow_k": {"thick": 1.4, "thin": 0.7}.get((lk.get("head") or {}).get("brows"), 1.0),
           "buckle": (0.2, 0.2, 0.22)}
    ws = [w for w in lk.get("weapons") or [] if WEAPON.get(w.get("kind"))]
    melee = [w for w in ws if WEAPON[w["kind"]] not in GUNS]
    main = (melee or ws or [None])[0]
    r = WEAPON[main["kind"]] if main else ""
    l = ""
    if main and main.get("hands") == "both" and main.get("grip") != "two_hand" and r not in LONG:
        l = r
    for w in ws:
        if w is not main and w.get("hands") == "left" and not l:
            l = WEAPON[w["kind"]]
    # 목록 순서 = 대표 무기(검토 2026-11-06 — 칼을 먼저 골라 총이 대표인 인물(크롯 · 메드베디 …)의 총이 빠지던 것). 손(hands)을 따른다
    r, l = "", ""
    for w in ws:
        k = WEAPON[w["kind"]]
        if "식칼" in str(w.get("name")) or "클리버" in str(w.get("name")):
            k = "sashimi"
        hand = w.get("hands") or "right"
        if hand == "left" and not l:
            l = k
        elif hand in ("right", "both") and not r:
            r = k
            if hand == "both" and w.get("grip") != "two_hand" and k not in LONG and not l:
                l = k
        elif not l and hand != "left" and k in GUNS and r not in GUNS and r not in LONG:
            l = k                         # 칼 + 총 — 총은 왼손
    if l and not r:
        r, l = l, ""                      # 왼손 무기만 — 이 판 자세는 오른손이 치는 손(왼손잡이는 맞춰 두지 않음)
    main = next((w for w in ws if WEAPON[w["kind"]] == r), None)
    out["weapon_r"], out["weapon_l"] = r, l
    if l and (main or {}).get("grip") in ("forward", "both") or l in GUNS:
        out["grip_l"] = "fwd"
    out["guard"] = "long" if r in LONG else ("baek" if r else "box")
    return out


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
    roster = [cid for cid in sorted(looks) if cid not in {c for c, _w in NAMES.values()}]
    names = dict(NAMES, **{cid: (cid, None) for cid in roster})
    lines = ['extends RefCounted',
             '## 생성물 — tools/looks_from_common.py 가 만든다(손으로 고치지 않는다). castle_common data/looks.json(원작 조각 대조 ·',
             '## 사용자 답58)의 겉모습 칸 — looks.gd look() 이 LOOKS 위에 덮는다. 키 · 체격 · 무기 · 자세는 LOOKS 가 정한다.',
             '', 'const BY_NAME := {']
    for name in sorted(names):
        cid, when = names[name]
        if cid not in looks:
            continue
        d = keep_hand(convert(pick(looks[cid], when), cid, name in roster, is_female(looks[cid])), hands.get(name, {}), KEEP.get(name, ()))
        body = ", ".join("%s: %s" % (json.dumps(k), gd(v)) for k, v in sorted(d.items()))
        lines.append('\t"%s": {%s},  # %s%s' % (name, body, cid, " · " + when if when else ""))
    lines += ['}', '',
              '## 명부(roster) 인물 — 장 표에 아직 안 쓰는 looks.json 인물(이름 = id · 대표 차림). 이 판 소유 칸 기본값(game_fields() — build · weapons).',
              '## 그림은 assets/roster/models/<이름>_a.glb · assets/roster/sprites/<이름>_b(APK 에서 뺀다 — 편집기 · 시험에서만 있다)',
              'const ROSTER := {']
    for cid in roster:
        body_d = game_fields(looks[cid]["base"], cid, is_female(looks[cid]))
        lines.append('\t"%s": {%s},' % (cid, ", ".join("%s: %s" % (json.dumps(k), gd(v)) for k, v in sorted(body_d.items()))))
    lines += ['}', '', '## looks.json id → 이 판 외형 이름(대표 차림 — 장 차림 이름이 따로 있어도 None 차림 이름을 먼저)', 'const ID_NAME := {']
    idn = {}
    for name in sorted(names, key=lambda n: (names[n][1] is not None, n)):
        idn.setdefault(names[name][0], name)
    for cid in sorted(idn):
        if cid in looks:
            lines.append('\t"%s": "%s",' % (cid, idn[cid]))
    lines += ['}', '']
    return "\n".join(lines)


def roster_ids():
    with open(SRC, encoding="utf-8") as f:
        looks = {r["id"] for r in json.load(f)["looks"]}
    return sorted(i for i in looks if i not in {c for c, _w in NAMES.values()})


def roster_count():
    return len(roster_ids())


def missing_art():
    """명부 인물마다 GLB · 도트 시트(png · json)가 있는가 — verify 외형 생성물 줄."""
    out = []
    for cid in roster_ids():
        for rel in ("models/%s_a.glb" % cid, "sprites/%s_b.png" % cid, "sprites/%s_b.json" % cid):
            if not os.path.exists(os.path.join(ROOT, "assets", "roster", rel)):
                out.append(rel)
    return out


def main():
    text = build()
    if "--check" in sys.argv:
        with open(OUT, encoding="utf-8") as f:
            if f.read() != text:
                print("src/view/looks_common.gd 가 data/common/looks.json 과 다르다 — python3.11 tools/looks_from_common.py")
                return 1
        miss = missing_art()
        if miss:
            print("명부 그림이 없다(%d): %s — tools/make_models.gd · make_sprites.gd" % (len(miss), ", ".join(miss[:8])))
            return 1
        print("looks_common.gd 최신 · 명부 그림 %d명" % roster_count())
        return 0
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("wrote", os.path.relpath(OUT, ROOT), text.count("\n"), "lines")
    return 0


if __name__ == "__main__":
    sys.exit(main())
