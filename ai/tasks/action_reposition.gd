@tool
extends BTAction

@export var min_distance: float = 150.0
@export var max_distance: float = 350.0
@export var duration: float = 1.5 # Lama boss berjalan-jalan

var _target_pos: Vector2
var _time_left: float = 0.0

func _enter() -> void:
	var target = blackboard.get_var("target", null)
	var enemy = agent as EnemyController
	
	if is_instance_valid(target) and is_instance_valid(enemy):
		# Pilih titik acak di sekitar player
		var random_angle = randf_range(0, TAU)
		var random_dist = randf_range(min_distance, max_distance)
		var offset = Vector2.from_angle(random_angle) * random_dist
		
		_target_pos = target.global_position + offset
		_time_left = duration
	else:
		_time_left = 0.0

func _tick(delta: float) -> Status:
	var enemy = agent as EnemyController
	if not is_instance_valid(enemy): return FAILURE
	
	_time_left -= delta
	if _time_left <= 0:
		# Waktu habis, berhenti dan lapor SUKSES
		enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.stats.friction * delta)
		if enemy.animation_player.has_animation("Idle"):
			enemy.animation_player.play("Idle")
		return SUCCESS
	
	# Logika Gerak Menuju Titik Acak
	var dir = (_target_pos - enemy.global_position).normalized()
	enemy.velocity.x = dir.x * (enemy.stats.speed * 0.8) # Jalan santai (80% speed)
	
	# Visual Flip
	if enemy.visuals and dir.x != 0:
		# Pastikan sprite asli boss menghadap Kanan. Jika asli kiri, balik logikanya.
		enemy.visuals.scale.x = 1 if dir.x > 0 else -1
	
	if enemy.animation_player.has_animation("Walk"):
		if enemy.animation_player.current_animation != "Walk":
			enemy.animation_player.play("Walk")
			
	return RUNNING
