class_name BaseSkill
extends Resource

@export var skill_name: String = "Skill Name"
@export var cooldown: float = 1.0
@export var mana_cost: int = 3
@export var icon: Texture2D

# --- TAMBAHAN BARU UNTUK CHARGING ---
@export_group("Charge Settings")
@export var can_charge: bool = false # Apakah skill ini bisa ditahan?
@export var max_charge_time: float = 1.0 # Berapa lama sampai full charge?
@export var charge_damage_multiplier: float = 2.0 # Damage x2 kalau full charge

var _current_timer: float = 0.0
# Fungsi virtual yang akan ditimpa oleh skill spesifik
# Fungsi untuk memulai cooldown (Panggil ini SETELAH animasi selesai)

func is_ready() -> bool:
	return _current_timer <= 0.0

func start_cooldown():
	# Nanti di-override oleh skill spesifik
	_current_timer = cooldown

func execute(user: CharacterBody2D, stats: PlayerStats) -> void:
	push_warning("Skill logic not implemented!")

func tick_cooldown(delta: float):
	if _current_timer > 0:
		_current_timer -= delta
