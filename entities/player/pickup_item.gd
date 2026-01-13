extends Area2D

var item_data: ItemData
var amount: int = 1
var is_collected: bool = false
var player_target: CharacterBody2D = null

func setup(data: ItemData, qty: int):
	item_data = data
	amount = qty
	
	if item_data.icon:
		$Sprite2D.texture = item_data.icon
		
		# --- TAMBAHAN: PAKSA UKURAN KECIL ---
		# Misal kita ingin lebar maksimal selalu 32 pixel
		var target_size = 32.0 
		var texture_width = item_data.icon.get_width()
		
		# Hitung skala pengecilan
		if texture_width > target_size:
			var scale_factor = target_size / texture_width
			$Sprite2D.scale = Vector2(scale_factor, scale_factor)
		else:
			# Reset ke 1 jika gambar sudah kecil (biar gak pecah dibesarkan)
			$Sprite2D.scale = Vector2(1, 1)

func _ready() -> void:
	# Efek muncul (Lontar ke atas sedikit)
	var tween = create_tween()
	var random_x = randf_range(-50, 50)
	tween.tween_property(self, "position", position + Vector2(random_x, -50), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", position + Vector2(random_x, 0), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Sambungkan sinyal jika player mendekat
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_collected:
		player_target = body
		is_collected = true
		
		# Matikan deteksi agar tidak memicu 2x
		set_deferred("monitoring", false)

func _process(delta: float) -> void:
	# EFEK MAGNET (Tarik ke Player)
	if is_collected and player_target:
		var dir = (player_target.global_position - global_position).normalized()
		var dist = global_position.distance_to(player_target.global_position)
		
		# Semakin dekat semakin cepat
		var speed = 800.0 if dist > 50 else 1500.0
		position += dir * speed * delta
		
		# Jika sudah sangat dekat -> Masuk Inventory
		if dist < 20:
			_collect_item()

func _collect_item():
	# Masukkan ke Global Inventory
	if InventoryManager.add_item(item_data, amount):
		# Efek Suara (Opsional)
		# AudioManager.play_sfx("pickup")
		
		# Efek Visual (Floating Text atau Partikel) - Opsional
		print("Dapat Item: " + item_data.name)
		
		queue_free() # Hapus dari dunia
