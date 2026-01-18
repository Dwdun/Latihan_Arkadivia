extends CanvasLayer

@onready var fader: ColorRect = $Fader

func _ready() -> void:
	fader.color.a = 0.0
	visible = false

func change_scene(scene_path: String, target_door_id: String = "", spawn_player: bool = true, custom_pos: Vector2 = Vector2.INF):
	visible = true
	get_tree().paused = true

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fader, "color:a", 1.0, 0.5)
	await tween.finished

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame 
	while get_tree().current_scene == null:
		await get_tree().process_frame
	
	var player_instance = null
	if spawn_player:
		player_instance = _spawn_player_in_new_level()

	if player_instance:
		if custom_pos != Vector2.INF:
			player_instance.global_position = custom_pos
			if player_instance.has_node("Camera2D"):
				player_instance.get_node("Camera2D").reset_smoothing()

		elif target_door_id != "":
			_teleport_player_to_door(player_instance, target_door_id)

	var tween_in = create_tween()
	tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(fader, "color:a", 0.0, 0.5)
	await tween_in.finished
	
	visible = false
	get_tree().paused = false

func _spawn_player_in_new_level() -> CharacterBody2D:
	var char_scene = GameManager.current_character_scene
	if not char_scene:
		push_error("GameManager: Tidak ada karakter yang dipilih!")
		return null
	
	var new_player = char_scene.instantiate()
	
	var current_scene = get_tree().current_scene
	current_scene.add_child(new_player)
	
	return new_player

func _teleport_player_to_door(player: Node2D, door_id: String):
	if not player: return
	
	var doors = get_tree().get_nodes_in_group("doors")
	for door in doors:
		if door.has_method("get_id") and door.get_id() == door_id:
			player.global_position = door.get_spawn_position()
			if player.has_node("Camera2D"):
				player.get_node("Camera2D").enabled = false
				player.get_node("Camera2D").enabled = true
			return
	
	push_warning("Pintu " + door_id + " tidak ditemukan! Player spawn di (0,0)")
