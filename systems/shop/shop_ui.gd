extends Control

# Template tombol toko (Bisa dibuat scene terpisah atau generate via code)
# Kita anggap Anda punya scene tombol sederhana: "ShopSlot.tscn"
var slot_scene = preload("res://systems/shop/shop_slot.tscn") 

@onready var title_lbl: Label = $Panel/Label
@onready var grid: GridContainer = $Panel/ScrollContainer/GridContainer
@onready var close_button: Button = $Panel/CloseButton

var current_npc = null

func _ready():
	hide() # Default sembunyi
	if close_button:
		close_button.pressed.connect(close_shop)

func open_shop(npc_ref):
	current_npc = npc_ref
	
	if npc_ref.shop_data:
		var data = npc_ref.shop_data 
		title_lbl.text = data.shop_name
		
		refresh_grid()
		
		show()
		get_tree().paused = true 
		
		await get_tree().process_frame
		if grid.get_child_count() > 0:
			grid.get_child(0).grab_focus()
	else:
		print("Error: NPC ini tidak punya ShopData!")
	
	var data = npc_ref.shop_data
	
	title_lbl.text = data.shop_name
	refresh_grid()
	
	# Bersihkan slot lama
	for child in grid.get_children():
		child.queue_free()
	
	# Buat tombol baru sesuai listing
	for listing in data.listings:
		var stock = npc_ref.get_stock(listing)
		if stock != 0:
				var slot = slot_scene.instantiate()
				grid.add_child(slot)
				slot.setup(listing, stock, self)
		
	show()
	get_tree().paused = true # Pause game saat belanja
	
	# Fokus ke tombol pertama (untuk Controller/Keyboard)
	await get_tree().process_frame
	if grid.get_child_count() > 0:
		grid.get_child(0).grab_focus()

func close_shop():
	hide()
	get_tree().paused = false

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"): # Tombol ESC/B
		close_shop()

func refresh_grid():
	# Bersihkan slot lama
	for child in grid.get_children():
		child.queue_free()
	
	# Buat tombol baru
	if current_npc and current_npc.shop_data:
		for listing in current_npc.shop_data.listings:
			# Cek Stok dulu di NPC
			var stock = current_npc.get_stock(listing)
			
			# Hanya tampilkan jika stok masih ada atau unlimited (-1)
			# (Atau tetap tampilkan tapi disable, terserah desain Anda)
			if stock != 0: 
				var slot = slot_scene.instantiate()
				grid.add_child(slot)
				# Kita pass juga referensi UI ini ke slot biar bisa callback
				slot.setup(listing, stock, self)

func on_buy_attempt(listing):
	# 1. Coba Beli secara Ekonomi (Inventory Manager)
	if InventoryManager.try_buy_item(listing):
		
		# 2. Jika Berhasil, Kurangi Stok di NPC
		if current_npc:
			current_npc.reduce_stock(listing)
		
		# 3. Render ulang UI (agar angka stok berkurang/hilang)
		refresh_grid()
		
		# Cek apakah NPC sudah tutup? (Semua habis)
		if current_npc and not current_npc.is_shop_active:
			close_shop()
