extends Area2D

@export var tablet_text: String = ""
@export var speaker_name: String = ""

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("interactable")

func interact() -> void:
	if tablet_text.is_empty():
		return
	var lines: Array[Dictionary] = []
	var normalized := tablet_text.replace("\\n", "\n")
	for part in normalized.split("\n"):
		var clean := part.strip_edges()
		if clean != "":
			lines.append({"speaker": speaker_name, "text": clean})
	if not lines.is_empty():
		DialogManager.show_dialog(lines)

func get_interact_name() -> String:
	if speaker_name != "":
		return speaker_name
	return "札记"
