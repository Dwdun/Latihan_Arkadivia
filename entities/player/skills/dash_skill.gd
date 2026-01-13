class_name SkillDash
extends BaseSkill

@export_group("Dash Settings")
@export var dash_speed: float = 800.0
@export var duration: float = 0.2
@export var cooldown_time: float = 0.6

# Variable internal untuk menghitung cooldown
var _current_cooldown: float = 0.0

func execute(user: CharacterBody2D, stats: PlayerStats) -> void:
	# Cek apakah sedang cooldown?
	if _current_cooldown > 0:
		return # Masih cooldown, batalkan skill

	# --- LOGIKA "PENYUNTIKAN" DATA ---
	# Kita kirim data dari Resource ini ke Player Controller
	# Agar nanti State Dash tahu seberapa cepat dia harus bergerak
	if user.has_method("apply_dash_data"):
		user.apply_dash_data(dash_speed, duration)
		
		# Picu transisi State Machine!
		# Asumsi: user punya properti 'limbo_hsm'
		user.limbo_hsm.dispatch("dash_started")
		
		# Mulai cooldown
		_current_cooldown = cooldown_time

# Fungsi khusus agar cooldown berjalan (dipanggil dari player nanti)
func tick_cooldown(delta: float):
	if _current_cooldown > 0:
		_current_cooldown -= delta
