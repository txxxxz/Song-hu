extends LevelBase

@onready var _archive_triggers: Array[Area2D] = [
	$Narrative/ArchiveTrigger1,
	$Narrative/ArchiveTrigger2,
	$Narrative/ArchiveTrigger3,
	$Narrative/ArchiveTrigger4,
	$Narrative/ArchiveTrigger5,
]
@onready var _plaque_marker: Marker2D = $Narrative/PlaqueMarker
@onready var _fox_spawn_marker: Marker2D = $Narrative/FoxSpawnMarker

const ARCHIVE_DIALOGS := [
	[
		{"speaker": "", "text": "旧木牌被雨水泡得发白，还能辨认出一句：山中有狐，不可直呼其名。"},
		{"speaker": "", "text": "旁边另有一行更淡的批注：被送者亦不可回首。"},
	],
	[
		{"speaker": "", "text": "回廊前的记事木牌写着：送狐之礼，始于饥年。"},
		{"speaker": "", "text": "它不像祈福的文书，更像在记录一场被合理化的处置。"},
	],
	[
		{"speaker": "", "text": "角落压着一张残纸：今夜送行者，纱夜，年九岁。"},
		{"speaker": "", "text": "下面紧跟两条规矩：不得呼名。不得回望。"},
	],
	[
		{"speaker": "", "text": "内殿入口的木札列着装束次序：杉木为底，白衣覆身，蓬草盖顶。"},
		{"speaker": "", "text": "你一路学来的供物顺序，和这张札记一字不差。"},
	],
	[
		{"speaker": "", "text": "最深处的记录几乎被刮净，只剩一句：狐若回首，是因仍记得家人。"},
		{"speaker": "", "text": "另一行像是后来补上的：送的从来不是狐。"},
	],
]

var _archives_found: int = 0
var _total_archives: int = 5
var _truth_revealed: bool = false
var _final_choice_shown: bool = false
var _fox_ref: Node2D = null

func _on_level_ready() -> void:
	for index in _archive_triggers.size():
		var trigger := _archive_triggers[index]
		if trigger:
			trigger.body_entered.connect(_on_archive_body_entered.bind(index, trigger))
	show_area_name("终章  本社・不返之灯")
	GameManager.set_state(GameManager.State.PLAYING)
	play_bgm(preload("res://assets/audio/bgm/shrine_theme.wav"))
	play_ambience(preload("res://assets/audio/ambience/shrine_roomtone.wav"))
	await get_tree().create_timer(0.8).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "主社到了。这里已经很久没有人来过。"},
		{"speaker": "", "text": "灯笼、回廊、纸门和神木都还在，却像被某种力量维持着表面的完整。"},
		{"speaker": "", "text": "你需要在社内找到更多线索。"},
	] as Array[Dictionary])

func _process(delta: float) -> void:
	super._process(delta)
	if _final_choice_shown or not player or not _plaque_marker:
		return
	var near_plaque := player.global_position.distance_to(_plaque_marker.global_position) < 260.0
	if player.has_method("set_external_interact_prompt"):
		player.set_external_interact_prompt("E  查看匾额", near_plaque and _truth_revealed)
	if near_plaque and _truth_revealed and Input.is_action_just_pressed("interact") and not DialogManager.is_active():
		_on_plaque_interact()

func _on_archive_body_entered(body: Node2D, archive_index: int, trigger: Area2D) -> void:
	if body != player:
		return
	if not is_instance_valid(trigger) or not trigger.monitoring:
		return
	trigger.set_deferred("monitoring", false)
	_on_archive_found(archive_index, trigger)

func _on_archive_found(archive_index: int, trigger: Area2D) -> void:
	_archives_found += 1
	trigger.call_deferred("queue_free")
	if archive_index >= 0 and archive_index < ARCHIVE_DIALOGS.size():
		DialogManager.show_dialog(_get_archive_dialog(archive_index))
		await DialogManager.dialog_finished
	if _archives_found >= _total_archives and not _truth_revealed:
		_truth_revealed = true
		_trigger_revelation()

func _get_archive_dialog(archive_index: int) -> Array[Dictionary]:
	var archive_dialog: Array[Dictionary] = []
	for line in ARCHIVE_DIALOGS[archive_index]:
		archive_dialog.append(line)
	return archive_dialog

func _trigger_revelation() -> void:
	await get_tree().create_timer(0.8).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "所有碎片拼在一起了。纱夜，那是你姐姐的名字。"},
		{"speaker": "", "text": "小时候，村里人都说她是被白狐带走了。"},
		{"speaker": "", "text": "但真相不是这样。她不是被带走的，她就是那只白狐。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	await get_tree().create_timer(0.4).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "杉木做底，像担架，也像棺床。白衣披身，被后人误写成白毛。"},
		{"speaker": "", "text": "蓬草覆顶，遮味、避秽、驱虫。所谓仪式，是把一个孩子打扮成狐，再把她送走。"},
		{"speaker": "", "text": "本殿的匾额也许还藏着最后的字。"},
	] as Array[Dictionary])

func _on_plaque_interact() -> void:
	if _final_choice_shown:
		return
	_final_choice_shown = true
	DialogManager.show_dialog([
		{"speaker": "", "text": "匾额上写着「迎狐」。"},
		{"speaker": "", "text": "当狐火照上去，表层文字之下露出被刮掉的旧字痕：送狐。"},
		{"speaker": "", "text": "这不是迎接，而是送行。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	await get_tree().create_timer(0.6).timeout
	_fox_ref = spawn_fox(_fox_spawn_marker.global_position if _fox_spawn_marker else Vector2(10100, 420), 0)
	await get_tree().create_timer(1.0).timeout
	DialogManager.show_dialog([
		{"speaker": "", "text": "白狐出现在本殿石阶上。它回过头来。"},
		{"speaker": "", "text": "狐火闪了一下，它在纸门上的影子不再是狐，而是穿白衣的小女孩。"},
		{"speaker": "", "text": "她就是你失踪多年的姐姐。"},
	] as Array[Dictionary])
	await DialogManager.dialog_finished
	await get_tree().create_timer(0.5).timeout
	show_choice(
		"你要叫出她的名字吗？",
		"沉默\n完成仪式", "纱夜\n呼唤她的名字",
		"让秩序继续", "让真相回来",
		_on_final_choice
	)

func _on_final_choice(choice: String) -> void:
	if choice == "A":
		GameManager.transition_to_ending("A")
	else:
		GameManager.transition_to_ending("B")
