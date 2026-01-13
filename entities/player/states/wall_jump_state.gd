extends PlayerState

func _enter() -> void:
	super()
	
	# 1. Hitung Arah Lontaran
	var wall_normal = player.get_wall_normal()
	
	# Force X = Normal * Kekuatan X (Menjauh dari tembok)
	# Force Y = Kekuatan Y (Ke atas)
	var jump_vector = Vector2(wall_normal.x * player.stats.wall_jump_force.x, player.stats.wall_jump_force.y)
	
	# 2. Terapkan Fisika
	player.velocity = jump_vector
	
	# 3. Visual & Juice
	# Paksa hadap ke arah lompatan
	player.visuals.scale.x = sign(wall_normal.x)
	player.animation_player.play("Jump")
	
	# Reset Double Jump (Opsional: Biasanya wall jump mengembalikan double jump)
	player.jump_count = 0 
	
	# 4. Selesai (Langsung pindah ke udara di frame berikutnya)
	# Kita beri sedikit delay agar input player tidak langsung membatalkan velocity X
	await get_tree().create_timer(0.1).timeout
	get_root().dispatch("state_ended")
