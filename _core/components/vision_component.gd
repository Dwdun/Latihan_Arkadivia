class_name VisionComponent
extends Node2D

@export_group("Settings")
@export var vision_range: float = 300.0
# Pastikan mask ini HANYA mencentang Layer Tembok/World (Layer 1), 
# JANGAN centang Layer Player, atau raycast akan menabrak player dan mengira itu tembok.
@export_flags_2d_physics var vision_mask: int = 1 

var player: Node2D = null

func _ready() -> void:
	# Coba cari sekali saat lahir (untuk Test World)
	_find_player()

func _process(_delta):
	# --- PERBAIKAN DI SINI ---
	# Jika variable player kosong (atau player mati/queue_free), cari lagi!
	if not is_instance_valid(player):
		_find_player()
	
	queue_redraw()

# Fungsi khusus pencari player
func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		# (Opsional) Print agar kita tahu kapan slime 'sadar'
		# print("VisionComponent: Player ditemukan!")

func _draw():
	if Engine.is_editor_hint() or OS.is_debug_build():
		if is_instance_valid(player):
			var color = Color.RED
			if can_see_player():
				color = Color.GREEN
			
			draw_circle(Vector2.ZERO, 5.0, color) 
			draw_line(Vector2.ZERO, to_local(player.global_position), color, 1.0)
			
func can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
		
	# 1. CEK JARAK
	var dist_sq = global_position.distance_squared_to(player.global_position)
	if dist_sq > vision_range * vision_range:
		return false 
		
	# 2. CEK LINE OF SIGHT
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(
		global_position, 
		player.global_position, 
		vision_mask
	)
	
	# Agar raycast tidak menabrak tubuh musuh itu sendiri
	# (Terutama jika musuh ada di layer yang sama dengan vision_mask)
	query.exclude = [get_parent().get_rid()] 
	
	var result = space_state.intersect_ray(query)
	
	# Jika Raycast kena sesuatu (Tembok), berarti pandangan terhalang
	if result:
		return false
		
	return true
