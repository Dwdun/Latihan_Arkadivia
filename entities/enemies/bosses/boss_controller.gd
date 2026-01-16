class_name BossController
extends EnemyController # <-- INI KUNCINYA (Mewarisi EnemyController)

@export_group("Boss Settings")
@export var boss_name: String = "The Great Slime"
@export var phase_2_threshold: float = 0.5 # Masuk fase 2 saat darah 50%

signal phase_changed(new_phase: int)

var current_phase: int = 1

func _ready() -> void:
	super._ready() # Jalankan _ready milik EnemyController dulu (Load stats, hp, dll)
	
	# Matikan HP Bar kecil di atas kepala (jika ada)
	var floating_bar = visuals.get_node_or_null("HealthBar")
	if floating_bar:
		floating_bar.visible = false

# Override fungsi damage untuk cek fase & update UI Besar
func _on_damaged(amount: int, source_pos: Vector2, knockback_force: float):
	# 1. Jalankan logika damage biasa (Hitung darah, animasi Hurt, Knockback)
	super._on_damaged(amount, source_pos, knockback_force) 
	
	# 2. Update Boss Bar di Global UI
	if GlobalUI.has_method("update_boss_health"):
		GlobalUI.update_boss_health(health_component.current_health)
	
	# 3. Cek Perubahan Fase
	check_phase_transition()

func check_phase_transition():
	if current_phase == 1:
		var health_percent = float(health_component.current_health) / float(stats.max_health)
		
		if health_percent <= phase_2_threshold:
			enter_phase_2()

func enter_phase_2():
	current_phase = 2
	print("BOSS MASUK FASE 2!")
	emit_signal("phase_changed", 2)
	
	# Contoh: Boss jadi merah dan lebih cepat
	var tween = create_tween()
	tween.tween_property(visuals, "modulate", Color.RED, 1.0)
	
	# Anda bisa ubah parameter di Blackboard agar Behavior Tree mengubah pola serangan
	bt_player.blackboard.set_var("is_enraged", true)
	
	# Efek ledakan/roar
	GameManager.hit_stop(0.0, 0.5) # Freeze sebentar biar dramatis

func activate_boss():
	# Dipanggil saat Player masuk ruangan boss
	if GlobalUI.has_method("show_boss_ui"):
		GlobalUI.show_boss_ui(boss_name, stats.max_health, health_component.current_health)
	
	# Mulai Behavior Tree
	bt_player.active = true

func _on_died():
	# Override kematian biar lebih dramatis (Slow motion)
	if GlobalUI.has_method("hide_boss_ui"):
		GlobalUI.hide_boss_ui()
		
	Engine.time_scale = 0.3 # Slow motion
	await get_tree().create_timer(1.0).timeout # Tunggu 1 detik real-time (3 detik game)
	Engine.time_scale = 1.0
	
	super._on_died() # Panggil kematian biasa (Drop item, hapus node)
