extends RefCounted
## 화면 대사 · 알림 글 — res://data/story/lines.json(APK 에 들어간다 — export_presets include_filter). 글을 코드에 적지 않는다.

const PATH := "res://data/story/lines.json"

static var _data := {}


static func all() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return _data


## 점으로 이은 길("ch6.fight" · "ch11.rooms.hall28.enter") → 값. 없으면 null
static func at(path: String):
	var v = all()
	for k in path.split("."):
		if not (v is Dictionary) or not v.has(k):
			return null
		v = v[k]
	return v
