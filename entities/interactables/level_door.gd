class_name LevelDoor
extends Area2D

# --- SETTING PINTU ---
@export_group("Door Identity")
@export var my_id: String = "door_a" # ID pintu INI (misal: "gerbang_desa")

@export_group("Destination")
@export_file("*.tscn") var target_level_path: String # Level tujuan
@export var target_door_id: String = "door_a" # ID pintu TUJUAN di level sana

# --- INTERNAL ---
var player_in_range: bool = false
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var label: Label = $Label # Jika ada label instruksi

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if label: label.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"): # Pastikan input map "interact" ada (misal tombol W/E)
		_enter_door()

func _enter_door():
	if target_level_path == "":
		push_error("Door: Level tujuan belum diisi!")
		return
	
	# Panggil Global Manager
	SceneManager.change_scene(target_level_path, target_door_id)

# --- FUNGSI API (Dipanggil SceneManager) ---
func get_id() -> String:
	return my_id

func get_spawn_position() -> Vector2:
	return spawn_point.global_position

# --- DETEKSI PLAYER ---
func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = true
		if label: label.visible = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_range = false
		if label: label.visible = false
