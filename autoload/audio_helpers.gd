extends RefCounted

static func play_one_shot(parent: Node, stream: AudioStream, volume_db: float = -3.0) -> void:
	if not parent or not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	parent.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

static func play_music(parent: Node, stream: AudioStream, _loop: bool = false, volume_db: float = 0.0) -> AudioStreamPlayer:
	if not parent or not stream:
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	parent.add_child(player)
	player.play()
	return player
