extends "res://tests/helpers.gd"
## CC0 모션캡처 드라이버(src/view/mocap_driver.gd) 단위 테스트 — 상태별 클립 매핑 · 에셋 로드 검증.

const Mocap = preload("res://src/view/mocap_driver.gd")


func test_mocap_clip_selection() -> void:
	var idle := Mocap.pick_clip("idle", 0.0, false, "", "", false, true)
	check(idle["clip"] == "Idle" and bool(idle["loop"]) and float(idle["weight"]) > 0.8, "평상 대기 = Idle")
	var armed := Mocap.pick_clip("idle", 0.0, false, "", "", true, false)
	check(armed["clip"] == "Sword_Idle" and float(armed["weight"]) > 0.8, "무기 전투 대기 = Sword_Idle")
	var walk := Mocap.pick_clip("move", 1.6, false, "", "", false, false)
	check(walk["clip"] == "Walk", "보통 걷기 = Walk")
	var formal := Mocap.pick_clip("move", 1.5, false, "", "", false, true)
	check(formal["clip"] == "Walk_Formal", "여유 걷기 = Walk_Formal")
	var jog := Mocap.pick_clip("move", 3.2, false, "", "", false, false)
	check(jog["clip"] == "Jog_Fwd", "달리기 = Jog_Fwd")
	var sprint := Mocap.pick_clip("move", 4.8, false, "", "", false, false)
	check(sprint["clip"] == "Sprint", "전력 질주 = Sprint")
	var sit := Mocap.pick_clip("idle", 0.0, false, "sit", "", false, true)
	check(sit["clip"] == "Sitting_Idle", "앉기 자세 = Sitting_Idle")
	var crouch := Mocap.pick_clip("move", 1.0, true, "", "", false, false)
	check(crouch["clip"] == "Crouch_Fwd", "앉아 이동 = Crouch_Fwd")
	var slash := Mocap.pick_clip("attack", 0.0, false, "", "slash", true, false)
	check(slash["clip"] == "Sword_Attack" and float(slash["weight"]) < 0.7, "베기는 하이브리드 블렌드")
	var jab := Mocap.pick_clip("attack", 0.0, false, "", "punch_L", false, false)
	check(jab["clip"] == "Punch_Jab", "주먹 연타 = Punch_Jab")
	var kick := Mocap.pick_clip("attack", 0.0, false, "", "sidekick", false, false)
	check(kick["clip"] == "" and float(kick["weight"]) == 0.0, "고유 발차기(sidekick)는 절차 포즈 100% 보존")
	var hit := Mocap.pick_clip("hitstun", 0.0, false, "", "", false, false)
	check(hit["clip"] == "Hit_Chest" and not bool(hit["loop"]), "피격 = Hit_Chest")
	var dead := Mocap.pick_clip("dead", 0.0, false, "", "", false, false)
	check(dead["clip"] == "Death01", "쓰러짐 = Death01")


func test_mocap_library_loads() -> void:
	check(Mocap.ensure_loaded(), "assets/animations/humanoid_cc0.glb 로드 성공")
	var names := Mocap.clip_names()
	check(names.size() >= 18, "CC0 모캡 클립 18개 이상 (%d)" % names.size())
	for req in ["Idle", "Walk", "Jog_Fwd", "Sword_Attack", "Punch_Jab", "Roll", "Death01"]:
		check(names.has(req), "필수 클립 %s 존재" % req)
