extends PlayerState

var is_charging: bool = false
var current_charge_time: float = 0.0
var has_released: bool = false
var skill_hitbox: HitboxComponent

func _enter() -> void:
	super()
	
	# 1. Reset Variable
	is_charging = player.temp_skill_can_charge
	current_charge_time = 0.0
	has_released = false
	
	# 2. Ambil Hitbox
	skill_hitbox = player.get_node("Visuals/SkillHitbox") as HitboxComponent
	
	if skill_hitbox:
		# Set damage awal (penting untuk instant skill)
		skill_hitbox.damage = player.temp_skill_damage
		# Reset agar musuh bisa dipukul lagi di cast ini
		skill_hitbox.reset_hitbox()
		# Pastikan monitoring nyala
		skill_hitbox.set_deferred("monitoring", true)
	
	# 3. Mainkan Animasi
	if player.animation_player.has_animation(player.temp_skill_anim):
		player.animation_player.play(player.temp_skill_anim)
		
		# --- LOGIKA CHARGE ---
		if is_charging:
			# Segera PAUSE animasi di frame awal (frame mengangkat pedang)
			# Biasanya frame ke-1 atau ke-2 (0.1 detik pertama)
			# Kita tunggu sebentar biar kelihatan ngangkat, baru pause
			await get_tree().create_timer(0.1).timeout 
			if is_charging and not has_released: # Cek lagi takutnya keburu dilepas
				player.animation_player.pause()
	else:
		get_root().dispatch("state_ended")
		return

	player.velocity = Vector2.ZERO
	
	# Sambungkan sinyal selesai (hanya dipanggil setelah dilepas)
	if not player.animation_player.animation_finished.is_connected(_on_animation_finished):
		player.animation_player.animation_finished.connect(_on_animation_finished)

func _update(delta: float) -> void:
	player.velocity.y += player.gravity * delta
	
	# --- LOGIKA CHARGE ---
	if is_charging and not has_released:
		# Hitung waktu tahan
		current_charge_time += delta
		
		# EFEK VISUAL CHARGING (Opsional: Getar atau Flash Putih)
		if current_charge_time >= player.temp_skill_max_charge:
			# Full Charge! Kasih tanda visual (misal warna jadi merah)
			player.visuals.modulate = Color(2, 1, 1) # Glowing Red
		
		# Cek Input Lepas (Action skill_1 atau attack sesuai input map Anda)
		if Input.is_action_just_released("skill_1"):
			_release_attack()

func _release_attack():
	has_released = true
	player.animation_player.play() # LANJUTKAN ANIMASI (Resume)
	
	# Hitung Damage Akhir
	var final_damage = player.temp_skill_damage
	
	# Jika charge penuh, kalikan damage
	if current_charge_time >= player.temp_skill_max_charge:
		final_damage *= player.temp_skill_multiplier
		print("FULL CHARGE ATTACK! Damage: ", final_damage)
		# Reset warna visual
		player.visuals.modulate = Color.WHITE
		
		# Tambahkan efek Juice (Screen Shake lebih kencang)
		if player.camera_shaker:
			player.camera_shaker.apply_shake(5.0)
	else:
		print("Normal Attack. Damage: ", final_damage)
	
	# Update Hitbox dengan damage baru
	if skill_hitbox:
		skill_hitbox.damage = int(final_damage)
		skill_hitbox.reset_hitbox()

func _on_animation_finished(anim_name: String):
	if anim_name == player.temp_skill_anim:
		# Reset modulasi warna jaga-jaga
		player.visuals.modulate = Color.WHITE
		#player.trigger_skill_cooldown()
		get_root().dispatch("state_ended")

func _exit() -> void:
	# 1. Pastikan cooldown tetap jalan (Existing)
	#if player.temp_active_skill:
		#player.trigger_skill_cooldown()

	# 2. Putuskan koneksi sinyal (Existing)
	if player.animation_player.animation_finished.is_connected(_on_animation_finished):
		player.animation_player.animation_finished.disconnect(_on_animation_finished)
	
	# 3. FIX: UNPAUSE ANIMATION
	# Jika player kena hit saat sedang charging (animasi pause), kita harus resume dulu
	# agar AnimationPlayer tidak nyangkut statenya di state berikutnya.
	if player.animation_player.current_animation == player.temp_skill_anim:
		if not player.animation_player.is_playing():
			player.animation_player.play() 
	
	# 4. FIX: MATIKAN HITBOX PAKSA
	# Jangan andalkan animasi untuk mematikan hitbox saat interupsi (kena hit)
	if skill_hitbox:
		skill_hitbox.set_deferred("monitoring", false)
	
	# 5. FIX: SEMBUNYIKAN EFEK VISUAL
	# Cari node efek visual (selain sprite utama) dan sembunyikan
	# Sesuaikan "EffectSprite" dengan nama node efek skill di scene player Anda
	var effect_sprite = player.visuals.get_node_or_null("EffectSprite")
	if effect_sprite:
		effect_sprite.visible = false
	
	# Atau cara general: Sembunyikan semua Sprite selain Sprite Utama
	for child in player.visuals.get_children():
		if child is Sprite2D and child != player.sprite:
			child.visible = false

	# 6. Reset Warna (Existing)
	player.visuals.modulate = Color.WHITE
