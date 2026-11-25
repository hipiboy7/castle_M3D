extends RefCounted
## 2D 원작 웹툰(정연 「캐슬」) 포트레이트 · 컷인 레지스트리(OCP — portraits_data.gd 113인 원작 자산 자동 등록).
## assets/portraits/<id>_{stand,hud,cutin}.jpg 를 캐싱하며, 헤드리스 · 미등록 인물은 안전하게 null 반환.

const Data = preload("res://src/view/portraits_data.gd")
const Common = preload("res://src/data/common.gd")
const Addendum = preload("res://src/data/addendum.gd")

const SPECS := Data.SPECS

const ALIASES := {
	"kimshin": "kimshin",
	"kim": "kimshin",
	"kim_bare": "kimshin",
	"kim_coat": "kimshin",
	"kim_p1_blade": "kimshin",
	"kimshin_coat": "kimshin",
	"kimshin_shadow": "kimshin_shadow",
	"baekdochan": "baekdochan",
	"baek": "baekdochan",
	"risa": "risa",
	"risa_p1": "risa",
	"jintae": "jintae",
	"seojintae": "jintae",
	"ojiin": "ojiin",
	"client_woman": "client_woman",
	"piwoojin": "woojin",
	"woojin": "woojin",
	"shingen": "shingen",
	"sasakishingen": "shingen",
}

const NAME_ALIASES := {
	"김신": "kimshin",
	"아무르 티그로": "kimshin",
	"백도찬": "baekdochan",
	"파이톤": "baekdochan",
	"리사": "risa",
	"서진태": "jintae",
	"사로카": "jintae",
	"오지인": "ojiin",
	"의뢰인": "client_woman",
	"의뢰인 여성": "client_woman",
	"피우진": "woojin",
	"사사키 신겐": "shingen",
	"신겐": "shingen",
	"군터": "gunter",
	"윤덕수": "yundeoksu",
	"김대건": "kimdaegeon",
	"차수민": "chasumin",
	"김혁주": "kimhyeokju",
	"김성준": "kimseongjun",
	"강만재": "gangmanjae",
	"강창석": "gangchangseok",
	"이슬": "iseul",
	"인수": "insu",
	"신태진": "sintaejin",
	"남궁혁": "namgunghyuk",
	"황보민철": "hwangbomincheol",
	"김재훈": "kimjaehoon",
	"김태훈": "kimtaehoon",
	"김용성": "kimyongseong",
	"류지학": "ryujihak",
	"최민욱": "choeminuk",
	"마학영": "mahakyoung",
	"마준영": "majunyeong",
	"구일화": "guilhwa",
	"하야부사": "hayabusa",
	"천일도": "cheonildo",
	"주로": "juro",
	"유우성": "yuwoosung",
	"도우첸": "douchen",
	"링링": "lingling",
	"리천": "richeon",
	"구스타프": "gustav",
	"아킬라": "akila",
	"그롤라": "grolla",
	"바실리": "vasily",
	"크리샤": "keurisa",
	"표영": "pyoyoung",
	"강민성": "gangminseong",
	"임무열": "immuyeol",
	"히데": "hide",
	"코모도": "komodo",
	"바리스타": "barista",
	"이희성": "ihuiseong",
	"여민수": "yeominsu",
	"크로트": "krot",
	"블랙맘바": "blackmamba",
	"메드베디": "medvedi",
	"라텔": "ratel",
	"마크": "mark",
	"스케일단장": "scaledanjang",
	"앤디청": "andycheong",
	"현석": "hyeonseok",
	"최달천": "choedalcheon",
	"사인진": "sainjin",
	"정단": "jeongdan",
	"이와시로": "iwashiro",
	"야마모토 쿄지": "yamamotokyoji",
	"쿄지": "yamamotokyoji",
}

static var _tex_cache := {}
static var _name_map: Dictionary = {}


## 인물 id 또는 외형 이름(look) → 포트레이트 키(없으면 "")
static func key_of(id_or_look: String) -> String:
	if id_or_look == "":
		return ""
	var clean := id_or_look.strip_edges().to_lower()
	if clean.ends_with("_a") or clean.ends_with("_b"):
		clean = clean.left(-2)
	if ALIASES.has(clean):
		var mapped := str(ALIASES[clean])
		return mapped if SPECS.has(mapped) else ""
	if SPECS.has(clean):
		return clean
	return ""


## 한글 표시 이름("김신" · "리사" · "백도찬" 등) → 포트레이트 키(없으면 "")
static func key_by_name(display_name: String) -> String:
	var nm := display_name.strip_edges()
	if nm == "":
		return ""
	if NAME_ALIASES.has(nm):
		return key_of(str(NAME_ALIASES[nm]))
	if _name_map.is_empty():
		_build_name_map()
	if _name_map.has(nm):
		return str(_name_map[nm])
	return key_of(nm)


static func _build_name_map() -> void:
	for id in SPECS.keys():
		var c := Addendum.character(str(id))
		var nm := str(c.get("name", "")).strip_edges()
		if nm != "":
			_name_map[nm] = str(id)
	for k in NAME_ALIASES:
		_name_map[k] = str(NAME_ALIASES[k])


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
	var faces_right: bool = bool(SPECS[k].get("faces_right", false))
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


## 종료 시 정적 캐시 해제(Godot 4.7 종료 ObjectDB / Resource leak 방지)
static func clear_cache() -> void:
	_tex_cache.clear()
	_name_map.clear()
