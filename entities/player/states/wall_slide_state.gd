extends PlayerState

func _enter() -> void:
	super()
	# Mainkan animasi nempel tembok (jika ada)
	if player.animation_player.has_animation("WallSlide"):
		player.animation_player.play("WallSlide")

func _update(delta: float) -> void:
	# 1. Logika Gravitasi (Tapi dibatasi/Clamp)
	player.velocity.y += player.gravity * delta
	# Jangan biarkan jatuh lebih cepat dari wall_slide_speed
	player.velocity.y = min(player.velocity.y, player.stats.wall_slide_speed)
	
	# 2. Update Arah Visual
	# Hadapkan sprite ke arah tembok
	var wall_normal = player.get_wall_normal()
	# Normal (-1, 0) artinya tembok di KANAN. Normal (1, 0) artinya tembok di KIRI.
	# Kita harus membalik logika scale
	if wall_normal.x != 0:
		player.visuals.scale.x = -sign(wall_normal.x)

	# 3. Transisi Keluar
	
	# A. Jika mendarat di tanah -> Idle/Move
	if player.is_on_floor():
		get_root().dispatch("state_ended")
		return

	# B. Jika lepas dari tembok (Tembok habis atau Pemain menjauh)
	if not player.is_on_wall():
		get_root().dispatch("fall_started")
		return
		
	# C. Jika Pemain sengaja menekan arah MENJAUH dari tembok -> Lepas
	# (Opsional, tapi bikin kontrol lebih enak)
	var input = Input.get_axis("move_left", "move_right")
	if input != 0 and sign(input) == sign(wall_normal.x):
		get_root().dispatch("fall_started")
		return

	# D. Wall Jump (Input Lompat)
	if Input.is_action_just_pressed("jump"):
		get_root().dispatch("wall_jump")
