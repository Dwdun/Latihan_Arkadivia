@tool
extends BTCondition

@export var attack_index: int = 0

# PERBAIKAN: Return type diubah dari 'bool' menjadi 'Status' (Enum milik LimboAI)
func _tick(_delta: float) -> Status:
	var enemy = agent as EnemyController
	
	# Jika enemy tidak valid, anggap kondisi Gagal (False)
	if not is_instance_valid(enemy): 
		return FAILURE
	
	# 1. Cek Cooldown (Menggunakan fungsi di EnemyController)
	if not enemy.can_use_attack(attack_index):
		return FAILURE # == False (Belum bisa serang)
		
	# 2. Ambil Data Serangan
	if attack_index >= enemy.stats.attacks.size(): 
		return FAILURE
		
	var atk = enemy.stats.attacks[attack_index]
	
	# 3. Cek Jarak (Min & Max Range)
	var target = blackboard.get_var("target", null)
	
	# Wajib ada target untuk menyerang
	if not is_instance_valid(target): 
		return FAILURE
	
	var dist = enemy.global_position.distance_to(target.global_position)
	
	# Logika Jarak: Jika terlalu dekat ATAU terlalu jauh -> GAGAL
	if dist < atk.min_range or dist > atk.max_range:
		return FAILURE 
		
	# Jika lolos semua cek di atas -> SUKSES (Boleh Serang)
	return SUCCESS # == True
