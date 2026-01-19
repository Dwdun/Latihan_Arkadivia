class_name PlayerState
extends LimboState

# Helper variable agar autocomplete mengenali 'agent' sebagai PlayerController
var player: PlayerController

func _enter() -> void:
	# Mengambil referensi agent sebagai PlayerController
	player = agent as PlayerController
