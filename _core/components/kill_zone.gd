class_name KillZone
extends Area2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	if area is HurtboxComponent:
		var health_comp = area.health_component
		if area.owner.is_in_group("player"):
			if health_comp:
				if health_comp.current_health <= 1:
					if area.has_method("take_damage"):
						area.take_damage(999999, global_position, 0.0)
				else:
					area.take_damage(1, global_position, 0.0)
					GameManager.rescue_player_from_fall(area.owner)
