extends CanvasLayer

@onready var shop_ui = $HUD/ShopUI
@onready var hp_label: Label = $HUD/HPLabel
@onready var mana_label: Label = $HUD/ManaLabel
@onready var gold_label: Label = $HUD/GoldLabel
@onready var skill_ui = $HUD/SkillUI
@onready var heart_container: HBoxContainer = $HUD/HeartContainer
@onready var hud_control: Control = $HUD

@export var heart_size: Vector2 = Vector2(32, 32)
@export var heart_full_texture: Texture2D
@export var heart_empty_texture: Texture2D


@onready var cinematic_layer = $CinematicLayer
@onready var top_bar = $CinematicLayer/TopBar
@onready var bottom_bar = $CinematicLayer/BottomBar
@onready var boss_title = $CinematicLayer/BossNameLabel

@onready var game_over_ui = $HUD/GameOver

func _ready() -> void:
	# Default: Sembunyi saat game baru dinyalakan (Booting)
	hide_ui()
	# --- DENGAR SINYAL GOLD ---
	InventoryManager.gold_updated.connect(update_gold_ui)

	
	# Update tampilan awal (0 Gold)
	update_gold_ui(InventoryManager.gold)
	if top_bar: top_bar.custom_minimum_size.y = 0
	if bottom_bar: bottom_bar.custom_minimum_size.y = 0
	if boss_title: boss_title.modulate.a = 0

func update_hp_ui(current: int, max_hp: int):
	# 1. Validasi Container
	if not heart_container: return
	
	# 2. Cek apakah jumlah slot hati sesuai Max HP?
	# Jika Max HP berubah (misal dapat item penambah nyawa), kita tata ulang.
	if heart_container.get_child_count() != max_hp:
		_rebuild_hearts(max_hp)
	
	# 3. Update Status Visual (Penuh/Kosong)
	# Loop semua hati yang ada di container
	for i in range(heart_container.get_child_count()):
		var heart_icon = heart_container.get_child(i)
		
		# Logika: Jika index (i) lebih kecil dari darah saat ini, berarti Penuh.
		# Contoh: HP 3. Index 0, 1, 2 = Penuh. Index 3 dst = Kosong.
		if i < current:
			heart_icon.texture = heart_full_texture
		else:
			heart_icon.texture = heart_empty_texture

func _rebuild_hearts(amount: int):
	# Hapus semua anak lama
	for child in heart_container.get_children():
		# --- PERBAIKAN DI SINI ---
		# Lepaskan child dari tree SEGERA agar tidak terhitung lagi oleh get_child_count()
		heart_container.remove_child(child) 
		# Lalu hapus dari memori
		child.queue_free()
	
	# Buat TextureRect baru sebanyak Max HP
	for i in range(amount):
		var icon = TextureRect.new()
		icon.texture = heart_empty_texture 
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE 
		
		icon.custom_minimum_size = heart_size 
		
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_container.add_child(icon)

func toggle_cinematic_bars(active: bool, title: String = ""):
	print("Toggle Cinematic Bars dipanggil! Active = ", active)
	var tween = create_tween()
	
	# --- CEK LOGIKA INI ---
	if active:
		# SALAH JIKA: active=true tapi malah size 0
		# BENAR: active=true -> size 100 (MUNCUL)
		tween.parallel().tween_property(top_bar, "custom_minimum_size:y", 100, 1.0)
		tween.parallel().tween_property(bottom_bar, "custom_minimum_size:y", 100, 1.0)
		
		# Munculkan nama
		boss_title.text = title
		tween.parallel().tween_property(boss_title, "modulate:a", 1.0, 1.0)
		
	else:
		# BENAR: active=false -> size 0 (HILANG)
		tween.parallel().tween_property(top_bar, "custom_minimum_size:y", 0, 1.0)
		tween.parallel().tween_property(bottom_bar, "custom_minimum_size:y", 0, 1.0)
		
		# Hilangkan nama
		tween.parallel().tween_property(boss_title, "modulate:a", 0.0, 0.5)

func show_ui():
	# Nyalakan kembali HUD
	if hud_control:
		hud_control.visible = true
	# Nyalakan kembali akses Sinematik (tapi bar tetap 0 dulu)
	if cinematic_layer:
		cinematic_layer.visible = true

func hide_ui():
	# 1. Sembunyikan HUD (Darah, Mana, Gold)
	if hud_control:
		hud_control.visible = false
	
	# 2. Sembunyikan Layer Sinematik (PENTING: Agar tidak BLANK hitam)
	if cinematic_layer:
		cinematic_layer.visible = false
	
	# 3. Pastikan Shop & Inventory tertutup
	if shop_ui: shop_ui.visible = false
	var inv_ui = hud_control.get_node_or_null("InventoryUI")
	if inv_ui: inv_ui.visible = false


func update_gold_ui(amount: int):
	if gold_label:
		# Format: "Gold: 150" atau pakai icon
		gold_label.text = "Gold: " + str(amount)

func update_mana_ui(current: int, max_mana: int):
	if mana_label:
		mana_label.text = "MP: %d / %d" % [current, max_mana]

func open_shop_ui(npc_ref):
	shop_ui.open_shop(npc_ref)

func register_player(player: PlayerController):
	# 1. Ambil Skill Utama (Biasanya index 1, karena index 0 itu Dash)
	# Pastikan player punya skill di slot itu
	if player.equipped_skills.size() > 1:
		var main_skill = player.equipped_skills[1]
		if main_skill and skill_ui:
			skill_ui.setup_skill(main_skill)
	
	# 2. Dengar sinyal saat player pakai skill
	if not player.skill_used.is_connected(_on_player_skill_used):
		player.skill_used.connect(_on_player_skill_used)

func _on_player_skill_used(index: int, cooldown: float):
	# Hanya respon jika yang dipakai adalah Skill 1 (Skill Serangan)
	if index == 1 and skill_ui:
		skill_ui.play_cooldown_animation(cooldown)

func show_game_over():
	if game_over_ui:
		game_over_ui.lose()
		if hud_control:
			pass
