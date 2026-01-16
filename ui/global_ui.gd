extends CanvasLayer

@onready var shop_ui = $HUD/ShopUI
@onready var hp_label: Label = $HUD/HPLabel
@onready var mana_label: Label = $HUD/ManaLabel
@onready var gold_label: Label = $HUD/GoldLabel
@onready var hud_control: Control = $HUD

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
	if hp_label:
		# Format teks: "HP: 50 / 100"
		hp_label.text = "HP: %s / %s" % [str(current), str(max_hp)]

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
