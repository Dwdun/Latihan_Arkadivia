class_name HurtboxComponent
extends Area2D

@export var health_component: HealthComponent 
signal received_damage(amount: int, source_pos: Vector2)

func take_damage(amount: int, source_pos: Vector2, knockback_force: float = 0.0) -> bool:
	received_damage.emit(amount, source_pos)
	
	if health_component:
		return health_component.damage(amount, source_pos, knockback_force)
	else:
		return true
