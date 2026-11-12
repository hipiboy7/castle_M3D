extends RefCounted
## 사람마다 다른 공격 동작(2026-11-12 사용자 "모든 주요 캐릭터들의 공격 모션들이 다 달랐으면 좋겠어. 하나도 동일한 동작이 없도록" ·
## "무리까지해"). 동작 모양(poses.gd SHAPES — 잽 · 훅 · 앞차기 …)은 여럿이 같이 쓰므로, 그 위에 사람마다 '버릇'을 얹는다:
## 낮게 앉음 crouch · 몸 비틀기 twist · 앞으로 쏠림 lean · 팔꿈치 벌림 flare · 팔 높이 high · 안 쓰는 손 가드 tuck(- 면 내림 — 거만) ·
## 뛰어오름 hop · 고개 head · 손목 wrist · 감는 크기 wind. 값은 -1 ~ 1. 이름 있는 인물은 아래 표(성격 — 원작 싸움 묘사), 표에 없는
## 사람(무리 · 다른 이름 있는 적)은 id 글자로 정해지는 값(사람마다 다르고 늘 같다). 같은 사람 안에서도 동작마다 조금씩 다르게(move_jitter),
## 무리는 한 사람 한 사람도 조금씩(person_jitter). 그림만 — 판정 · 프레임과 상관없다(puppet_pose _attack_pose 가 자세에 더한다).

const KEYS := ["crouch", "twist", "lean", "flare", "high", "tuck", "hop", "head", "wrist", "wind"]
const MOVE_JITTER := 0.22
const PERSON_JITTER := 0.25

## 이름 있는 인물의 버릇(원작에서 보이는 싸움 결 — 연출용 판단, conf ai)
const STYLES := {
	"kimshin": {"crouch": 0.2, "twist": 0.3, "lean": 0.45, "flare": -0.35, "high": 0.0, "tuck": 0.85, "hop": 0.0, "head": -0.25, "wrist": 0.1, "wind": -0.4},     # 군더더기 없이 짧게
	"baekdochan": {"crouch": 0.55, "twist": 0.6, "lean": 0.2, "flare": -0.55, "high": -0.45, "tuck": 0.6, "hop": 0.0, "head": -0.5, "wrist": 0.4, "wind": -0.2},  # 낮은 칼 · 차가운 몸
	"woojin": {"crouch": 0.65, "twist": 0.9, "lean": 0.6, "flare": 0.15, "high": 0.1, "tuck": 0.95, "hop": 0.0, "head": 0.55, "wrist": -0.3, "wind": 0.3},       # 늑대 — 몸통 회전 · 고개 흔들기
	"jintae": {"crouch": -0.25, "twist": 0.5, "lean": -0.2, "flare": 0.55, "high": 0.3, "tuck": -0.45, "hop": 0.65, "head": 0.35, "wrist": 0.5, "wind": 0.5},    # 장난스럽게 · 발을 쓴다
	"iseul": {"crouch": 0.3, "twist": 1.0, "lean": 0.85, "flare": 0.85, "high": 0.35, "tuck": -0.3, "hop": 0.0, "head": 0.6, "wrist": -0.6, "wind": 1.0},        # 막싸움 — 크게 휘두름
	"insu": {"crouch": 0.45, "twist": 0.6, "lean": 0.5, "flare": 0.65, "high": -0.1, "tuck": 0.2, "hop": 0.1, "head": 0.2, "wrist": -0.4, "wind": 0.6},
	"guilhwa": {"crouch": 0.55, "twist": 0.8, "lean": 0.5, "flare": -0.2, "high": 0.2, "tuck": 1.0, "hop": 0.0, "head": 0.85, "wrist": 0.0, "wind": 0.1},       # 복서 — 위빙
	"pyoyoung": {"crouch": 0.95, "twist": 0.7, "lean": 0.95, "flare": 0.3, "high": -0.3, "tuck": 0.3, "hop": 0.85, "head": -0.55, "wrist": 0.8, "wind": -0.3}, # 낮게 뛰어드는 짐승
	"namgunghyuk": {"crouch": 0.2, "twist": 0.4, "lean": 0.3, "flare": -0.45, "high": 0.55, "tuck": 0.7, "hop": 0.0, "head": 0.0, "wrist": 0.2, "wind": -0.1},
	"kimdaegeon": {"crouch": 0.5, "twist": 0.65, "lean": 0.4, "flare": 0.4, "high": 0.15, "tuck": 0.3, "hop": 0.35, "head": 0.3, "wrist": -0.2, "wind": 0.45},
	"gustav": {"crouch": 0.1, "twist": 0.5, "lean": 0.65, "flare": 0.9, "high": 0.6, "tuck": -0.65, "hop": 0.0, "head": -0.65, "wrist": -0.5, "wind": 0.8},    # 거만한 거구
	"yundeoksu": {"crouch": 0.3, "twist": 0.9, "lean": 0.75, "flare": 0.7, "high": 0.2, "tuck": -0.55, "hop": 0.0, "head": 0.4, "wrist": -0.7, "wind": 0.9},
	"gangmanjae": {"crouch": 0.15, "twist": 0.7, "lean": 0.5, "flare": 0.95, "high": 0.45, "tuck": -0.2, "hop": 0.0, "head": 0.1, "wrist": -0.8, "wind": 0.7},
	"kimhyeokju": {"crouch": 0.7, "twist": 0.4, "lean": 0.7, "flare": -0.6, "high": -0.2, "tuck": 0.4, "hop": 0.2, "head": -0.3, "wrist": 0.9, "wind": -0.5},  # 잭나이프 두 자루
	"kimseongjun": {"crouch": 0.4, "twist": 0.95, "lean": 0.9, "flare": 0.3, "high": 0.4, "tuck": -0.8, "hop": 0.3, "head": 0.9, "wrist": 0.6, "wind": 0.9},   # 약에 취해 흔들림
	"sintaejin": {"crouch": 0.6, "twist": 0.85, "lean": 0.35, "flare": -0.1, "high": 0.1, "tuck": 0.0, "hop": 0.4, "head": -0.4, "wrist": 0.7, "wind": 0.2},   # 쌍칼
	"hwangbomincheol": {"crouch": 0.65, "twist": 0.55, "lean": 0.55, "flare": -0.3, "high": -0.35, "tuck": 0.5, "hop": 0.1, "head": -0.2, "wrist": 0.55, "wind": 0.0},
	"ojiin": {"crouch": 0.35, "twist": 0.2, "lean": 0.1, "flare": -0.7, "high": 0.0, "tuck": 0.9, "hop": 0.0, "head": -0.7, "wrist": 0.3, "wind": -0.7},       # 단정한 칼
	"kimjaehoon": {"crouch": -0.6, "twist": 0.3, "lean": -0.4, "flare": 0.8, "high": 0.7, "tuck": -1.0, "hop": 0.0, "head": 0.7, "wrist": -0.9, "wind": 1.0}, # 엉성한 막주먹
	"gangchangseok": {"crouch": 0.2, "twist": 0.6, "lean": 0.6, "flare": 0.2, "high": -0.2, "tuck": 0.1, "hop": 0.2, "head": 0.5, "wrist": 0.4, "wind": 0.3},
	"vasily": {"crouch": 0.85, "twist": 0.3, "lean": 1.0, "flare": 0.95, "high": -0.5, "tuck": -0.2, "hop": 0.0, "head": -0.3, "wrist": -0.3, "wind": 0.5},   # 삼보 — 붙잡으러 든다
	"keurisa": {"crouch": 0.3, "twist": 0.8, "lean": 0.2, "flare": 0.1, "high": 0.8, "tuck": 0.7, "hop": 0.75, "head": -0.6, "wrist": 0.2, "wind": 0.2},       # 이스크라 발 기술
	"medvedi": {"crouch": 0.3, "twist": 0.4, "lean": 0.7, "flare": 0.8, "high": 0.3, "tuck": 0.4, "hop": 0.0, "head": -0.2, "wrist": -0.5, "wind": 0.6},
	"ratel": {"crouch": 0.9, "twist": 0.6, "lean": 0.8, "flare": 0.2, "high": -0.6, "tuck": 0.5, "hop": 0.5, "head": 0.4, "wrist": 0.6, "wind": -0.2},
	"namilho": {"crouch": 0.45, "twist": 0.75, "lean": 0.3, "flare": -0.5, "high": 0.25, "tuck": 0.5, "hop": 0.3, "head": -0.5, "wrist": 0.85, "wind": -0.3},  # 버킷햇 칼잡이 — 잔상
	"hahoe_mask": {"crouch": 0.3, "twist": 0.9, "lean": 0.55, "flare": 0.1, "high": 0.4, "tuck": 0.85, "hop": 0.0, "head": 0.7, "wrist": 0.0, "wind": -0.2},  # 주먹 연타
	"redspot_mask": {"crouch": 0.0, "twist": 0.6, "lean": -0.1, "flare": 0.6, "high": 0.9, "tuck": 0.3, "hop": 0.6, "head": 0.3, "wrist": 0.3, "wind": 0.4}, # 높은 발차기
	"bulgom": {"crouch": 0.6, "twist": 0.5, "lean": 0.9, "flare": 1.0, "high": -0.2, "tuck": -0.4, "hop": 0.0, "head": 0.2, "wrist": -0.6, "wind": 0.9},
	"moseunggyu": {"crouch": 0.1, "twist": 0.8, "lean": 0.6, "flare": 0.75, "high": 0.5, "tuck": -0.6, "hop": 0.0, "head": 0.6, "wrist": -0.7, "wind": 0.8},
	"odohwa": {"crouch": 0.4, "twist": 1.0, "lean": 0.4, "flare": 0.5, "high": 0.9, "tuck": 0.2, "hop": 0.0, "head": -0.6, "wrist": 0.5, "wind": 1.0},        # 손도끼 큰 호
	"masa": {"crouch": 0.75, "twist": 0.45, "lean": 0.85, "flare": -0.7, "high": -0.4, "tuck": 0.6, "hop": 0.3, "head": -0.4, "wrist": 0.9, "wind": -0.6},
	"shire": {"crouch": 0.4, "twist": 0.5, "lean": 0.4, "flare": 0.5, "high": 0.0, "tuck": 0.6, "hop": 0.0, "head": 0.0, "wrist": -0.1, "wind": 0.1},
	"komodo": {"crouch": 0.8, "twist": 0.65, "lean": 0.75, "flare": -0.2, "high": -0.5, "tuck": 0.2, "hop": 0.45, "head": -0.6, "wrist": 0.85, "wind": 0.0},
	"shingen": {"crouch": 0.5, "twist": 0.35, "lean": 0.25, "flare": -0.8, "high": 0.65, "tuck": 0.8, "hop": 0.0, "head": -0.8, "wrist": 0.2, "wind": -0.6},   # 검도 — 곧게
	"mahakyoung": {"crouch": 0.2, "twist": 0.75, "lean": 0.6, "flare": 0.6, "high": 0.4, "tuck": 0.4, "hop": 0.1, "head": -0.3, "wrist": 0.4, "wind": 0.5},
	"majunyeong": {"crouch": 0.3, "twist": 0.95, "lean": 0.7, "flare": 0.8, "high": 0.2, "tuck": -0.4, "hop": 0.2, "head": 0.6, "wrist": -0.4, "wind": 0.85},
	"jeongdan": {"crouch": 0.35, "twist": 0.3, "lean": 0.2, "flare": -0.3, "high": 0.5, "tuck": 0.75, "hop": 0.0, "head": -0.5, "wrist": 0.1, "wind": -0.4},
	"gunter": {"crouch": -0.4, "twist": 0.4, "lean": -0.3, "flare": 0.6, "high": 0.6, "tuck": -0.8, "hop": 0.0, "head": -0.6, "wrist": -0.6, "wind": 0.6},
}

static var _cache := {}


## 그 사람의 버릇(값 -1 ~ 1) — 표에 있으면 표, 없으면 id 글자에서(늘 같은 값)
static func style_for(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var st := {}
	if STYLES.has(id):
		st = STYLES[id].duplicate()
	else:
		for k in KEYS:
			st[k] = _h(id + ":" + k)
	_cache[id] = st
	return st


## -1 ~ 1 의 늘 같은 값(글자 해시)
static func _h(s: String) -> float:
	var x := s.hash() & 0xffffff
	return float(x) / float(0xffffff) * 2.0 - 1.0


## 자세 p 에 버릇을 더한다. ww = 감기(준비) 무게, ws = 타격 무게(0 ~ 1), side = 1(오른손 · 발) | -1(왼),
## seed = 동작 · 사람마다 다르게 하는 글(move_jitter · person_jitter)
static func apply(p: Dictionary, st: Dictionary, ww: float, ws: float, side: float, mseed: String, pseed: String, crowd: bool) -> Dictionary:
	if ww <= 0.001 and ws <= 0.001:
		return p
	var v := {}
	for k in KEYS:
		var j := MOVE_JITTER * _h(mseed + k) + (PERSON_JITTER * _h(pseed + k) if crowd else 0.0)
		v[k] = clampf(float(st.get(k, 0.0)) + j, -1.2, 1.2)
	var r := "_r" if side > 0.0 else "_l"
	var o := "_l" if side > 0.0 else "_r"
	var q := p.duplicate()
	var wind := 1.0 + 0.6 * float(v["wind"])
	# 감기(준비): 치는 쪽 반대로 비틀고 · 조금 가라앉고 · 고개를 숙인다
	var a := ww * wind
	_add(q, "chest", Vector3(-6.0 * v["lean"], -16.0 * v["twist"] * side, 0) * a)
	_add(q, "pelvis", Vector3(0, -8.0 * v["twist"] * side, 0) * a)
	_addf(q, "kn_r", 10.0 * maxf(0.0, v["crouch"]) * a)
	_addf(q, "kn_l", 10.0 * maxf(0.0, v["crouch"]) * a)
	_add(q, "sh" + r, Vector3(-10.0 * v["high"], -12.0 * v["twist"], 8.0 * v["flare"]) * a)
	# 타격: 비틀어 풀고 · 쏠리고 · 팔꿈치 · 팔 높이 · 안 쓰는 손 · 뛰어오름 · 고개 · 손목
	var b := ws
	_add(q, "chest", Vector3(14.0 * v["lean"], 18.0 * v["twist"] * side, 6.0 * v["head"] * side) * b)
	_add(q, "pelvis", Vector3(5.0 * v["lean"], 10.0 * v["twist"] * side, 0) * b)
	_add(q, "spine", Vector3(6.0 * v["lean"], 6.0 * v["twist"] * side, 0) * b)
	_add(q, "head", Vector3(-8.0 * v["lean"] + 6.0 * v["head"], 10.0 * v["head"] * side, 14.0 * v["head"]) * b)
	_add(q, "sh" + r, Vector3(14.0 * v["high"], 6.0 * v["twist"], 22.0 * v["flare"]) * b)
	_addf(q, "el" + r, -10.0 * v["flare"] * b)
	_add(q, "wr" + r, Vector3(10.0 * v["wrist"], 40.0 * v["wrist"], 0) * b)
	_add(q, "sh" + o, Vector3(22.0 * v["tuck"], 8.0 * v["tuck"], -6.0 * v["tuck"]) * b)
	_addf(q, "el" + o, 30.0 * v["tuck"] * b)
	var c := maxf(0.0, v["crouch"]) * (a * 0.5 + b)
	_addf(q, "kn_r", 16.0 * c)
	_addf(q, "kn_l", 16.0 * c)
	_add(q, "pelvis", Vector3(6.0 * c, 0, 0))
	if v["hop"] > 0.0:
		var hp: float = v["hop"] * b
		q["root_y"] = float(q.get("root_y", 0.0)) + 0.07 * hp
		_addf(q, "kn" + o, 26.0 * hp)
	return q


static func _add(q: Dictionary, k: String, d: Vector3) -> void:
	if q.has(k):
		q[k] = (q[k] as Vector3) + d


static func _addf(q: Dictionary, k: String, d: float) -> void:
	if q.has(k):
		q[k] = float(q[k]) + d
