class_name VisionComponent
extends Node2D

@export_group("Settings")
@export var vision_range: float = 300.0
@export_flags_2d_physics var vision_mask: int = 1 

var player: Node2D = null

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
func _process(_delta):
	queue_redraw()

func _draw():
	if Engine.is_editor_hint() or OS.is_debug_build():
		if is_instance_valid(player):
			var color = Color.RED
			if can_see_player():
				color = Color.GREEN
			
			# Gambar lingkaran range
			draw_circle(Vector2.ZERO, 5.0, color) 
			# Gambar garis ke player
			draw_line(Vector2.ZERO, to_local(player.global_position), color, 1.0)
			
func can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
		
	# 1. CEK JARAK
	var dist_sq = global_position.distance_squared_to(player.global_position)
	if dist_sq > vision_range * vision_range:
		return false # Player kejauhan, stop proses.
		
	# 2. CEK LINE OF SIGHT / RAYCAST
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(
		global_position,           # Dari Mata Musuh
		player.global_position,    # Ke Posisi Player
		vision_mask                # Apa yang bisa menghalangi? (Tembok)
	)
	
	query.exclude = [get_parent().get_rid()] 
	
	var result = space_state.intersect_ray(query)
	
	# Jika Raycast mengenai sesuatu (result tidak kosong)
	if result:
		return false
	return true
