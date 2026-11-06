extends RefCounted
## 생성물 — tools/looks_from_common.py 가 만든다(손으로 고치지 않는다). castle_common data/looks.json(원작 조각 대조 ·
## 사용자 답58)의 겉모습 칸 — looks.gd look() 이 LOOKS 위에 덮는다. 키 · 체격 · 무기 · 자세는 LOOKS 가 정한다.

const BY_NAME := {
	"baek": {"badge": null, "beard": false, "chain": null, "glasses": "sun", "goatee": false, "hair": Color(0.292, 0.251, 0.251), "hair_style": "slick_fringe", "lens": Color(0.933, 0.949, 0.965), "mustache": false, "outfit": "shirt", "piercing": false, "scar": false, "tie": null},  # baekdochan · 6
	"ds_suit": {"badge": null, "beard": true, "chain": null, "collar": "open", "glasses": false, "goatee": false, "hair_style": "short", "holster": null, "mustache": false, "piercing": false, "scar": false, "tie": null},  # _ds_member
	"g4": {"badge": null, "beard": false, "chain": null, "glasses": false, "goatee": false, "hair_style": "crew", "holster": null, "mustache": false, "piercing": false, "scar": false},  # _castle_g4
	"g4_leader": {"badge": null, "beard": false, "chain": null, "glasses": false, "goatee": false, "hair": Color(0.8, 0.78, 0.776), "hair_style": "crew", "holster": null, "mustache": false, "piercing": false, "scar": false},  # _castle_g4 · 리더
	"gangmanjae": {"badge": null, "beard": false, "chain": null, "collar": "open", "glasses": false, "goatee": false, "hair": Color(0.3, 0.296, 0.288), "hair_style": "crew", "holster": null, "mustache": false, "pants": Color(0.91, 0.894, 0.847), "piercing": true, "scar": true, "shirt": Color(0.42, 0.38, 0.565), "skin": Color(0.923, 0.85, 0.797), "tie": null},  # gangmanjae · 1
	"guard": {"badge": null, "beard": false, "chain": null, "glasses": false, "goatee": false, "hair_style": "slick", "holster": null, "mustache": false, "piercing": false, "scar": false},  # _castle_guard
	"guilhwa": {"badge": null, "beard": false, "chain": null, "collar": "turtle", "glasses": false, "goatee": false, "hair_style": "topknot", "holster": null, "mustache": true, "outfit": "coat", "piercing": false, "scar": "brow", "shirt": Color(0.231, 0.222, 0.231), "suit": Color(0.481, 0.358, 0.354), "tie": null},  # guilhwa · 11
	"gunter": {"badge": null, "beard": false, "chain": null, "glasses": false, "goatee": false, "hair": Color(0.706, 0.663, 0.616), "hair_style": "slick", "holster": null, "mustache": true, "outfit": "robe", "piercing": false, "scar": "brow", "tie": null},  # gunter · 0
	"hayabusa": {"badge": null, "beard": false, "chain": null, "glasses": false, "goatee": false, "hair_style": "wavy_back", "holster": null, "mustache": false, "piercing": false, "scar": false, "tie": null},  # hayabusa · 11
	"jintae": {"badge": null, "beard": false, "chain": null, "glasses": "sun", "goatee": false, "hair": Color(0.749, 0.718, 0.624), "holster": null, "mustache": false, "piercing": true, "scar": false, "tie": null},  # jintae · 1
	"kim": {"beard": false, "chain": null, "glasses": false, "goatee": false, "hair_style": "slick_fringe", "holster": null, "mustache": false, "piercing": true, "scar": true},  # kimshin
	"kimdaegeon": {"badge": null, "beard": false, "chain": null, "collar": "open", "glasses": false, "goatee": false, "hair_style": "crew", "holster": null, "mustache": false, "piercing": false, "scar": true, "tie": null},  # kimdaegeon · 1
	"kimhyeokju": {"badge": null, "beard": false, "collar": "open", "glasses": false, "goatee": false, "hair_style": "ponytail", "holster": null, "mustache": false, "piercing": false, "scar": true, "skin": Color(0.901, 0.807, 0.738), "tie": null},  # kimhyeokju · 1
	"kimseongjun": {"badge": null, "beard": false, "chain": null, "collar": "open", "glasses": false, "goatee": true, "hair_style": "curly", "holster": null, "mustache": false, "outfit": "coat", "piercing": true, "scar": false, "tie": null},  # kimseongjun · 1
	"shingen": {"badge": null, "beard": false, "chain": null, "glasses": false, "goatee": true, "hair_style": "spiky", "holster": null, "mustache": false, "piercing": false, "scar": false},  # shingen · 11
	"woojin": {"badge": null, "beard": false, "chain": null, "collar": "open", "glasses": "sun", "goatee": false, "holster": null, "lens": Color(0.165, 0.141, 0.149), "mustache": false, "piercing": true, "scar": "nose", "tie": null},  # woojin · 11
	"yundeoksu": {"badge": null, "beard": false, "chain": null, "glasses": false, "goatee": false, "hair_style": "undercut", "holster": null, "mustache": false, "pants": Color(0.91, 0.878, 0.8), "piercing": true, "scar": false, "tie": Color(0.0947, 0.0947, 0.0947)},  # yundeoksu · 1
}
