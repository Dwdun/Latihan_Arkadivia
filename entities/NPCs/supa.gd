extends Area2D

@export var shop_data: ShopData 

var current_stock: Dictionary = {}
var player_in_range = false
var is_shop_active = true 
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$Label.hide()
	animation_player.play("Idle")
	# Inisialisasi Stok
	if shop_data:
		for listing in shop_data.listings:
			current_stock[listing] = listing.initial_stock
	
	# Cek awal (siapa tahu dari awal emang kosong)
	_check_if_shop_empty()

func _on_body_entered(body):
	# Hanya munculkan label jika player datang DAN toko masih aktif
	if body.is_in_group("player") and is_shop_active:
		player_in_range = true
		$Label.show()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		$Label.hide()

func _input(event):
	# PENTING: Tambahkan 'is_shop_active' di sini
	if player_in_range and is_shop_active and event.is_action_pressed("interact"):
		if GlobalUI.has_method("open_shop_ui"):
			GlobalUI.open_shop_ui(self) 

func get_stock(listing: ShopListing) -> int:
	return current_stock.get(listing, 0)

func reduce_stock(listing: ShopListing):
	if current_stock.has(listing):
		var s = current_stock[listing]
		
		# Jika bukan unlimited (-1), kurangi
		if s > 0:
			current_stock[listing] -= 1
			
		# --- CEK SETIAP KALI STOK BERUBAH ---
		_check_if_shop_empty()

func _check_if_shop_empty():
	var any_stock_left = false
	
	for listing in current_stock:
		var s = current_stock[listing]
		# Jika ada satu saja item Unlimited (-1) atau > 0
		if s == -1 or s > 0:
			any_stock_left = true
			break
	
	# Jika tidak ada stok tersisa sama sekali
	if not any_stock_left:
		animation_player.play(("After"))
		is_shop_active = false
		player_in_range = false 
		$Label.hide() # Sembunyikan tulisan "Press F"
		print("Toko Tutup! Barang habis.")
