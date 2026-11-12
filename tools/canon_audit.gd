extends SceneTree
## 원작 대사 어긋남 점검(창 없음): <godot> --headless --path . -s res://tools/canon_audit.gd -- [장 id ..]
## 방마다 lines.json <장>.canon.<방> 의 open · mid · close 가 실제로 그 방에서 어떻게 도는지 —
##  · 말하는 사람이 방에 없으면 게임이 건너뛴다(scene.gd who_of) → 건너뛰는 줄 비율 · 사람
##  · 손으로 쓴 장면(방 scene · triggers scene · talk)이 있으면 open(· close)은 안 돈다
##  · 반 넘게 빠지는 대목은 게임이 통째로 안 튼다(stage.gd canon_keep — 같은 규칙으로 센다) → (뺌)
## 앞의 [뺌] = 그런 대목이 있는 방. 남은 대목도 내용이 방과 맞는지는 사람이 본다(tools/canon_lines.py)
const Stage = preload("res://src/combat/stage.gd")
const Campaign = preload("res://src/data/campaign.gd")
const Lines = preload("res://src/data/lines.gd")


func _initialize() -> void:
	var chs: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("ch"):
			chs.append(a)
	if chs.is_empty():
		chs = Campaign.ids().filter(func(i): return Campaign.kind(i) == "stage")
	var flagged := 0
	var total := 0
	for ch in chs:
		var T = Campaign.table(ch)
		for i in T.ROOMS.size():
			var room: Dictionary = T.ROOMS[i]
			var d := Stage.make(1, {"chapter": ch, "room": i})
			var canon = Lines.at("%s.canon.%s" % [T.LINES, room["id"]])
			if not (canon is Dictionary):
				continue
			total += 1
			var here := {}
			for f in d["world"].fighters:
				here[f.char_id] = true
			for v in d.get("tag_of", {}).values():
				here[str(v)] = true
			var later := str(room.get("triggers", []))      # 방 안에서 나중에 서는 사람(triggers spawn — close 때는 있다)
			var hand_open: bool = room.has("scene") or room.has("talk")
			var hand_close: bool = room.get("triggers", []).any(func(t): return t.has("scene")) or room.has("talk")
			var is_here := func(id: String) -> bool: return here.has(id) or later.contains('"%s"' % id)
			var parts := []
			var bad := false
			for part in ["open", "mid", "close"]:
				var v = canon.get(part, [])
				if v.is_empty():
					continue
				var gone := {}
				var n := 0
				for ln in v:
					if not is_here.call(str(ln[0])) and str(ln[0]) != "@" and not str(ln[0]).begins_with("?"):
						gone[str(ln[0])] = true
					else:
						n += 1
				var kept: Array = Stage.canon_keep(v, is_here)
				if part == "mid":                                   # mid 는 반씩 따로 튼다(stage.gd _canon_mid)
					var h: int = int(ceil(v.size() / 2.0))
					kept = Stage.canon_keep(v.slice(0, h), is_here) + Stage.canon_keep(v.slice(h), is_here)
				var s := "%s %d/%d" % [part, n, v.size()]
				if (part == "open" and hand_open) or (part == "close" and hand_close):
					s += "(손 장면)"
				elif kept.is_empty():
					bad = true
					s += "(뺌)"
				if not gone.is_empty():
					s += " 없음:" + ",".join(gone.keys())
				parts.append(s)
			if bad:
				flagged += 1
			print("%s%s %s[%d] — %s" % ["[뺌] " if bad else "", ch, room["id"], i, " · ".join(parts)])
	print("canon_audit: 방 %d · 대목을 빼는 방 %d" % [total, flagged])
	quit(0)
