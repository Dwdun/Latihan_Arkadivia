extends PlayerState

func _enter() -> void:
	super()
	player.animation_player.play("Run")

func _update(delta: float) -> void:
	# LOGIKA BALIK BADAN BARU
	if player.input_axis != 0:
		# Jika input Kanan (1), scale.x = 1.
		# Jika input Kiri (-1), scale.x = -1.
		# Ini akan membalik Sprite DAN Hitbox sekaligus!
		player.visuals.scale.x = sign(player.input_axis)

	# ... logika gerak yang lama ...
	if player.input_axis != 0:
		player.velocity.x = move_toward(
			player.velocity.x, 
			player.input_axis * player.stats.move_speed, 
			player.stats.acceleration * delta
		)
	else:
		get_root().dispatch("state_ended")

	if not player.is_on_floor():
		# Sebelum transisi ke 'fall', aktifkan Coyote Time!
		player.coyote_timer = player.stats.coyote_time
		get_root().dispatch("fall_started")
		return # Stop eksekusi biar langsung pindah state

	# Cek Lompat Biasa (Input Langsung)
	if Input.is_action_just_pressed("jump"):
		get_root().dispatch("jump_started")
