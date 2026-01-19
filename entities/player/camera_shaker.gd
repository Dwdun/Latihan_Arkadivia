extends Camera2D

# Kekuatan guncangan saat ini
var shake_strength: float = 0.0
# Seberapa cepat guncangan menghilang
var shake_fade: float = 5.0

func apply_shake(strength: float):
	# Timpa kekuatan shake yang ada (ambil yang terbesar agar tidak aneh)
	shake_strength = max(shake_strength, strength)

func _process(delta: float):
	if shake_strength > 0:
		# Kurangi kekuatan shake seiring waktu (Lerp menuju 0)
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		
		# Geser kamera secara acak (Offset)
		offset = random_offset()

func random_offset() -> Vector2:
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)
