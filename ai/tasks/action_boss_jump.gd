@tool
extends BTAction

@export var jump_height: float = 150.0   # Tinggi lompatan
@export var duration: float = 1.0        # Estimasi durasi di udara
@export var land_offset: float = 100.0   # Jarak mendarat dari player (X offset)
@export var chance_behind: float = 0.5   # 50% kemungkinan lompat ke belakang player

var _is_jumping: bool = false

func _enter() -> void:
	_is_jumping = false
	var enemy = agent as BossSlimeMech # Pastikan casting ke Boss Script
	var target = blackboard.get_var("target", null)
	
	if is_instance_valid(enemy) and is_instance_valid(target):
		_perform_jump(enemy, target)
	else:
		_is_jumping = false # Gagal start

func _tick(_delta: float) -> Status:
	var enemy = agent as BossSlimeMech
	
	# Jika setup gagal di awal
	if not _is_jumping: return FAILURE
	
	# Tunggu sampai boss menyentuh tanah lagi (dan velocity Y turun/bukan awal lompat)
	if enemy.is_on_floor() and enemy.velocity.y >= 0:
		enemy.is_jumping_logic = false # Matikan flag fisika
		# Mainkan animasi landing/idle
		enemy.face_target()
		if enemy.animation_player.has_animation("Idle"):
			enemy.animation_player.play("Idle")
		return SUCCESS
		
	return RUNNING

func _perform_jump(enemy: BossSlimeMech, target: Node2D):
	# 1. Tentukan Posisi Target (Depan atau Belakang?)
	var player_pos = target.global_position
	var direction_to_player = sign(player_pos.x - enemy.global_position.x)
	if direction_to_player == 0: direction_to_player = 1
	
	# Roll dadu: Lompat ke Belakang atau Depan?
	var final_offset = -land_offset # Default: Depan player (antara boss dan player)
	if randf() < chance_behind:
		final_offset = land_offset # Belakang player (melewati player)
	
	# Target X adalah posisi player +/- offset
	# Kita kalikan direction agar "Depan" dan "Belakang" relatif terhadap posisi boss
	var target_x = player_pos.x + (direction_to_player * final_offset)
	
	# 2. Hitung Fisika Parabola
	# Rumus Fisika: 
	# Vy = sqrt(2 * gravity * height)
	# t_up = Vy / gravity
	# total_time = t_up * 2
	# Vx = distance / total_time
	
	var gravity = enemy.gravity * enemy.stats.gravity_scale
	var jump_velocity_y = -sqrt(2 * gravity * jump_height)
	var time_to_peak = abs(jump_velocity_y / gravity)
	var total_air_time = time_to_peak * 2
	
	var distance_x = target_x - enemy.global_position.x
	var jump_velocity_x = distance_x / total_air_time
	
	# 3. Eksekusi
	enemy.velocity = Vector2(jump_velocity_x, jump_velocity_y)
	enemy.is_jumping_logic = true # Beritahu script boss agar tidak ngerem di udara
	_is_jumping = true
	if enemy.has_method("_apply_squash_stretch"):
		enemy._apply_squash_stretch(0.7, 1.3)
	
	# Visual & Animasi
	if enemy.visuals:
		enemy.visuals.scale.x = 1 if jump_velocity_x > 0 else -1
		
	if enemy.animation_player.has_animation("Jump"):
		enemy.animation_player.play("Jump")
	else:
		# Fallback kalau belum punya animasi Jump, pakai Walk/Charge
		enemy.animation_player.play("Walk")
