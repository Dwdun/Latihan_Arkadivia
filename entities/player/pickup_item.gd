extends CharacterBody2D

var item_data: ItemData
var amount: int = 1

var is_grounded: bool = false
var is_collected: bool = false
var player_target: CharacterBody2D = null

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var bounce_force: float = -300.0 # Kekuatan mental ke atas saat spawn

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea

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
	# 1. SETUP AWAL: Lontarkan ke atas acak
	velocity.y = bounce_force
	velocity.x = randf_range(-100, 100) # Mental sedikit ke kiri/kanans
	
	detection_area.body_entered.connect(_on_magnet_range_entered)
	# Sambungkan sinyal jika player mendekat
func _on_body_entered(body):
	if body.is_in_group("player") and not is_collected:
		player_target = body
		is_collected = true
		
		# Matikan deteksi agar tidak memicu 2x
		set_deferred("monitoring", false)

func _process(delta: float) -> void:
	# EFEK MAGNET (Tarik ke Player)
	if is_collected and player_target:
		# Matikan collision agar tembus tembok saat ditarik
		collision_mask = 0 
		
		var dir = (player_target.global_position - global_position).normalized()
		var dist = global_position.distance_to(player_target.global_position)
		
		# Akselerasi makin dekat makin cepat
		var speed = 800.0 if dist > 50 else 1500.0
		velocity = dir * speed
		
		move_and_slide()
		
		# Logic ambil item
		if dist < 20:
			_collect_item()
		return # Stop logika di bawah

	# --- FASE 2: JATUH (GRAVITASI) ---
	if not is_on_floor():
		velocity.y += gravity * delta
		# Gesekan udara horizontal (biar gak meluncur terus kaya es)
		velocity.x = move_toward(velocity.x, 0, 200 * delta) 
		
		move_and_slide()
	
	# --- FASE 3: MENDARAT & FLOATING ---
	else:
		if not is_grounded:
			is_grounded = true
			velocity = Vector2.ZERO # Stop gerak
			_start_floating_anim()

func _start_floating_anim():
	# Kita animasikan SPRITE-nya saja, bukan badannya (badannya tetap di lantai)
	var tween = create_tween().set_loops()
	# Naik 5 pixel, lalu turun
	tween.tween_property(sprite, "position:y", -5.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_magnet_range_entered(body):
	if body.is_in_group("player") and not is_collected:
		player_target = body
		is_collected = true
		# Matikan tween floating agar tidak konflik
		sprite.position.y = 0 
		detection_area.set_deferred("monitoring", false)

func _collect_item():
	if InventoryManager.add_item(item_data, amount):
		# Efek partikel/suara bisa ditaruh disini
		queue_free()
