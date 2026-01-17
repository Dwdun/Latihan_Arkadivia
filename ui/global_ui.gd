extends CanvasLayer

@onready var shop_ui = $HUD/ShopUI
@onready var hp_label: Label = $HUD/HPLabel
@onready var mana_label: Label = $HUD/ManaLabel
@onready var gold_label: Label = $HUD/GoldLabel
@onready var heart_container: HBoxContainer = $HUD/HeartContainer
@onready var hud_control: Control = $HUD

@export var heart_size: Vector2 = Vector2(32, 32)
@export var heart_full_texture: Texture2D
@export var heart_empty_texture: Texture2D


@onready var cinematic_layer = $CinematicLayer
@onready var top_bar = $CinematicLayer/TopBar
@onready var bottom_bar = $CinematicLayer/BottomBar
@onready var boss_title = $CinematicLayer/BossNameLabel

func _ready() -> void:
	# Default: Sembunyi saat game baru dinyalakan (Booting)
	hide_ui()
	# --- DENGAR SINYAL GOLD ---
	InventoryManager.gold_updated.connect(update_gold_ui)
	
	if hud_control: hud_control.visible = true
	
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

# Fungsi Helper untuk membangun ulang wadah hati
func _rebuild_hearts(amount: int):
	# Hapus semua anak lama
	for child in heart_container.get_children():
		child.queue_free()
	
	# Buat TextureRect baru sebanyak Max HP
	for i in range(amount):
		var icon = TextureRect.new()
		# Set texture default (kosong dulu gpp, nanti di-update)
		icon.texture = heart_empty_texture 
		# Mode stretch agar ukuran konsisten (Opsional, keep aspect centered bagus)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE 
		
		# 2. Paksa ukuran sesuai keinginan kita (variable export)
		icon.custom_minimum_size = heart_size 
		
		# 3. Jaga aspek rasio agar hati tidak gepeng
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
	if hud_control:
		hud_control.visible = true

func hide_ui():
	if hud_control:
		hud_control.visible = false


func update_gold_ui(amount: int):
	if gold_label:
		# Format: "Gold: 150" atau pakai icon
		gold_label.text = "Gold: " + str(amount)

func update_mana_ui(current: int, max_mana: int):
	if mana_label:
		mana_label.text = "MP: %d / %d" % [current, max_mana]

func open_shop_ui(npc_ref):
	shop_ui.open_shop(npc_ref)
