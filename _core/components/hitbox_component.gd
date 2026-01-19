class_name HitboxComponent
extends Area2D

@export var damage: int = 10 
@export var knockback_force: float = 300.0

signal hit_connected

@export_group("Juice")
@export var hit_stop_duration: float = 0.15 
@export var screen_shake_amount: float = 2.0 

var hit_list: Array[Area2D] = []

func _ready() -> void:
	# Kita tidak butuh area_entered lagi karena kita akan cek manual tiap frame
	pass

func _physics_process(delta: float) -> void:
	if not monitoring:
		return
	# Cek semua area yang sedang tumpang tindih (Overlapping) saat ini
	var overlapping_areas = get_overlapping_areas()

	for area in overlapping_areas:
		if area.has_method("take_damage"): 
			_attempt_hit(area)

func _attempt_hit(area: HurtboxComponent):
	# 1. Cek apakah korban ini sudah masuk daftar "Sudah Kena"?
	if area in hit_list:
		return # Skip, jangan dipukul lagi (Tunggu reset dari pemilik)
	
	# 2. Coba kirim damage
	var attack_success = false
	if area.has_method("take_damage"):
		attack_success = area.take_damage(damage, global_position, knockback_force)
	
	# 3. Logika PENTING:
	# Kita hanya memasukkan ke hit_list JIKA serangan SUKSES (Tembus I-Frame)
	if attack_success:
		hit_connected.emit()
		hit_list.append(area)
		_apply_hit_feel()
	
	# JIKA GAGAL (attack_success == false):
	# Area TIDAK dimasukkan ke hit_list.
	# Akibatnya: Di frame berikutnya, _physics_process akan mencoba memukul lagi!
	# Ini akan berulang terus sampai I-Frame player habis. Begitu habis -> Hajar.

func _apply_hit_feel():
	if GameManager:
		GameManager.hit_stop(0.05, hit_stop_duration)
	
	var viewport = get_viewport()
	if viewport:
		var camera = viewport.get_camera_2d()
		if camera and camera.has_method("apply_shake"):
			camera.apply_shake(screen_shake_amount)
		
	var parent = get_parent()
	if parent:
		var owner_node = parent.get_parent()
		if owner_node and owner_node.has_method("apply_recoil"):
			if parent.get("scale"): 
				var recoil_dir = Vector2(-parent.scale.x, 0)
				owner_node.apply_recoil(recoil_dir)

func reset_hitbox():
	hit_list.clear()
