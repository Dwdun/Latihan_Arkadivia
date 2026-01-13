extends Node

# Signal agar UI tahu kalau ada isi tas yang berubah
signal inventory_updated

signal gold_updated(new_amount: int)
# Struktur Array:
# [ 
#    {"item": Resource(Potion), "quantity": 10},
#    {"item": Resource(Key), "quantity": 1}
# ]
var inventory: Array[Dictionary] = []
var gold: int = 0 # Dompet pemain

# --- FUNGSI NAMBAH ITEM ---
func add_item(item: ItemData, amount: int = 1) -> bool:
	# 1. Cek apakah item sudah ada di tas? (Untuk di-stack)
	for slot in inventory:
		if slot["item"] == item:
			# Cek apakah sudah mentok 99?
			if slot["quantity"] >= item.max_stack:
				print("Inventory: Item mentok 99!")
				return false # Gagal nambah
			
			# Hitung penambahan
			var new_quantity = slot["quantity"] + amount
			
			if new_quantity > item.max_stack:
				# Opsional: Jika mau hard cap (kalau 98 + 2 = tetep 99, sisa 1 hilang)
				slot["quantity"] = item.max_stack
				print("Inventory: Stack penuh, sisa terbuang.")
			else:
				slot["quantity"] = new_quantity
			
			inventory_updated.emit() # Kabari UI
			return true

	# 2. Jika item belum ada, buat slot baru (Flexible Slot)
	var new_slot = {
		"item": item,
		"quantity": min(amount, item.max_stack) # Safety cap
	}
	inventory.append(new_slot)
	
	inventory_updated.emit() # Kabari UI
	return true

# --- FUNGSI CEK ITEM (Untuk Quest/Shop) ---
func has_item(item: ItemData, amount_needed: int = 1) -> bool:
	for slot in inventory:
		if slot["item"] == item:
			return slot["quantity"] >= amount_needed
	return false

# --- FUNGSI AMBIL/PAKAI ITEM ---
func remove_item(item: ItemData, amount: int = 1):
	for i in range(inventory.size()):
		if inventory[i]["item"] == item:
			inventory[i]["quantity"] -= amount
			
			# Jika habis, hapus slot dari array (Flexible Slot berkurang)
			if inventory[i]["quantity"] <= 0:
				inventory.remove_at(i)
			
			inventory_updated.emit()
			return

func add_gold(amount: int):
	gold += amount
	print("Gold bertambah: ", amount, " Total: ", gold)
	gold_updated.emit(gold)

func has_gold(amount: int) -> bool:
	return gold >= amount

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_updated.emit(gold)
		return true
	return false

func use_item(item: ItemData):
	# 1. Validasi: Hanya item CONSUMABLE yang bisa dipakai
	if item.type != ItemData.Type.CONSUMABLE:
		print("Item ini tidak bisa dikonsumsi!")
		return

	# 2. Cari Player (Target Efek)
	# Kita cari node pertama dalam grup "player"
	var player = get_tree().get_first_node_in_group("player")
	
	if not player:
		print("Error: Player tidak ditemukan!")
		return

	# 3. Terapkan Efek (Heal)
	# Pastikan player punya health_component sesuai script Anda
	if player.health_component and player.health_component.has_method("heal"):
		player.health_component.heal(item.effect_amount)
		print("Menggunakan " + item.name + ", Heal: " + str(item.effect_amount))
		
		# 4. Buang Bungkusnya (Kurangi stok 1 biji)
		remove_item(item, 1)
		
		# (Opsional) Play Sound Effect lewat GameManager/AudioManager
		# GameManager.play_sfx("drink_potion")
