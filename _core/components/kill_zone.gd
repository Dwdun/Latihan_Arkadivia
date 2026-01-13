class_name KillZone
extends Area2D

@export var damage_amount: int = 999999

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	if area is HurtboxComponent:
		if area.has_method("take_damage"):
			area.take_damage(damage_amount, global_position, 0.0)
