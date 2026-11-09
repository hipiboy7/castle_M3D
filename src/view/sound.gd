extends Node
## 소리 — 효과음 8채널 · 음악 1채널. 창 없는 점검(headless)에서는 내지 않는다(가짜 오디오가 끝날 때 재생 객체를 붙잡는다).
## 일시정지(get_tree().paused) 때 같이 멈춘다(PAUSABLE). 소리 파일 출처는 assets/ASSETS.md.

const SFX := ["knife", "swing", "slash", "hit", "hit_heavy", "kick", "guard", "counter", "miss", "ko", "wind", "step",
	"shine", "fall", "shot"]

var headless := false
var sfx := {}
var players: Array = []
var music: AudioStreamPlayer
var current := ""               # 지금 곡 이름(같은 곡을 처음부터 다시 틀지 않게 — main.gd _music)


func setup(is_headless: bool) -> void:
	headless = is_headless
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for n in SFX:
		var path := "res://assets/sfx/%s.wav" % n
		if ResourceLoader.exists(path):
			sfx[n] = load(path)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music = AudioStreamPlayer.new()
	music.volume_db = -9.0
	add_child(music)


func play(n: String, db := 0.0, pitch := 1.0) -> void:
	if headless or not sfx.has(n):
		return
	for p in players:
		if not p.playing:
			p.stream = sfx[n]
			p.volume_db = db
			p.pitch_scale = pitch
			p.play()
			return


func song(n: String, loop := true) -> void:
	current = n
	if headless:
		return
	var s = load("res://assets/music/%s.ogg" % n)
	s.loop = loop
	music.stream = s
	music.play()


func song_playing() -> bool:
	return music.playing
