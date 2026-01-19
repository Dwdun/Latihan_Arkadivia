@tool
extends BTCondition

@export var attack_index: int = 0
@export var needs_facing: bool = true # Opsi baru: Wajib menghadap player?

func _tick(_delta: float) -> Status:
	var enemy = agent as EnemyController
	if not is_instance_valid(enemy): return FAILURE
	
	# LOCKING: Jika sedang animasi serangan, biarkan lanjut (SUCCESS)
	if enemy.is_attacking:
		return SUCCESS
	
	# 1. Cek Target
	var target = blackboard.get_var("target", null)
	if not is_instance_valid(target): return FAILURE
	
	# 2. Cek Validitas Index
	if attack_index >= enemy.stats.attacks.size(): return FAILURE
	var atk = enemy.stats.attacks[attack_index]
	
	# 3. Cek Jarak (Min & Max)
	var dist_sq = enemy.global_position.distance_squared_to(target.global_position)
	var max_range_sq = atk.max_range * atk.max_range
	var min_range_sq = atk.min_range * atk.min_range
	
	if dist_sq > max_range_sq or dist_sq < min_range_sq:
		return FAILURE
		
	# 4. Cek Cooldown
	if not enemy.can_use_attack(attack_index):
		return FAILURE
	
	# --- 5. LOGIKA BARU: CEK ARAH HADAP (NO CHEATING!) ---
	if needs_facing:
		var dir_to_target = target.global_position.x - enemy.global_position.x
		var facing_dir = enemy.visuals.scale.x
		
		# Logika: Jika arah target beda tanda (+/-) dengan arah hadap -> GAGAL
		# sign(50) = 1 (Kanan), sign(-50) = -1 (Kiri)
		# Namun kita izinkan toleransi dikit jika target tepat di tengah (0)
		if dir_to_target != 0 and facing_dir != 0:
			if sign(dir_to_target) != sign(facing_dir):
				return FAILURE # Salah hadap! Jangan nyerang.
				
	return SUCCESS
