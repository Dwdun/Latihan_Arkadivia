extends Parallax2D

@export var speed: float = 10.0 # Kecepatan gerak pixel per detik

func _process(delta: float) -> void:
	# Menggeser offset background setiap frame
	scroll_offset.x -= speed * delta
