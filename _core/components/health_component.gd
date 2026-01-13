class_name HealthComponent
extends Node

# Sinyal untuk memberitahu sistem lain
signal died # Pemilik mati
signal health_changed(current_value: int, max_value: int) # Untuk UI Bar darah
signal damaged(amount: int, knockback_source: Vector2, force: float)
@export var max_health: int = 100
# Iframes
@export var has_iframes: bool = false
@export var iframe_duration: float = 0.5

var current_health: int
var _is_invulnerable: bool = false

func _ready() -> void:
	# Set darah penuh di awal
	current_health = max_health
	health_changed.emit(current_health, max_health)

func damage(amount: int, source_pos: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> bool:
	if _is_invulnerable:

		print(get_parent().name + " KEBAL! Damage diabaikan.")
		return false
	
	current_health -= amount
	current_health = clampi(current_health, 0, max_health)

	health_changed.emit(current_health, max_health)

	damaged.emit(amount, source_pos, knockback_force)
	
	if current_health <= 0:
		died.emit()
	else:
		if has_iframes:
			start_iframes()
			
	return true

func start_iframes():
	_is_invulnerable = true
	await get_tree().create_timer(iframe_duration).timeout
	_is_invulnerable = false

func heal(amount: int):
	current_health += amount
	current_health = clampi(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)
