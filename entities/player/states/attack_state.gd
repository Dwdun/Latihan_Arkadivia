extends PlayerState

func _enter() -> void:
	super()
	
	# 1. Reset & Setup Hitbox
	var hitbox = player.get_node("Visuals/Hitbox") as HitboxComponent # Perhatikan path "Visuals" (Lihat Solusi 2 di bawah)
	# Jika belum pakai Visuals (Solusi 2), pakai player.get_node("Hitbox") dulu
	if hitbox:
		hitbox.damage = player.stats.base_damage
		hitbox.reset_hitbox()
	
	# 2. Sambungkan sinyal selesai
	# Kita hubungkan sinyal: "Kalau animasi kelar, panggil fungsi _on_animation_finished"
	if not player.animation_player.animation_finished.is_connected(_on_animation_finished):
		player.animation_player.animation_finished.connect(_on_animation_finished)
	
	# 3. Mainkan Animasi
	player.animation_player.play("Attack1")
	
	# 4. Stop gerakan
	player.velocity = Vector2.ZERO

func _exit() -> void:
	# Bersih-bersih: Putuskan koneksi sinyal saat keluar state
	# Agar tidak error saat animasi lain selesai di state lain
	if player.animation_player.animation_finished.is_connected(_on_animation_finished):
		player.animation_player.animation_finished.disconnect(_on_animation_finished)

# Fungsi ini otomatis dipanggil oleh Godot saat animasi selesai
func _on_animation_finished(anim_name: String):
	if anim_name == "Attack1":
		get_root().dispatch("state_ended") # Baru kita akhiri state disini

func _update(delta: float) -> void:
	# Tetap terapkan gravitasi
	player.velocity.y += player.gravity * delta
