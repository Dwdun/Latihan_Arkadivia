extends StaticBody2D

func close_gate():
	# Mainkan animasi menutup
	if $AnimationPlayer.has_animation("Close"):
		$AnimationPlayer.play("Close")
	else:
		# Fallback jika lupa bikin animasi: Langsung muncul
		show()
		$CollisionShape2D.set_deferred("disabled", false)
