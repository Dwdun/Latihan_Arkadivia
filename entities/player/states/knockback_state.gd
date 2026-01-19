extends PlayerState

var timer: float = 0.0
var duration: float = 0.15 # Durasi pentalan (sangat singkat)

func _enter() -> void:
	super()
	# 1. Ambil Knockback dari "Titipan" Controller
	# Sekarang 'player' sudah aman digunakan
	if player:
		player.velocity = player.temp_knockback
		
		# Mainkan animasi "Jump" atau "Hurt" (Pilih salah satu)
		# Animasi Jump biasanya lebih mulus untuk transisi udara
		if player.animation_player.has_animation("Jump"):
			player.animation_player.play("Jump")
	
	timer = duration
func _update(delta: float) -> void:
	# 1. Biarkan Fisika Bekerja (Inersia)
	# Kita hanya menerapkan gravitasi & sedikit gesekan udara
	player.velocity.y += player.gravity * delta
	player.velocity.x = move_toward(player.velocity.x, 0, 500 * delta) # Sedikit friction udara
	
	# 2. Hitung Mundur
	timer -= delta
	if timer <= 0:
		# Kembalikan ke Fall (Udara) atau Idle (Tanah)
		if player.is_on_floor():
			get_root().dispatch("state_ended")
		else:
			get_root().dispatch("fall_started")
