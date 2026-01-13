class_name PlayerController
extends CharacterBody2D

# --- KOMPONEN "ALAT DEWA" ---
# Cukup drag-and-drop Resource ke sini di Inspector
@export var stats: PlayerStats 

# Inventory Skill (Bisa punya banyak, bisa diganti saat runtime)
@export var equipped_skills: Array[BaseSkill] = []

# --- KOMPONEN SISTEM ---
@onready var limbo_hsm: LimboHSM = $LimboHSM
# @onready var health_component = $HealthComponent (Nanti)



var temp_active_skill: BaseSkill = null

# --- VARIABLE TEMPORARY UNTUK SKILL ---
# Ini variabel "Titipan" dari Resource Skill ke State
var temp_dash_speed: float = 0.0
var temp_dash_duration: float = 0.0

var temp_skill_damage: int = 0
var temp_skill_anim: String = ""

var temp_knockback: Vector2 = Vector2.ZERO # Titipan knockbacks

var knockback_lock_timer: float = 0.0 # Timer pengunci input

var is_dead_flag: bool = false # Ganti nama variable agar tidak bentrok dengan state

#Variabel charge/hold
var temp_skill_can_charge: bool = false
var temp_skill_max_charge: float = 0.0
var temp_skill_multiplier: float = 1.0

@onready var health_component: HealthComponent = $HealthComponent

#Visual
@onready var visuals: Marker2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D 
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var camera_shaker: Camera2D = $Camera2D
# --- LOGIKA LOMPAT LANJUTAN ---
var jump_count: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# --- GLOBAL VARIABLES ---
# Variable yang sering diakses oleh State LimboAI
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var input_axis: float = 0.0

func _ready() -> void:
	# Validasi safety
	if not stats:
		push_error("STATS BELUM DIPASANG! Pasang resource PlayerStats di Inspector.")
		set_physics_process(false)
		return
	
	if stats:
		# Baris ini mengubah kapasitas gelas (Max HP)
		health_component.max_health = stats.max_health
		
		# --- BARIS YANG HILANG (FIX) ---
		# Baris ini mengisi airnya sampai penuh sesuai kapasitas baru!
		health_component.current_health = stats.max_health 
	
	if GlobalUI:
		GlobalUI.show_ui()
		# (Opsional) Update UI bar darah jika ada
		# health_component.health_changed.emit(stats.max_health, stats.max_health)
	
	health_component.died.connect(_on_died)
	health_component.damaged.connect(_on_damaged)
	
	# 1. Sambungkan sinyal perubahan darah
	health_component.health_changed.connect(_on_health_changed)
	
	# 2. Update UI pertama kali saat game mulai (agar tidak kosong)
	# Kita panggil manual sekali biar angkanya muncul
	_on_health_changed(health_component.current_health, health_component.max_health)
	
	_initialize_hsm()

func _physics_process(delta: float) -> void:
	# 1. Update Timers
	if coyote_timer > 0:
		coyote_timer -= delta
		
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	# 2. Input Buffer (Mengingat tombol lompat sesaat sebelum mendarat)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = stats.jump_buffer
	
	# 3. Reset Double Jump saat di tanah
	if is_on_floor():
		jump_count = 0
		# PENTING: Coyote time kita set manual saat JATUH dari tebing (di MoveState), 
		# bukan di sini.
	# Dapatkan input global di sini agar semua State bisa baca
	input_axis = Input.get_axis("move_left", "move_right")
	
	
	
	# Gravitasi manual (agar bisa dimanipulasi per stats)
	if not is_on_floor():
		velocity.y += gravity * stats.gravity_scale * delta
	
	if Input.is_action_just_pressed("attack"):
		limbo_hsm.dispatch("attack_started")
	
	for skill in equipped_skills:
		if skill.has_method("tick_cooldown"):
			skill.tick_cooldown(delta)
			
	# Cek Input Dash (Asumsi Skill Dash dipasang di slot 0)
	if Input.is_action_just_pressed("dash"):
		use_skill(0) # Panggil skill slot pertama
		
	if Input.is_action_just_pressed("skill_1"): # Pastikan action ini ada di Project Settings
		use_skill(1)
	
	# Gravitasi & Move Slide
	# --- PERBAIKAN GRAVITASI (BETTER JUMP PHYSICS) ---
	if not is_on_floor():
		var final_gravity = gravity * stats.gravity_scale
		
		# JIKA JATUH: Gravitasi diperberat (misal 1.5x lipat)
		# Ini membuat lompatan terasa 'snappy' (cepat naik, cepat turun)
		if velocity.y > 0:
			final_gravity *= 1.5 
			
		velocity.y += final_gravity * delta
		
		# Opsional: Terminal Velocity (Batas kecepatan jatuh maksimum)
		# Agar tidak menembus lantai jika jatuh terlalu tinggi
		velocity.y = min(velocity.y, 1000.0) 
	# ------------------------------------------------
		
	# Update skill cooldowns...
	move_and_slide()

# --- FUNGSI BARU UNTUK KOMUNIKASI DATA ---
func apply_dash_data(speed: float, duration: float):
	temp_dash_speed = speed
	temp_dash_duration = duration

# --- SKILL SYSTEM HOOK ---
# Di dalam player_controller.gd

func use_skill(index: int):
	# 1. Cek State Aktif
	# Kita tidak mau skill keluar saat sedang Attack, Hurt, atau Mati
	var current_state = limbo_hsm.get_active_state()
	
	# Daftar state yang "Haram" diganggu skill (Blocking States)
	if current_state.name == "Attack" or current_state.name == "Dead":
		# Opsi A: Abaikan total (Cooldown aman)
		return 
		
		# Opsi B (Advanced): Kalau mau sistem "Antrian" (Input Buffer),
		# simpan index skill ini di variabel 'queued_skill_index' 
		# dan panggil nanti saat state Attack selesai.
	
	# 2. Eksekusi Skill (Hanya jika lolos cek di atas)
	if index < equipped_skills.size() and equipped_skills[index] != null:
		equipped_skills[index].execute(self, stats)
# --- LIMBO AI SETUP ---
func _initialize_hsm():
	# 1. Load Script dan buat Instance-nya (.new)
	# Kita harus membuat "benda"-nya dari cetak biru (script)
	var idle_node = load("res://entities/player/states/idle_state.gd").new()
	var move_node = load("res://entities/player/states/move_state.gd").new()
	var air_node = load("res://entities/player/states/air_state.gd").new()
	var dash_node = load("res://entities/player/states/dash_state.gd").new()
	var attack_node = load("res://entities/player/states/attack_state.gd").new()
	var cast_node = load("res://entities/player/states/cast_state.gd").new()
	var wall_slide_node = load("res://entities/player/states/wall_slide_state.gd").new()
	var wall_jump_node = load("res://entities/player/states/wall_jump_state.gd").new()
	var knockback_node = load("res://entities/player/states/knockback_state.gd").new()
	
	# 2. Beri Nama pada Node (Penting untuk debugging)
	idle_node.name = "Idle"
	move_node.name = "Move"
	air_node.name = "Air"
	dash_node.name = "Dash"
	attack_node.name = "Attack"
	cast_node.name = "Cast"
	wall_slide_node.name = "WallSlide"
	wall_jump_node.name = "WallJump"
	knockback_node.name = "Knockback"

	# 3. Tambahkan sebagai anak (Child) dari LimboHSM
	# Ini pengganti 'add_state'. LimboAI otomatis menganggap anak sebagai State.
	limbo_hsm.add_child(idle_node)
	limbo_hsm.add_child(move_node)
	limbo_hsm.add_child(air_node)
	limbo_hsm.add_child(dash_node)
	limbo_hsm.add_child(attack_node)
	limbo_hsm.add_child(cast_node)
	limbo_hsm.add_child(wall_slide_node)
	limbo_hsm.add_child(wall_jump_node)
	limbo_hsm.add_child(knockback_node)
	
	# --- DEFINISI TRANSISI ---
	# Format: add_transition(DARI_NODE, KE_NODE, NAMA_EVENT)
	
	# Dari Idle
	limbo_hsm.add_transition(idle_node, move_node, "move_started")
	limbo_hsm.add_transition(idle_node, air_node, "jump_started")
	limbo_hsm.add_transition(idle_node, air_node, "fall_started")
	
	# Dari Move
	limbo_hsm.add_transition(move_node, idle_node, "state_ended") 
	limbo_hsm.add_transition(move_node, air_node, "jump_started")
	limbo_hsm.add_transition(move_node, air_node, "fall_started")
	
	# Dari Air
	limbo_hsm.add_transition(air_node, idle_node, "state_ended")
	limbo_hsm.add_transition(air_node, move_node, "move_started")
	
	# Masuk ke Dash
	limbo_hsm.add_transition(idle_node, dash_node, "dash_started")
	limbo_hsm.add_transition(move_node, dash_node, "dash_started")
	limbo_hsm.add_transition(air_node, dash_node, "dash_started")
	
	# Keluar dari Dash (Biasanya langsung ke Air/Fall state)
	limbo_hsm.add_transition(dash_node, air_node, "fall_started")
	limbo_hsm.add_transition(dash_node, idle_node, "state_ended")
	limbo_hsm.add_transition(dash_node, move_node, "move_started")
	
	# Bisa serang dari tanah atau udara
	limbo_hsm.add_transition(idle_node, attack_node, "attack_started")
	limbo_hsm.add_transition(move_node, attack_node, "attack_started")
	limbo_hsm.add_transition(air_node, attack_node, "attack_started")

	# Setelah attack selesai, kembali ke Idle (atau Air jika di udara, tapi Idle dulu cukup aman)
	limbo_hsm.add_transition(attack_node, idle_node, "state_ended")
	# 1. Masuk ke Wall Slide (Dari Air)
	limbo_hsm.add_transition(air_node, wall_slide_node, "wall_slide_started")
	
	# 2. Dari Wall Slide -> Keluar
	limbo_hsm.add_transition(wall_slide_node, air_node, "fall_started") # Lepas tembok
	limbo_hsm.add_transition(wall_slide_node, idle_node, "state_ended") # Mendarat
	
	# 3. Wall Jump
	limbo_hsm.add_transition(wall_slide_node, wall_jump_node, "wall_jump")
	
	# 4. Selesai Wall Jump -> Kembali ke Air
	limbo_hsm.add_transition(wall_jump_node, air_node, "state_ended")
	
	# --- TAMBAHAN: ATTACK CANCELLING ---
	# Izinkan Dash membatalkan Attack
	limbo_hsm.add_transition(attack_node, dash_node, "dash_started")
	
	# Izinkan Skill (Cast) membatalkan Attack
	limbo_hsm.add_transition(attack_node, cast_node, "skill_cast_started")
	
	# 2. Transisi "DARIMANA SAJA" ke Knockback
	# (Copy-paste blok ini)
	limbo_hsm.add_transition(idle_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(move_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(air_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(dash_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(attack_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(cast_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(wall_slide_node, knockback_node, "knockback_started")
	
	# 3. Keluar dari Knockback
	limbo_hsm.add_transition(knockback_node, idle_node, "state_ended")
	limbo_hsm.add_transition(knockback_node, air_node, "fall_started")
	
	# 4. Inisialisasi HSM
	# initial_state harus berupa Node yang sudah di-add_child
	limbo_hsm.initial_state = idle_node
	limbo_hsm.initialize(self)
	limbo_hsm.set_active(true)
	
	# 2. TRANSISI
	# Bisa skill dari Idle, Move, Air
	limbo_hsm.add_transition(idle_node, cast_node, "skill_cast_started")
	limbo_hsm.add_transition(move_node, cast_node, "skill_cast_started")
	limbo_hsm.add_transition(air_node, cast_node, "skill_cast_started")
	
	# Keluar dari skill -> kembali ke Idle
	limbo_hsm.add_transition(cast_node, idle_node, "state_ended")

func apply_recoil(direction: Vector2):
	# Beri sedikit dorongan instan
	velocity += direction * 20 # Angka 200 bisa diatur sesuai selera
	move_and_slide()

# FUNGSI BARU: Menerima data dari Skill Resource
func prepare_skill_attack(dmg: int, anim: String, charging: bool = false, charge_time: float = 0.0, mult: float = 1.0):
	temp_skill_damage = dmg
	temp_skill_anim = anim
	temp_skill_can_charge = charging
	temp_skill_max_charge = charge_time
	temp_skill_multiplier = mult

func _on_died():
	if not is_physics_processing(): return # Mencegah dipanggil 2x
	
	print("PLAYER MATI! Requesting Respawn...")
	
	set_physics_process(false)
	set_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Panggil GameManager
	GameManager.respawn_player()
# Fungsi helper untuk mengurangi 'stok' lompatan
func perform_jump():
	velocity.y = stats.jump_force
	jump_count += 1
	jump_buffer_timer = 0 
	coyote_timer = 0

	# EFEK BARU: Stretch (Kurus 0.8, Panjang 1.2)
	apply_squash_stretch(0.8, 1.2)

# GANTI FUNGSI LAMA DENGAN INI
func apply_squash_stretch(x_scale: float, y_scale: float):
	if visuals:
		# 1. Simpan arah hadap saat ini (-1 atau 1)
		var current_facing = sign(visuals.scale.x)
		if current_facing == 0: current_facing = 1 # Safety check
		
		# 2. Reset scale tapi KALIKAN dengan arah hadap
		# Ini mencegah karakter tiba-tiba berbalik ke kanan
		visuals.scale = Vector2(1 * current_facing, 1) 
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.set_ease(Tween.EASE_OUT)
		
		# 3. Terapkan Squash/Stretch dengan tetap mempertahankan arah
		visuals.scale = Vector2(x_scale * current_facing, y_scale)
		
		# 4. Kembalikan ke normal (juga mempertahankan arah)
		tween.tween_property(visuals, "scale", Vector2(1.0 * current_facing, 1.0), 0.15)

# --- EFEK VISUAL GHOST TRAIL ---
func add_ghost_trail():
	# 1. Buat Sprite Baru (Kosong)
	var ghost = Sprite2D.new()
	
	# 2. Salin Data Sprite Pemain Saat Ini
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	
	# 3. Salin Posisi & Skala
	# PENTING: Gunakan global_position agar hantu tidak ikut bergerak nempel player
	ghost.global_position = sprite.global_position 
	ghost.scale = visuals.scale # Agar arah hadap (kiri/kanan) sesuai
	
	# 4. Atur Warna & Z-Index
	ghost.modulate = Color(0.5, 0.5, 1.0, 0.5) # Warna Biru transparan (R, G, B, Alpha)
	ghost.z_index = -1 # Agar muncul di BELAKANG player
	
	# 5. Masukkan ke dalam Scene (Sebagai saudara player, bukan anak player)
	get_parent().add_child(ghost)
	
	# 6. Animasi Fade Out (Menghilang)
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3) # Hilang dalam 0.3 detik
	tween.tween_callback(ghost.queue_free) # Hapus dari memori setelah selesai

func _on_damaged(amount: int, source_pos: Vector2, knockback_force: float):
	if is_dead_flag: return
	
	# 1. HIT STOP (Tetap Ada)
	GameManager.hit_stop(0.00, 0)
	
	# 2. IFRAME BLINKING (Tetap Ada - Visual)
	_start_iframe_blink()
	
	# 3. KNOCKBACK PHYSICS (Perbaikan)
	# Hitung arah mental
	var dir = (global_position - source_pos).normalized()
	# Pentalan selalu sedikit ke atas biar enak (parabola)
	var knock_dir = Vector2(sign(dir.x), -0.8).normalized() 
	
	# Simpan data untuk diambil KnockbackState
	# Gunakan force dari hitbox, atau default 300 jika 0
	var force = knockback_force if knockback_force > 0 else 300.0
	temp_knockback = knock_dir * force
	
	# 4. PINDAH STATE (Agar MoveState tidak mengganggu fisika)
	limbo_hsm.dispatch("knockback_started")
	
func _start_iframe_blink():
	# 1. Ambil durasi kebal dari HealthComponent
	var duration = health_component.iframe_duration
	
	# 2. Setup Tween untuk Kedip-Kedip
	var tween = create_tween()
	
	# Kita set loop agar berjalan terus...
	tween.set_loops() 
	
	# ...tapi logika loopnya begini:
	# Transparan dalam 0.1 detik -> Terang dalam 0.1 detik (Total 0.2 detik per kedip)
	tween.tween_property(visuals, "modulate:a", 0.2, 0.1) # Jadi Transparan
	tween.tween_property(visuals, "modulate:a", 1.0, 0.1) # Jadi Padat lagi
	
	# 3. Hentikan Tween setelah durasi habis
	# Kita buat timer manual untuk mematikan kedipan
	get_tree().create_timer(duration).timeout.connect(func():
		tween.kill() # Matikan animasi kedip
		visuals.modulate.a = 1.0 # Pastikan sprite kembali terlihat penuh (safety)
	)

func trigger_skill_cooldown():
	if temp_active_skill and temp_active_skill.has_method("start_cooldown"):
		temp_active_skill.start_cooldown()
		temp_active_skill = null # Reset setelah dipakai

# Callback saat darah berubah (Heal atau Kena Damage)
func _on_health_changed(current_val: int, max_val: int):
	# Panggil fungsi di GlobalUI (karena Autoload, bisa langsung dipanggil namanya)
	if GlobalUI.has_method("update_hp_ui"):
		GlobalUI.update_hp_ui(current_val, max_val)
