extends Node

var current_level_path: String = ""

var enchanter = preload("res://entities/player/enchanter.tscn")
var executioner = preload("res://entities/player/executioner.tscn")
var item_test = load("res://items/resources/potion_item.tres")
var item_test2 = load("res://items/resources/key.tres")

var last_checkpoint_pos: Vector2 = Vector2.INF
var last_checkpoint_level: String = ""

var collected_items_state: Dictionary = {}

var current_character_scene: PackedScene

var is_cutscene: bool = false

var camera_left: int
var camera_right: int
var camera_top: int
var camera_bottom: int
var camera_zoom: int

func _ready() -> void:
	if item_test:
		InventoryManager.add_item(item_test, 5)
		InventoryManager.add_item(item_test, 10)
		InventoryManager.add_item(item_test2, 5)
		InventoryManager.add_item(item_test2, 11)

func hit_stop(time_scale: float, duration: float):
	Engine.time_scale = time_scale

	await get_tree().create_timer(duration, true, false, true).timeout
	
	Engine.time_scale = 1.0 

func select_character(type: String):
	match type:
		"enchanter": current_character_scene = enchanter
		"executioner": current_character_scene = executioner
		_: print("Karakter tidak dikenal!")

func respawn_player():
	print("GameManager: Memulai proses respawn...")

	await get_tree().create_timer(0.5).timeout

	if get_tree().current_scene:
		current_level_path = get_tree().current_scene.scene_file_path

	if current_level_path == "":
		push_error("GameManager: Gagal reload!")
		return

	if last_checkpoint_pos != Vector2.INF and last_checkpoint_level == current_level_path:
		SceneManager.change_scene(current_level_path, "", true, last_checkpoint_pos)
	else:
		SceneManager.change_scene(current_level_path, "start")


func is_item_collected(id: String) -> bool:
	return collected_items_state.has(id)

func register_collected_item(id: String):
	collected_items_state[id] = true

func set_cutscene_mode(active: bool):
	is_cutscene = active
	
	if active:
		if GlobalUI: GlobalUI.hide_ui()

		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_physics_process(false)
			player.velocity = Vector2.ZERO
			if player.has_node("AnimationPlayer"):
				player.get_node("AnimationPlayer").play("Idle")
	else:
		if GlobalUI: GlobalUI.show_ui()
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_physics_process(true)

func register_checkpoint(pos: Vector2, level_path: String):
	last_checkpoint_pos = pos
	last_checkpoint_level = level_path
	print("Checkpoint Saved at: ", pos)
	
