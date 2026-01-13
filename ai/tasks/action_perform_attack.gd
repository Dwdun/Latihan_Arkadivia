@tool
extends BTAction

@export var attack_index: int = 0

# Variabel untuk memastikan kita hanya memanggil perform_attack sekali per aktivasi
var _has_started: bool = false

# Dipanggil saat Task pertama kali aktif (Masuk kotak ini)
func _enter() -> void:
	_has_started = false

func _tick(_delta: float) -> int:
	var enemy = agent as EnemyController
	if not is_instance_valid(enemy): return FAILURE
	
	# Jika musuh mati atau sakit, batalkan serangan
	if enemy.is_hurt or enemy.is_dead:
		return FAILURE

	# 1. TRIGGER SERANGAN (Hanya sekali di awal)
	if not _has_started:
		var target = blackboard.get_var("target", null)
		var target_pos = target.global_position if target else Vector2.ZERO
		
		# Perintah controller untuk serang
		enemy.perform_attack(attack_index, target_pos)
		_has_started = true
		return RUNNING # Beritahu BT: "Tunggu, aku lagi kerja"

	# 2. TUNGGU ANIMASI SELESAI
	# Kita baca flag 'is_attacking' dari EnemyController
	if enemy.is_attacking:
		return RUNNING # Masih animasi, jangan pindah state!
	else:
		return SUCCESS # Animasi kelar, tugas selesai.
