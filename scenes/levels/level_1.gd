extends LevelBase

@onready var _altar_ref: Area2D = $Narrative/Altar
@onready var _elder_ref: Area2D = $Narrative/Elder
@onready var _fox_spawn_marker: Marker2D = $Narrative/FoxSpawnMarker

var _ending_triggered: bool = false

func _on_level_ready() -> void:
	_altar_ref.offering_completed.connect(_on_altar_completed)
	_elder_ref.set_dialog([
		{"speaker": "老人", "text": "终于有人来了。这条参道，我守了三十年。"},
		{"speaker": "老人", "text": "送狐之仪须依古法：先奉杉木，再覆白毛，最后以蓬草盖顶。"},
		{"speaker": "老人", "text": "三物齐备，置于祭坛，白狐自会现身。"},
		{"speaker": "老人", "text": "记住：送狐途中，不可出声，不可回头。"},
	] as Array[Dictionary])
	show_area_name("第一章  装束之祠")
	GameManager.set_state(GameManager.State.PLAYING)
	play_bgm(preload("res://assets/audio/bgm/forest_night.wav"))
	play_ambience(preload("res://assets/audio/ambience/night_insects.wav"))

func _on_altar_completed(success: bool) -> void:
	if not success or _ending_triggered:
		return
	_ending_triggered = true
	await get_tree().create_timer(0.8).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "供物被安稳地叠在祭坛上，木、白、草的顺序没有错。"},
		{"speaker": "", "text": "祭坛微微发亮，还需要最后一道顶礼供物。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	show_choice(
		"选择顶礼供物",
		"铃绳纤维", "狐火石",
		"温和地呼唤", "强行点燃狐火",
		_on_final_choice
	)

func _on_final_choice(choice: String) -> void:
	if choice == "A":
		GameManager.set_branch(1, "A")
		_play_ending_a()
	else:
		GameManager.set_branch(1, "B")
		_play_ending_b()

func _play_ending_a() -> void:
	DialogManager.show_dialog([
		{"speaker": "", "text": "你将铃绳纤维轻放在供物之上。"},
		{"speaker": "", "text": "风从鸟居方向吹来，带着铃声的残响。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	var fox := spawn_fox(_fox_pos(), 0)
	await get_tree().create_timer(1.2).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "一只白狐从鸟居后走出，安静地看了你一眼。"},
		{"speaker": "", "text": "它转过身，向山上跑去。尾端的狐火温和而平稳。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	fox.depart(Vector2(1.0, -0.08))
	await get_tree().create_timer(1.5).timeout
	GameManager.transition_to_level(2)

func _play_ending_b() -> void:
	DialogManager.show_dialog([
		{"speaker": "", "text": "你将狐火石嵌入供物之间。"},
		{"speaker": "", "text": "石头表面的火纹猛地亮起，祭坛上的供物开始震颤。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	var fox := spawn_fox(_fox_pos(), 1)
	await get_tree().create_timer(1.2).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "白狐从火光中走出。它的狐火忽大忽小，像在喘息。"},
		{"speaker": "", "text": "山路被照得忽明忽暗，前方的影子也变长了。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	fox.depart(Vector2(1.0, -0.08))
	await get_tree().create_timer(1.5).timeout
	GameManager.transition_to_level(2)

func _fox_pos() -> Vector2:
	if _fox_spawn_marker:
		return _fox_spawn_marker.global_position
	return Vector2(8540, 420)
