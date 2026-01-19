class_name EntitySpawner
extends Marker2D

@export var entity_scene: PackedScene

var spawned_instance: Node2D = null

func _ready() -> void:
	# 1. Sambungkan sinyal perubahan visibilitas
	visibility_changed.connect(_on_visibility_changed)
	
	# --- PERBAIKAN PENTING ---
	# 2. Cek status manual saat lahir!
	# (Mengatasi bug jika Chunk sudah aktif sejak awal game)
	_on_visibility_changed()

func _on_visibility_changed():
	if is_visible_in_tree():
		spawn()
	else:
		despawn()

func spawn():
	# Cek 1: Pastikan belum ada instance (biar gak double)
	# Cek 2: Pastikan scene musuh sudah dimasukkan di Inspector
	if not spawned_instance and entity_scene:
		spawned_instance = entity_scene.instantiate()
		
		# PENTING: Gunakan call_deferred untuk keamanan saat spawning di tengah proses
		call_deferred("add_child", spawned_instance)

func despawn():
	if spawned_instance:
		spawned_instance.queue_free()
		spawned_instance = null
