class_name BossSlimeMech
extends EnemyController

@export var projectile_scene: PackedScene

@onready var gun_left = $Visuals/GunLeft
@onready var gun_right = $Visuals/GunRight

# --- CONFIG DODGE ---
@export_group("AI Reactions")
@export var dodge_chance: float = 0.5    
@export var dodge_cooldown: float = 4.0  
@export var reaction_range: float = 250.0 

var dodge_timer: float = 0.0
var is_dodging: bool = false 

# Variabel Charge
var is_charging_active: bool = false
var charge_direction: int = 0
var charge_speed_val: float = 0.0
# Variabel Jump
var is_jumping_logic: bool = false 

# --- JUICE VARIABLES ---
var was_in_air: bool = false
var tween_squash: Tween

var is_phase_two: bool = false

func _ready() -> void:
	super._ready() # PENTING: Panggil fungsi bapaknya agar koneksi sinyal HealthComponent jalan
	
	# Setting manual stats boss jika perlu (Opsional, lebih baik set di Inspector)
	if body_hitbox:
		body_hitbox.damage = stats.contact_damage
		# Boss biasanya lebih berat, knockback force yang dia berikan besar
		body_hitbox.knockback_force = 400.0

func _physics_process(delta: float) -> void:
	if dodge_timer > 0: dodge_timer -= delta

	# 1. REACTIVE DODGE
	if is_on_floor() and not is_charging_active and not is_hurt and not is_dead:
		if dodge_timer <= 0:
			_check_player_input_dodge()

	if body_hitbox and not is_dead:
		body_damage_cooldown -= delta
		if body_damage_cooldown <= 0:
			body_hitbox.reset_hitbox() # Hapus daftar korban
			body_damage_cooldown = body_reset_time

	# 2. Update Blackboard & Gravity
	if bt_player:
		bt_player.blackboard.set_var("is_attacking", is_attacking)
		var t = bt_player.blackboard.get_var("target", null)
		if is_instance_valid(t):
			bt_player.blackboard.set_var("distance_to_player", global_position.distance_to(t.global_position))
		else:
			bt_player.blackboard.set_var("distance_to_player", 9999.0)

	# --- JUICE: LANDING SQUASH ---
	if not is_on_floor():
		was_in_air = true
	else:
		if was_in_air:
			# Mendarat -> Gepeng
			_apply_squash_stretch(1.3, 0.7) 
			
			# Jika jatuh dari tinggi (Spider Jump) -> Shake Layar
			if velocity.y > 500: 
				_shake_camera(3.0) # Shake agak kuat
				
			was_in_air = false

	if not is_on_floor():
		velocity.y += gravity * stats.gravity_scale * delta

	for k in attack_cooldowns.keys():
		if attack_cooldowns[k] > 0: attack_cooldowns[k] -= delta

	# 3. MOVEMENT LOGIC
	if is_charging_active:
		velocity.x = charge_direction * charge_speed_val
		if is_on_wall(): _end_charge_collision()
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			if col.get_collider().is_in_group("player"):
				_end_charge_collision()
				break
				
	elif is_dodging:
		velocity.x = move_toward(velocity.x, 0, stats.friction * 0.5 * delta)
		
		if is_on_floor() and velocity.y >= 0:
			is_dodging = false
			is_attacking = false
			is_charging_active = false
			var atk_hitbox = visuals.get_node_or_null("AttackHitbox")
			if atk_hitbox: atk_hitbox.set_deferred("monitoring", false)
			
			face_target() 
			if animation_player.has_animation("Idle"): animation_player.play("Idle")
			
	elif not is_jumping_logic:
		if is_attacking or is_hurt or is_dead:
			velocity.x = move_toward(velocity.x, 0, stats.friction * delta)
	
	_update_vision()
	move_and_slide()

# --- FUNGSI UTAMA: INPUT READING ---
func _check_player_input_dodge():
	var target = bt_player.blackboard.get_var("target", null)
	if not is_instance_valid(target): return
	
	var dist = global_position.distance_to(target.global_position)
	if dist > reaction_range: return
	
	# Pastikan input map "attack" dan "skill_1" sudah ada di Project Settings
	var player_pressed_attack = Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("skill_1")
	
	if player_pressed_attack:
		if randf() <= dodge_chance:
			_perform_dodge_maneuver(target)

func _perform_dodge_maneuver(target: Node2D):
	dodge_timer = dodge_cooldown
	is_attacking = false 
	is_charging_active = false
	is_dodging = true
	
	var dir_to_player = sign(target.global_position.x - global_position.x)
	if dir_to_player == 0: dir_to_player = 1
	
	var back_dir = -dir_to_player
	var space_behind = _check_space(Vector2(back_dir, 0), 150.0)
	
	# JUICE: Stretch saat mulai dodge
	_apply_squash_stretch(0.7, 1.3)

	if space_behind:
		# BACKSTEP
		velocity = Vector2(back_dir * 600, -200)
		visuals.scale.x = dir_to_player 
	else:
		# SPIDER JUMP
		var jump_force_x = dir_to_player * 400 
		velocity = Vector2(jump_force_x, -500) 
		visuals.scale.x = dir_to_player

	if animation_player.has_animation("Jump"):
		animation_player.play("Jump")

func _check_space(direction: Vector2, distance: float) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query_wall = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -20), 
		global_position + Vector2(0, -20) + (direction * distance),
		1 
	)
	var result_wall = space_state.intersect_ray(query_wall)
	if result_wall: return false 
	return true 

# --- HELPER FUNCTIONS ---

func face_target():
	var target = bt_player.blackboard.get_var("target", null)
	if is_instance_valid(target):
		var dir_to_player = sign(target.global_position.x - global_position.x)
		if dir_to_player != 0:
			# Gunakan flip H di editor (Sprite hadap kanan)
			visuals.scale.x = dir_to_player

func perform_attack(index: int, target_pos: Vector2):
	if is_dodging: return 
	super.perform_attack(index, target_pos)
	
	var laser_hitbox = visuals.get_node_or_null("LaserHitbox")
	if laser_hitbox: 
		# Reset agar player yang kena laser sebelumnya bisa kena lagi di serangan baru
		if laser_hitbox.has_method("reset_hitbox"):
			laser_hitbox.reset_hitbox() 
	
	var atk_hitbox = visuals.get_node_or_null("AttackHitbox")
	if atk_hitbox and atk_hitbox.has_method("reset_hitbox"):
		atk_hitbox.reset_hitbox()
	
	if index == 0: # SHOOT
		get_tree().create_timer(0.3).timeout.connect(_fire_projectiles)
	
	elif index == 1:
		# Reset hitbox melee seperti biasa
		var melee_hitbox = visuals.get_node_or_null("AttackHitbox")
		if melee_hitbox and melee_hitbox.has_method("reset_hitbox"):
			melee_hitbox.reset_hitbox()
		
	elif index == 2: # CHARGE
		velocity.y = 0 
		is_charging_active = true
		
		# JUICE: Charge Start Squash
		_apply_squash_stretch(1.2, 0.8)
		
		var dir = (target_pos - global_position).normalized()
		charge_direction = 1 if dir.x > 0 else -1
		visuals.scale.x = charge_direction
		
		var atk = stats.attacks[index]
		charge_speed_val = atk.lunge_speed 

func _end_charge_collision():
	if not is_charging_active: return
	
	is_charging_active = false
	is_attacking = false 
	
	velocity.x = -charge_direction * 100 
	
	# JUICE: Nabrak Tembok -> Shake Kencang & Squash
	_shake_camera(5.0) 
	_apply_squash_stretch(0.6, 1.4) 
	
	if animation_player.has_animation("Idle"):
		animation_player.play("Idle")

func _fire_projectiles():
	# Cek kondisi dasar
	if is_dead or not is_attacking: return
	
	# Pastikan scene peluru sudah dipasang di Inspector
	if projectile_scene:
		# Spawn dari Marker Kiri (Jika node ada)
		if gun_left:
			_spawn_one(gun_left.global_position)
		else:
			# Fallback jika lupa pasang marker: Spawn dari badan
			_spawn_one(global_position + Vector2(-20, 0))
			
		# Spawn dari Marker Kanan (Jika node ada)
		if gun_right:
			_spawn_one(gun_right.global_position)
		else:
			# Fallback
			_spawn_one(global_position + Vector2(20, 0))
	
func _spawn_one(pos: Vector2):
	var p = projectile_scene.instantiate()
	p.global_position = pos
	
	if "is_phase_two_projectile" in p:
		p.is_phase_two_projectile = is_phase_two
	
	var target = bt_player.blackboard.get_var("target", null)
	if is_instance_valid(target):
		var target_center = target.global_position + Vector2(0, -25.0)
		p.direction = (target_center - pos).normalized()
		p.rotation = p.direction.angle()
	else:
		var dir_x = visuals.scale.x
		p.direction = Vector2(dir_x, 0)
		p.rotation = 0 if dir_x > 0 else PI
	get_parent().add_child(p)

func _on_damaged(amount: int, source_pos: Vector2, knockback_force: float):
	if is_dead: return
	
	# A. Efek Visual (Juice)
	_shake_camera(2.0)
	_apply_squash_stretch(1.1, 0.9) # Sedikit getar
	
	if is_phase_two and is_attacking: 
		# Kita kurangi darah tapi boss tidak goyah/tidak mainkan animasi hurt
		return
	# B. Reset Status Spesial Boss (Interupsi)
	# Jika player memukul saat boss sedang charge -> Batalkan charge-nya!
	if is_charging_active:
		is_charging_active = false
		velocity.x = 0 # Stop lari
	
	if is_dodging:
		is_dodging = false
	
	# C. Panggil Logika Parent (EnemyController)
	# TAPI kita kurangi knockback_force agar Boss terasa "Berat" (Super Armor)
	# Kalikan 0.1 (hanya terima 10% efek dorong)
	super._on_damaged(amount, source_pos, knockback_force * 0.1)
	
	if not is_phase_two and health_component.current_health <= (health_component.max_health * 0.5):
		enter_phase_two()

func enter_phase_two():
	is_phase_two = true
	print("BOSS ENTERED PHASE 2! BEWARE!")
	
	is_attacking = true 
	is_charging_active = false
	is_dodging = false
	is_hurt = false
	
	# Visual Feedback (Opsional): Ubah warna boss jadi merah
	var sprite = visuals.get_node("Sprite2D")
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 0.5, 0.5), 0.5) # Jadi kemerahan
	
	# Visual Feedback (Opsional): Shake layar
	_shake_camera(4.0)
	
	if animation_player.has_animation("Idle"):
		animation_player.play("Idle")
		# Opsional: Percepat speed scale biar terlihat "marah/bergetar"
		animation_player.speed_scale = 2.0
	
	get_tree().create_timer(1.5).timeout.connect(_finish_phase_transition)

func _finish_phase_transition():
	if is_dead: return
	
	# Kembalikan semua ke normal
	is_attacking = false # AI boleh ambil alih lagi
	animation_player.speed_scale = 1.0 # Speed normal lagi
	
	# Reset Hitbox (jaga-jaga)
	var atk_hitbox = visuals.get_node_or_null("AttackHitbox")
	if atk_hitbox: atk_hitbox.set_deferred("monitoring", false)
	
	print("Boss Fase 2 Siap Tempur!")

# 2. SAAT MATI
func _on_died():
	# A. Matikan AI
	if bt_player:
		bt_player.active = false # Stop berpikir
	
	# B. Efek Dramatis (Slow Motion)
	# Pastikan GameManager punya fungsi hit_stop 
	GameManager.hit_stop(0.2, 2.0) # Time scale 0.2 selama 2 detik (Real time)
	_shake_camera(5.0) # Shake kencang
	
	# C. Panggil Logika Parent (Animasi Die, Matikan Collision, Drop Loot)
	super._on_died()

# --- OVERRIDE ANIMATION FINISH ---
func _on_animation_finished(anim_name: String):
	if anim_name == "Die":
		print("Boss tewas. Menjadi mayat abadi.")
		
		# Mainkan animasi mayat
		if animation_player.has_animation("AfterDie"):
			animation_player.play("AfterDie")
		
		# PENTING: Jangan panggil super._on_animation_finished("Die")
		# karena itu akan menghapus boss dari game (queue_free).
		return
	
	super._on_animation_finished(anim_name)
	
	if anim_name == "Hurt":
		is_charging_active = false
		is_dodging = false
	if anim_name == "Shoot" or anim_name == "Melee":
		is_attacking = false
		var atk_hitbox = visuals.get_node_or_null("AttackHitbox")
		if atk_hitbox: atk_hitbox.set_deferred("monitoring", false)
		if animation_player.has_animation("Idle"):
			animation_player.play("Idle")

# --- JUICE FUNCTIONS (UPDATED) ---

func _apply_squash_stretch(x_scale: float, y_scale: float):
	if tween_squash and tween_squash.is_valid():
		tween_squash.kill()
	
	tween_squash = create_tween()
	tween_squash.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	var facing = sign(visuals.scale.x)
	if facing == 0: facing = 1
	
	tween_squash.tween_property(visuals, "scale", Vector2(x_scale * facing, y_scale), 0.1)
	tween_squash.tween_property(visuals, "scale", Vector2(1.0 * facing, 1.0), 0.4)

func _shake_camera(amount: float):
	# 1. Ambil kamera aktif (Cutscene Manager Camera)
	var cam = get_viewport().get_camera_2d()
	
	if cam:
		# Opsi A: Jika kamera punya script shake sendiri (Player Camera)
		if cam.has_method("apply_shake"):
			cam.apply_shake(amount)
			
		# Opsi B: MANUAL SHAKE (Untuk kamera statis/cutscene manager)
		# Kita gerakkan offset kamera secara acak
		else:
			var shake_tween = create_tween()
			var shake_duration = 0.2
			var shake_steps = 5
			
			for i in shake_steps:
				var random_offset = Vector2(
					randf_range(-amount, amount), 
					randf_range(-amount, amount)
				)
				shake_tween.tween_property(cam, "offset", random_offset, shake_duration / shake_steps)
			
			# Kembalikan ke 0
			shake_tween.tween_property(cam, "offset", Vector2.ZERO, 0.05)
