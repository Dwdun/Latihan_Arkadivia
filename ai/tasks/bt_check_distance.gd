@tool
extends BTCondition
## Node Custom untuk mengecek jarak antara Agent (Boss) dan Target (Player)

enum Operator { LESS_THAN, GREATER_THAN }

@export var target_var: String = "target" # Nama variabel di blackboard
@export var operator: Operator = Operator.LESS_THAN # Pilih: Kurang Dari atau Lebih Dari
@export var distance: float = 100.0 # Jarak pemicu

func _tick(_delta: float) -> Status:
	# 1. Ambil target dari blackboard
	var target = blackboard.get_var(target_var, null)
	
	# 2. Validasi: Kalau target tidak ada/mati, anggap GAGAL
	if not is_instance_valid(target):
		return FAILURE
	
	# 3. Hitung Jarak
	var d = agent.global_position.distance_to(target.global_position)
	var is_match = false
	
	# 4. Bandingkan sesuai Operator yang dipilih
	if operator == Operator.LESS_THAN:
		is_match = d < distance # Contoh: Jarak < 150 (Dekat)
	else:
		is_match = d > distance # Contoh: Jarak > 300 (Jauh)
	
	# 5. Return Success jika kondisi terpenuhi
	if is_match:
		return SUCCESS
	else:
		return FAILURE
