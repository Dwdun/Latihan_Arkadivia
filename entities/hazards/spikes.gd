class_name HazardSpike
extends Node2D

@onready var hitbox: HitboxComponent = $Hitbox

# Timer internal untuk reset hitbox
var reset_timer: float = 0.0
var reset_interval: float = 0.5 # Hitbox aktif ulang setiap 0.5 detik

func _process(delta: float) -> void:
	# Hitung mundur
	if reset_timer > 0:
		reset_timer -= delta
	else:
		# Waktunya reset!
		if hitbox:
			hitbox.reset_hitbox() # Lupakan siapa yang sudah dipukul
		
		# Ulangi timer
		reset_timer = reset_interval
