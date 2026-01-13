extends Control

@onready var item_grid: GridContainer = $Panel/ScrollContainer/ItemGrid
var slot_scene = preload("res://_core/inventory/inventory_slot.tscn")

func _ready() -> void:
	InventoryManager.inventory_updated.connect(refresh_ui)
	refresh_ui()
	hide() # Sembunyikan saat mulai

func _input(event: InputEvent) -> void:
	if not GlobalUI.visible:
		return
	
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
	# 1. Simpan index slot yang sedang difokuskan (sebelum dihapus)
	var focused_index = -1
	var children = item_grid.get_children()
	for i in range(children.size()):
		if children[i].has_focus():
			focused_index = i
			break
	
	# 2. Hapus slot lama (Kode lama)
	for child in children:
		child.queue_free()
	
	# 3. Buat slot baru (Kode lama)
	for data in InventoryManager.inventory:
		var slot = slot_scene.instantiate()
		item_grid.add_child(slot)
		slot.set_item(data["item"], data["quantity"])
		slot.focus_mode = Control.FOCUS_ALL
	
	# 4. KEMBALIKAN FOKUS
	# Tunggu sebentar agar node baru siap
	await get_tree().process_frame
	
	if item_grid.get_child_count() > 0:
		if focused_index != -1 and focused_index < item_grid.get_child_count():
			# Balik ke posisi semula
			var target_slot = item_grid.get_child(focused_index)
			target_slot.grab_focus()
		else:
			# Kalau slot yang tadi difokuskan hilang (misal item habis),
			# atau baru buka menu, fokus ke yang pertama
			# (Hanya ambil fokus jika menu sedang terlihat/aktif)
			if visible: 
				item_grid.get_child(0).grab_focus()
