class_name SkillShockwave
extends BaseSkill

@export_group("Shockwave Stats")
@export var damage: int = 50
@export var animation_name: String = "Shockwave"

var _current_cooldown: float = 0.0

# 1. override fungsi start_cooldown
func start_cooldown():
	_current_cooldown = cooldown

func execute(user: CharacterBody2D, stats: PlayerStats) -> void:
	if _current_cooldown > 0:
		return

	if user.has_method("prepare_skill_attack"):
		# Kirim data skill, TERMASUK referensi 'self' (skill ini sendiri)
		# Kita perlu update prepare_skill_attack sedikit nanti, 
		# atau simpan skill ini di variable temp player
		user.prepare_skill_attack(damage, animation_name, can_charge, max_charge_time, charge_damage_multiplier)
		
		# KITA SIMPAN SKILL INI DI CONTROLLER AGAR BISA DIPANGGIL NANTI
		user.temp_active_skill = self 
		
		user.limbo_hsm.dispatch("skill_cast_started")
		
		# --- HAPUS BARIS INI ---
		# _current_cooldown = cooldown 
		# Biarkan cooldown dipicu manual oleh CastState

func tick_cooldown(delta: float):
	if _current_cooldown > 0:
		_current_cooldown -= delta
