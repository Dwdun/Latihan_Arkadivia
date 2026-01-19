extends Node2D

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	health_component.died.connect(_on_died)
	health_component.damaged.connect(_on_damaged)

# Tambahkan parameter ke-3: knockback_force
func _on_damaged(amount: int, source_pos: Vector2, knockback_force: float):
	# Efek visual sederhana
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

func _on_died():
	print("Musuh Tewas!")
	queue_free() # Hapus musuh dari dunia
