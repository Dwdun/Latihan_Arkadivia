extends PlayerState

var timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var ghost_timer: float = 0.0
var ghost_interval: float = 0.05

func _enter() -> void:
	super()
	
	# --- 1. EFEK "CRISPY" (URUTAN PENTING) ---
	
	# A. FREEZE FRAME (Hentikan waktu sejenak)
	# Celeste menggunakan freeze sekitar 0.15 detik sebelum dash meluncur.
	# Ini memberi kesan "ancang-ancang" yang berat.
	GameManager.hit_stop(0.0, .1) 
	
	# B. SCREEN SHAKE (Guncang Kamera)
	# [cite_start]Kita panggil fungsi apply_shake dari script camera_shaker.gd [cite: 14]
	if player.camera_shaker:
		player.camera_shaker.apply_shake(1.5) # Kekuatan guncangan (bisa diatur)
	
	# C. SQUASH & STRETCH (Penyetkan Karakter)
	# Saat mulai dash, kita buat karakter gepeng sedikit ke arah gerakan
	player.apply_squash_stretch(1.3, 0.6) 
	
	# ----------------------------------------

	# 2. SETUP VARIABEL (Logic Dash Diagonal yang sudah kita buat)
	timer = player.temp_dash_duration
	player.velocity.y = 0
	ghost_timer = 0.0
	
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_vector != Vector2.ZERO:
		dash_direction = input_vector.normalized()
		if input_vector.x != 0:
			player.visuals.scale.x = sign(input_vector.x)
	else:
		dash_direction = Vector2(player.visuals.scale.x, 0)
	
	# 3. ANIMASI
	if player.animation_player.has_animation("Dash"):
		# ... (Kode animasi speed scale yang sebelumnya) ...
		var anim_length = player.animation_player.get_animation("Dash").length
		var speed_scale = 1.0 if timer == 0 else anim_length / timer
		player.animation_player.play("Dash", -1, speed_scale)

func _update(delta: float) -> void:
	# Terapkan Velocity ke segala arah (termasuk vertikal/diagonal)
	player.velocity = dash_direction * player.temp_dash_speed
	
	timer -= delta
	
	# Ghost Trail Logic
	ghost_timer -= delta
	if ghost_timer <= 0:
		player.add_ghost_trail()
		ghost_timer = ghost_interval
	
	# Logika Keluar
	if timer <= 0:
		# PENTING: Saat dash diagonal selesai, kita harus "mematikan" momentum
		# agar player tidak melayang terus ke atas jika dash diagonal atas.
		# Kita kurangi kecepatannya, tapi sisakan sedikit momentum (misal 50%) agar enak.
		player.velocity = player.velocity * 0.5 
		
		if player.is_on_floor():
			if player.input_axis != 0:
				get_root().dispatch("move_started")
			else:
				get_root().dispatch("state_ended")
		else:
			get_root().dispatch("fall_started")
