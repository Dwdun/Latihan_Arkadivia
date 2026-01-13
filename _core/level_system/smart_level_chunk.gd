@tool
class_name SmartLevelChunk
extends Node2D

# --- PENGATURAN UTAMA ---
@export_group("Chunk Settings")
@export var size: Vector2 = Vector2(1152, 648)
@export var activation_margin: float = 200.0
@export var start_active: bool = false

# --- PENGATURAN FISIKA (FIX DISINI) ---
@export_group("Detection")
# Bitmask: Centang Layer dimana Player berada (Biasanya Layer 2)
@export_flags_2d_physics var detection_mask: int = 2 
@export var debug_mode: bool = false # Centang ini kalau mau lihat log di Output

# --- INTERNAL ---
var _detection_area: Area2D
var _collision_shape: CollisionShape2D

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	
	_setup_system()
	
	# Inisialisasi awal
	if start_active:
		_set_active(true)
	else:
		_set_active(false)

func _setup_system():
	# 1. Buat Area Sensor
	_detection_area = Area2D.new()
	_detection_area.name = "ChunkSensor"
	
	# PENTING: Set Collision Mask sesuai settingan Inspector
	# Ini agar sensor bisa melihat Player di Layer 2
	_detection_area.collision_layer = 0 # Sensor tidak perlu ditabrak
	_detection_area.collision_mask = detection_mask 
	
	_detection_area.monitorable = false # Optimasi: Tidak perlu dideteksi area lain
	_detection_area.monitoring = true   # Wajib nyala untuk mendeteksi body
	
	add_child(_detection_area)
	
	# 2. Buat Bentuk Sensor
	_collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = size + Vector2(activation_margin, activation_margin) * 2
	_collision_shape.shape = rect_shape
	_detection_area.add_child(_collision_shape)
	
	# 3. Posisikan di tengah
	_collision_shape.position = size / 2
	
	# 4. Sambungkan Sinyal
	_detection_area.body_entered.connect(_on_body_entered)
	_detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	# Debugging: Lihat siapa yang masuk?
	if debug_mode:
		print("[Chunk ", name, "] Mendeteksi: ", body.name)

	if body.is_in_group("player"):
		if debug_mode: print(" -> PLAYER DETECTED! Loading Chunk...")
		call_deferred("_set_active", true)

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		if debug_mode: print(" -> PLAYER LEFT! Unloading Chunk...")
		call_deferred("_set_active", false)

func _set_active(is_active: bool):
	var mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED
	
	for child in get_children():
		# Sensor JANGAN dimatikan!
		if child == _detection_area:
			continue
			
		child.process_mode = mode
		if child is CanvasItem:
			child.visible = is_active

# --- VISUAL EDITOR ---
func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()

func _draw():
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color.GREEN, false, 2.0)
		var margin_rect = Rect2(Vector2.ZERO, size).grow(activation_margin)
		draw_rect(margin_rect, Color(1, 1, 0, 0.5), false, 1.0)
		# Tampilkan nama layer yang dideteksi (Visual aid)
		draw_string(ThemeDB.fallback_font, Vector2(10, 50), "Mask: " + str(detection_mask), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
