extends Area2D

@export var amount: int = 1
@export var unique_id: String = ""
@onready var sprite = $Sprite2D

func _ready():
	if unique_id == "":
		unique_id = str(get_tree().current_scene.scene_file_path) + "/" + str(get_path())

	if GameManager.is_item_collected(unique_id):
		queue_free()

func _process(delta: float) -> void:
	$AnimationPlayer.play("Idle")

func _on_body_entered(body):
	print("Sesuatu masuk: ", body.name)
	if body.is_in_group("player"):
		_collect_coin()

func _collect_coin():
	InventoryManager.add_gold(amount)

	GameManager.register_collected_item(unique_id)

	set_deferred("monitoring", false)
	
	var tween = create_tween()

	tween.set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	
	tween.chain().tween_callback(queue_free)
