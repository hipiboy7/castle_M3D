extends RefCounted
## 2D 웹툰 포트레이트 · 컷인 레지스트리(OCP — 새 인물 추가 시 SPECS · ALIASES 에 한 줄만 추가).
## assets/portraits/<id>_{stand,hud,cutin}.png 를 캐싱하며, 헤드리스 · 미등록 인물은 안전하게 null 반환.

const ALIASES := {
	"kimshin": "kimshin",
	"kim": "kimshin",
	"kim_bare": "kimshin",
	"kim_coat": "kimshin",
	"kim_p1_blade": "kimshin",
	"baekdochan": "baekdochan",
	"baek": "baekdochan",
	"risa": "risa",
	"risa_p1": "risa",
	"jintae": "jintae",
	"seojintae": "jintae",
	"ojiin": "ojiin",
	"client_woman": "client_woman",
}

const SPECS := {
	"kimshin": {
		"stand": "res://assets/portraits/kimshin_stand.png",
		"hud": "res://assets/portraits/kimshin_hud.png",
		"cutin": "res://assets/portraits/kimshin_cutin.png",
		"accent": Color(0.28, 0.80, 0.98),
		"faces_right": false,
		"prefer_right": false,
	},
	"baekdochan": {
		"stand": "res://assets/portraits/baekdochan_stand.png",
		"hud": "res://assets/portraits/baekdochan_hud.png",
		"cutin": "res://assets/portraits/baekdochan_cutin.png",
		"accent": Color(0.92, 0.16, 0.20),
		"faces_right": false,
		"prefer_right": true,
	},
	"risa": {
		"stand": "res://assets/portraits/risa_stand.png",
		"hud": "res://assets/portraits/risa_hud.png",
		"cutin": "",
		"accent": Color(0.94, 0.74, 0.34),
		"faces_right": false,
		"prefer_right": true,
	},
	"jintae": {
		"stand": "res://assets/portraits/jintae_stand.png",
		"hud": "res://assets/portraits/jintae_hud.png",
		"cutin": "res://assets/portraits/jintae_cutin.png",
		"accent": Color(0.98, 0.76, 0.18),
		"faces_right": true,
		"prefer_right": false,
	},
	"ojiin": {
		"stand": "res://assets/portraits/ojiin_stand.png",
		"hud": "res://assets/portraits/ojiin_hud.png",
		"cutin": "res://assets/portraits/ojiin_cutin.png",
		"accent": Color(0.86, 0.18, 0.30),
		"faces_right": false,
		"prefer_right": true,
	},
	"client_woman": {
		"stand": "res://assets/portraits/client_woman_stand.png",
		"hud": "res://assets/portraits/client_woman_hud.png",
		"cutin": "",
		"accent": Color(0.78, 0.70, 0.64),
		"faces_right": true,
		"prefer_right": false,
	},
}

static var _tex_cache := {}


## 인물 id 또는 외형 이름(look) → 포트레이트 키(없으면 "")
static func key_of(id_or_look: String) -> String:
	if id_or_look == "":
		return ""
	var clean := id_or_look.strip_edges().to_lower()
	if clean.ends_with("_a") or clean.ends_with("_b"):
		clean = clean.left(-2)
	return str(ALIASES.get(clean, ""))


static func has_stand(id_or_look: String) -> bool:
	var k := key_of(id_or_look)
	return k != "" and str(SPECS[k].get("stand", "")) != ""


static func has_hud(id_or_look: String) -> bool:
	var k := key_of(id_or_look)
	return k != "" and str(SPECS[k].get("hud", "")) != ""


static func has_cutin(id_or_look: String) -> bool:
	var k := key_of(id_or_look)
	return k != "" and str(SPECS[k].get("cutin", "")) != ""


static func stand_path(id_or_look: String) -> String:
	var k := key_of(id_or_look)
	return str(SPECS[k].get("stand", "")) if k != "" else ""


static func hud_path(id_or_look: String) -> String:
	var k := key_of(id_or_look)
	return str(SPECS[k].get("hud", "")) if k != "" else ""


static func cutin_path(id_or_look: String) -> String:
	var k := key_of(id_or_look)
	return str(SPECS[k].get("cutin", "")) if k != "" else ""


static func accent_color(id_or_look: String) -> Color:
	var k := key_of(id_or_look)
	return SPECS[k]["accent"] as Color if k != "" else Color(0.88, 0.16, 0.18)


## 대화 스탠딩 기본 좌우 배치(-1 왼쪽 · +1 오른쪽): 적군 · 보스 · 리사/오지인은 오른쪽, 아군 · 김신 · 의뢰인은 왼쪽
static func side_of(id_or_look: String, team := 0) -> int:
	if team != 0:
		return 1
	var k := key_of(id_or_look)
	if k != "" and bool(SPECS[k].get("prefer_right", false)):
		return 1
	return -1


## 배치된 쪽(side: -1 왼쪽 / +1 오른쪽)에서 화면 중앙을 바라보도록 좌우 반전 여부 결정
static func should_flip(id_or_look: String, side: int) -> bool:
	var k := key_of(id_or_look)
	if k == "":
		return false
	var faces_right: bool = bool(SPECS[k].get("faces_right", true))
	return (side < 0) != faces_right


## 텍스처 로드 + 정적 캐시(헤드리스에서는 GPU 텍스처 로드 생략)
static func _load_tex(path: String) -> Texture2D:
	if path == "" or DisplayServer.get_name() == "headless":
		return null
	if _tex_cache.has(path):
		return _tex_cache[path] as Texture2D
	if not ResourceLoader.exists(path):
		_tex_cache[path] = null
		return null
	var res = load(path)
	var tex: Texture2D = res as Texture2D if res is Texture2D else null
	_tex_cache[path] = tex
	return tex


static func stand_tex(id_or_look: String) -> Texture2D:
	return _load_tex(stand_path(id_or_look))


static func hud_tex(id_or_look: String) -> Texture2D:
	return _load_tex(hud_path(id_or_look))


static func cutin_tex(id_or_look: String) -> Texture2D:
	return _load_tex(cutin_path(id_or_look))
