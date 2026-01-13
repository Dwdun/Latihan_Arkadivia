extends PlayerState

func _enter() -> void:
	super() # Panggil setup dasar
	player.animation_player.play("Idle") # Pastikan nama "Idle" sesuai dengan yang Anda buat

func _update(delta: float) -> void:
	# ... logika friksi yang lama ...
	player.velocity.x = move_toward(player.velocity.x, 0, player.stats.friction * delta)
	
	# ... logika transisi yang lama ...
	if player.input_axis != 0:
		get_root().dispatch("move_started")
	if Input.is_action_just_pressed("jump"):
		get_root().dispatch("jump_started")
	if not player.is_on_floor():
		get_root().dispatch("fall_started")
