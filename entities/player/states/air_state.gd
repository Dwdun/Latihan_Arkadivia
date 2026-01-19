extends PlayerState

func _enter() -> void:
	super()
	
	# LOGIKA 1: APAKAH KITA HARUS MELOMPAT?
	# Kita melompat jika:
	# A. Tombol ditekan barusan (Buffer) ATAU ditekan sekarang.
	# B. DAN (Kita di tanah ATAU Masih punya Coyote Time ATAU Masih punya stok Double Jump).
	
	var trying_to_jump = Input.is_action_just_pressed("jump") or player.jump_buffer_timer > 0
	
	if trying_to_jump:
		_try_jump()
	
	# Update animasi awal (Jump vs Fall)
	if player.velocity.y < 0:
		player.animation_player.play("Jump")
	else:
		player.animation_player.play("Fall")

func _update(delta: float) -> void:
	# --- LOGIKA BARU: ANIMASI DINAMIS ---
	# Jika bergerak ke bawah (jatuh) DAN belum memutar animasi Fall
	if player.velocity.y > 0 and player.animation_player.current_animation != "Fall":
		player.animation_player.play("Fall")
	# ------------------------------------

	# LOGIKA 2: DOUBLE JUMP (Tetap sama)
	if Input.is_action_just_pressed("jump"):
		player.jump_buffer_timer = player.stats.jump_buffer
		_try_jump()

	# LOGIKA AIR CONTROL (Tetap sama)
	if player.input_axis != 0:
		player.visuals.scale.x = sign(player.input_axis)
		player.velocity.x = move_toward(player.velocity.x, player.input_axis * player.stats.move_speed, player.stats.acceleration * delta) # Perbaikan: Pakai 'speed' bukan 'move_speed' sesuai Stats umum
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.stats.friction * delta)

	# LOGIKA VARIABLE JUMP HEIGHT (Tetap sama)
	if Input.is_action_just_released("jump") and player.velocity.y < 0:
		player.velocity.y *= 0.5

	# LOGIKA 3: MENDARAT (LANDING)
	if player.is_on_floor():
		# Efek Visual: Squash saat mendarat (Panggil fungsi baru di controller)
		player.apply_squash_stretch(1.2, 0.8) # <-- TAMBAHAN JUICE
		
		if player.jump_buffer_timer > 0: # [cite: 23]
			_try_jump() 
		else:
			if player.input_axis == 0:
				get_root().dispatch("state_ended")
			else:
				get_root().dispatch("move_started")
	
	# TRIGGER WALL SLIDE
	# Syarat: Di udara, Nempel Tembok, Jatuh (Velocity Y > 0), Input menekan ke arah tembok
	if player.is_on_wall() and player.velocity.y > 0:
		var input = Input.get_axis("move_left", "move_right")
		var wall_normal = player.get_wall_normal()
		
		# Cek apakah input BERLAWANAN dengan normal tembok (artinya menekan ke tembok)
		if input != 0 and sign(input) != sign(wall_normal.x):
			get_root().dispatch("wall_slide_started")

# Fungsi Internal Logic
func _try_jump():
	# Syarat: Hanya boleh lompat jika di tanah atau Coyote Time masih aktif
	var can_jump = player.is_on_floor() or player.coyote_timer > 0
	
	if can_jump:
		player.perform_jump()
		player.animation_player.play("Jump")
	
	# Logika Double Jump sudah DIHAPUS total.
