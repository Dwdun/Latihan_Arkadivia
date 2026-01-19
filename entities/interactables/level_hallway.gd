class_name LevelHallway
extends Area2D

# --- IDENTITAS LORONG ---
@export_group("Identity")
@export var my_id: String = "hallway_a" # ID Lorong ini

# --- TUJUAN ---
@export_group("Destination")
@export_file("*.tscn") var target_level_path: String # File Level Tujuan
@export var target_hallway_id: String = "hallway_b" # ID Lorong di seberang sana

# --- INTERNAL ---
@onready var spawn_point: Marker2D = $SpawnPoint

func _ready() -> void:
	# Hubungkan sinyal tabrakan
	body_entered.connect(_on_body_entered)
	
	# Tambahkan ke grup "doors" agar SceneManager bisa menemukannya
	# Walaupun namanya Hallway, fungsinya sama seperti pintu bagi SceneManager
	add_to_group("doors")

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		# Cek apakah level tujuan valid?
		if target_level_path == "" or target_level_path == null:
			push_warning("Hallway: Level tujuan kosong!")
			return
			
		# PANGGIL SCENE MANAGER (Tanpa cek tombol input)
		# Ini yang membedakan Hallway dengan Door
		SceneManager.change_scene(target_level_path, target_hallway_id)

# --- API UNTUK SCENE MANAGER ---
# SceneManager butuh dua fungsi ini untuk meletakkan player
func get_id() -> String:
	return my_id

func get_spawn_position() -> Vector2:
	return spawn_point.global_position
