@tool
extends BTAction

# ZONA IDEAL BOSS (Sweet Spot)
@export var min_distance: float = 120.0  # Kalau lebih dekat dari ini, Mundur (Kiting)
@export var max_distance: float = 180.0  # Kalau lebih jauh dari ini, Kejar (Clingy)

func _tick(delta: float) -> int:
	var enemy = agent as EnemyController
	if not is_instance_valid(enemy): return FAILURE
	
	# Jangan gerak kalau sedang sibuk (Attack/Hurt/Dead)
	if enemy.is_attacking or enemy.is_hurt or enemy.is_dead:
		return RUNNING
	
	var target = blackboard.get_var("target", null)
	if not is_instance_valid(target):
		# Kalau tidak ada target, diam saja (Idle)
		enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.stats.friction * delta)
		if enemy.animation_player.has_animation("Idle"):
			enemy.animation_player.play("Idle")
		return RUNNING
		
	# 1. HITUNG JARAK & ARAH
	var dist = enemy.global_position.distance_to(target.global_position)
	var dir_to_player = 1 if target.global_position.x > enemy.global_position.x else -1
	
	# 2. LOGIKA SMART POSITIONING
	var move_dir = 0 # 0 artinya diam
	
	if dist < min_distance:
		# KONDISI A: Terlalu Dekat -> MUNDUR (Kiting)
		move_dir = -dir_to_player # Kebalikan arah player
		
	elif dist > max_distance:
		# KONDISI B: Terlalu Jauh -> MAJU (Clingy/Chase)
		move_dir = dir_to_player # Menuju arah player
		
	else:
		# KONDISI C: Zona Pas (Sweet Spot) -> DIAM & TATAP PLAYER
		move_dir = 0
	
	# 3. EKSEKUSI GERAKAN
	if move_dir != 0:
		# Set kecepatan
		enemy.velocity.x = move_dir * enemy.stats.speed
		
		# Mainkan Animasi Jalan
		if enemy.animation_player.has_animation("Walk"):
			if enemy.animation_player.current_animation != "Walk":
				enemy.animation_player.play("Walk")
	else:
		# Stop pelan-pelan (Friksi)
		enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.stats.friction * delta)
		
		# Mainkan Animasi Idle
		if enemy.animation_player.has_animation("Idle"):
			if enemy.animation_player.current_animation != "Idle":
				enemy.animation_player.play("Idle")

	# 4. VISUAL FACING (Selalu menatap Player, walau sedang mundur)
	if enemy.visuals:
		# Pastikan sprite selalu menghadap player (bukan menghadap arah jalan)
		# Agar saat mundur terlihat seperti "Backstep" kiting
		enemy.visuals.scale.x = 1 if dir_to_player > 0 else -1
		
	return RUNNING
