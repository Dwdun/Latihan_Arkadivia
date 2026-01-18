extends Area2D

@onready var spawn_point = $SpawnPoint
var is_active: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_active:
		activate_checkpoint()

func activate_checkpoint():
	is_active = true

	var level_path = get_tree().current_scene.scene_file_path
	GameManager.register_checkpoint(spawn_point.global_position, level_path)
	
	var tween = create_tween()
	
	print("Checkpoint Activated!")
