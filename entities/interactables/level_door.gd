class_name LevelDoor
extends Area2D
@export_group("Door Identity")
@export var my_id: String = "door_a" 

@export_group("Destination")
@export_file("*.tscn") var target_level_path: String
@export var target_door_id: String = "start"

const NEXT_STAGE_SCENE = preload("res://_core/next_stage.tscn") 

var player_in_range: bool = false
@onready var label: Label = $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if label: label.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		_enter_door()

func _enter_door():
	if target_level_path == "":
		push_error("Door: Level tujuan belum diisi!")
		return
	
	print("Level Selesai! Membuka menu Next Stage...")
	
	var victory_menu = NEXT_STAGE_SCENE.instantiate()
	
	if GlobalUI:
		GlobalUI.add_child(victory_menu)
	else:
		get_tree().current_scene.add_child(victory_menu)

	victory_menu.setup_victory(target_level_path, target_door_id)

func get_id() -> String:
	return my_id

func get_spawn_position() -> Vector2:
	return $SpawnPoint.global_position

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		if label: label.visible = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		if label: label.visible = false
