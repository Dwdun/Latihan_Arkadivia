class_name TreasureChest
extends Node2D

# REUSE SISTEM: Kita pakai ShopData sebagai wadah item loot
@export var loot_data: ShopData 

@export_group("Settings")
@export var is_locked: bool = false
@export var key_item_required: ItemData # Kunci yang dibutuhkan (Opsional)
@export var one_time_id: String = "" # ID unik jika ingin peti disimpan (Save System)

@onready var sprite = $Sprite2D
@onready var label = $Label
@onready var anim_player = $AnimationPlayer
@onready var spawn_point = $SpawnPoint

# Ambil scene pickup item yang sama dengan yang dipakai musuh
var pickup_scene = preload("res://entities/player/pickup_item.tscn")

var is_opened: bool = false
var player_in_range = null

func _ready() -> void:
	# Setup area interaksi
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)
	
	if label: label.visible = false
	
	# (Opsional) Cek Save Data disini apakah peti sudah pernah dibuka
	# if SaveSystem.is_chest_opened(one_time_id):
	#    is_opened = true
	#    sprite.frame = 1 (Gambar terbuka)

func _input(event: InputEvent) -> void:
	# Cek input interaksi (misal tombol "F" atau "Interact")
	if not is_opened and player_in_range and event.is_action_pressed("interact"):
		attempt_open()

func attempt_open():
	# 1. Cek Kunci (Jika terkunci)
	if is_locked and key_item_required:
		if InventoryManager.has_item(key_item_required):
			InventoryManager.remove_item(key_item_required, 1)
			print("Menggunakan kunci untuk membuka peti.")
			_open_chest()
		else:
			print("Terkunci! Butuh: " + key_item_required.name)
			_shake_chest() # Visual feedback: Peti goyang karena dikunci
			return
	
	# 2. Buka Normal
	_open_chest()

func _open_chest():
	is_opened = true
	if label: label.visible = false

	if anim_player.has_animation("Open"):
		anim_player.play("Open")
	#else:
		#sprite.frame = 1 # Ganti frame manual jika tidak ada animasi
	
	# EFEK JUICE: Squash peti saat dibuka
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1) # Gepeng
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE)

	# SPAWN LOOT
	if loot_data:
		drop_loot()
	else:
		print("Peti kosong (Lupa pasang Resource ShopData?)")

func drop_loot():
	# REUSE LOGIKA: Loop isi ShopData 
	for listing in loot_data.listings:
		# Abaikan harga (price_gold), ambil barangnya saja 
		var item = listing.item_to_sell
		var qty = listing.quantity_sell
		
		# Spawn item fisik ke dunia
		spawn_pickup(item, qty)
		
		# Beri sedikit delay antar item biar muncratnya bagus
		await get_tree().create_timer(0.1).timeout

func spawn_pickup(item: ItemData, qty: int):
	if not pickup_scene: return
	
	var pickup = pickup_scene.instantiate()
	pickup.global_position = spawn_point.global_position
	
	# Setup data item
	if pickup.has_method("setup"):
		pickup.setup(item, qty)
	
	get_parent().call_deferred("add_child", pickup)
	
	# JUICE: Lontarkan item ke atas/acak
	if pickup is CharacterBody2D or pickup is RigidBody2D:
		var random_dir = Vector2(randf_range(-1, 1), -1).normalized()
		var force = randf_range(300, 500)
		
		# Jika pickup pakai CharacterBody2D (seperti di game umum)
		if "velocity" in pickup:
			pickup.velocity = random_dir * force

# --- VISUAL FEEDBACK (Gagal Buka) ---
func _shake_chest():
	var tween = create_tween()
	tween.tween_property(sprite, "position:x", 5, 0.05)
	tween.tween_property(sprite, "position:x", -5, 0.05)
	tween.tween_property(sprite, "position:x", 0, 0.05)

# --- SINYAL AREA ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body
		if not is_opened and label:
			label.visible = true
			if is_locked and key_item_required:
				label.text = "Locked (Need %s)" % key_item_required.name
			else:
				label.text = "Open"

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = null
		if label: label.visible = false
