extends Area2D

const AudioHelpers = preload("res://autoload/audio_helpers.gd")
const SFX_INTERACT := preload("res://assets/audio/sfx/interact.wav")

@export var tablet_text: String = ""
@export var speaker_name: String = ""

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")

func interact() -> void:
	if tablet_text.is_empty():
		return
	AudioHelpers.play_one_shot(get_tree().root, SFX_INTERACT)
	var lines: Array[Dictionary] = []
	var normalized := tr(tablet_text).replace("\\n", "\n")
	for part in normalized.split("\n"):
		var clean := part.strip_edges()
		if clean != "":
			lines.append({"speaker": speaker_name, "text": clean})
	if not lines.is_empty():
		DialogManager.show_dialog(lines, {
			"voice_key": tablet_text,
			"voice_persistent": true,
			"voice_volume_db": 0.0,
		})

func get_interact_name() -> String:
	if speaker_name != "":
		return tr(speaker_name)
	return tr("UI_INTERACT_TABLET")
