extends Control

@onready var item_grid: GridContainer = $Panel/ScrollContainer/ItemGrid
var slot_scene = preload("res://_core/inventory/inventory_slot.tscn")

func _ready() -> void:
	InventoryManager.inventory_updated.connect(refresh_ui)
	refresh_ui()
	hide() # Sembunyikan saat mulai

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		toggle_inventory()

func toggle_inventory():
	visible = !visible
	
	if visible:
		# 1. PAUSE GAME
		get_tree().paused = true
		
		# 2. Render Ulang
		refresh_ui()
		
		# 3. AMBIL FOKUS (Kunci agar WASD jalan)
		# Kita tunggu 1 frame agar UI selesai digambar dulu
		await get_tree().process_frame
		
		if item_grid.get_child_count() > 0:
			var first_slot = item_grid.get_child(0)
			if first_slot is Button:
				first_slot.grab_focus() # <-- Ini kuncinya!
	else:
		# UNPAUSE GAME
		get_tree().paused = false

func refresh_ui():
	# Hapus anak lama
	for child in item_grid.get_children():
		child.queue_free()
	
	# Buat anak baru
	for data in InventoryManager.inventory:
		var slot = slot_scene.instantiate()
		item_grid.add_child(slot)
		slot.set_item(data["item"], data["quantity"])
		
		# Setup Navigasi Antar Slot (Otomatis oleh GridContainer, tapi pastikan ini)
		slot.focus_mode = Control.FOCUS_ALL
