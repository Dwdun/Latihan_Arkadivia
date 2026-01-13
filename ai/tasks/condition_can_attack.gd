@tool
extends BTCondition

@export var attack_index: int = 0

func _tick(_delta: float) -> int:
	var enemy = agent as EnemyController
	if not is_instance_valid(enemy): return FAILURE
	
	# --- PERBAIKAN PENTING (LOCKING) ---
	# Jika musuh SEDANG dalam animasi serangan, jangan diganggu!
	# Biarkan logika Attack lanjut terus agar animasi tidak kepotong Dynamic Selector.
	if enemy.is_attacking:
		return SUCCESS
	# -----------------------------------
	
	var target = blackboard.get_var("target", null)
	if not is_instance_valid(target): return FAILURE
	
	if attack_index >= enemy.stats.attacks.size(): return FAILURE
	
	var atk = enemy.stats.attacks[attack_index]
	
	# Cek Jarak
	var dist_sq = enemy.global_position.distance_squared_to(target.global_position)
	var max_range_sq = atk.max_range * atk.max_range
	var min_range_sq = atk.min_range * atk.min_range
	
	if dist_sq > max_range_sq or dist_sq < min_range_sq:
		return FAILURE
		
	# Cek Cooldown
	if not enemy.can_use_attack(attack_index):
		return FAILURE
			
	return SUCCESS
