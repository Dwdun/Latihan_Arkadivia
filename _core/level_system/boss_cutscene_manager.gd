extends Node2D

@export var boss_visual_scene: PackedScene 
@export var boss_name_display: String = "THE DARK KNIGHT"
@export var entry_gate: Node2D
@export var arena_center: Marker2D
@export var boss_combat_scene: PackedScene

@onready var slime_container = $SlimeContainer

var boss_instance = null 

func _ready():
	$TriggerArea.body_entered.connect(_on_body_entered)
	$Camera2D.enabled = false
	if slime_container: slime_container.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		$TriggerArea.set_deferred("monitoring", false)
		start_cutscene()

func start_cutscene():
	print("Action!")
	
	GameManager.set_cutscene_mode(true)
	if GlobalUI:
		GlobalUI.toggle_cinematic_bars(true, boss_name_display)

	if slime_container:
		slime_container.visible = true

	#if boss_visual_scene:
		#boss_instance = boss_visual_scene.instantiate()
		#add_child(boss_instance)
		#boss_instance.global_position = $BossSpawnPos.global_position
	
	if GlobalUI:
		GlobalUI.toggle_cinematic_bars(true, boss_name_display)
	$CutsceneDirector.play("IntroSequence")

func anim_setup_camera():
	# Pindahkan kamera ke titik awal (dekat pintu)
	$Camera2D.global_position = $CameraStartPos.global_position
	$Camera2D.enabled = true
	$Camera2D.make_current() # Ambil alih layar
	
		
	if entry_gate and entry_gate.has_method("close_gate"):
		entry_gate.close_gate()

func anim_slime_set():
	$SlimeContainer/Slime1/SlimePlayer.play("Set")
	$SlimeContainer/Slime2/SlimePlayer.play("Set")
	$SlimeContainer/Slime3/SlimePlayer.play("Set")
	$SlimeContainer/Slime4/SlimePlayer.play("Set")

func anim_slime_walkto():
	$SlimeContainer/Slime1/SlimePlayer.play("Walkto")
	$SlimeContainer/Slime2/SlimePlayer.play("Walkto")
	$SlimeContainer/Slime3/SlimePlayer.play("Walkto")
	$SlimeContainer/Slime4/SlimePlayer.play("Walkto")

# Dipanggil di tengah-tengah (misal detik 2.0)
func anim_boss_roar():
	# Cek apakah boneka punya AnimationPlayer sendiri
	if boss_instance and boss_instance.has_node("AnimationPlayer"):
		boss_instance.get_node("AnimationPlayer").play("Intro")
		# Opsional: Mainkan suara teriakan
		# AudioManager.play_sfx("monster_roar")

func anim_spawn_boss_morph():
	if slime_container:
		slime_container.visible = false

	if boss_visual_scene:
		boss_instance = boss_visual_scene.instantiate()
		add_child(boss_instance)
		boss_instance.global_position = $BossSpawnPos.global_position

	if boss_instance and boss_instance.has_node("AnimationPlayer"):
		boss_instance.get_node("AnimationPlayer").play("Intro")


# Dipanggil di akhir (misal detik 4.0)
func anim_finish():
	print("Cutscene Selesai. Masuk Mode Boss Fight.")
	
	# 1. Matikan Bar Hitam (UI Sinematik)
	if GlobalUI:
		GlobalUI.toggle_cinematic_bars(false)
	
	# 2. Kembalikan Kendali ke Player
	GameManager.set_cutscene_mode(false)
	
	# 3. ATUR KAMERA (LOGIKA BARU)
	# JANGAN matikan kamera ($Camera2D.enabled = false) <-- HAPUS/COMMENT INI
	
	if arena_center:
		# Pindahkan kamera dari Wajah Boss ke Tengah Ruangan secara halus
		var tween = create_tween()
		
		# Geser Posisi
		tween.tween_property($Camera2D, "global_position", arena_center.global_position, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# (Opsional) Zoom Out sedikit agar arena terlihat luas
		# Angka < 1.0 artinya Zoom Out (Jauh), Angka > 1.0 artinya Zoom In (Dekat)
		var target_zoom = Vector2(2, 2) 
		tween.parallel().tween_property($Camera2D, "zoom", target_zoom, 1.0)
		
	if boss_instance:
		boss_instance.queue_free()
		boss_instance = null
	
	# B. Munculkan Boss Asli (Combat)
	if boss_combat_scene:
		var real_boss = boss_combat_scene.instantiate()
		# Taruh di parent manager (Level) agar tidak ikut terhapus jika manager dihapus
		get_parent().add_child(real_boss)
		
		# Set posisi sama dengan posisi spawn
		real_boss.global_position = $BossSpawnPos.global_position
		
		# C. Aktifkan Boss!
		if real_boss.has_method("activate_fight"):
			real_boss.activate_fight()
	else:
		push_error("LUPA PASANG SCENE BOSS ASLI DI INSPECTOR!")
