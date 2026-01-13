@tool
extends BTAction

func _tick(_delta: float) -> int:
	var enemy = agent as EnemyController
	if not is_instance_valid(enemy): return FAILURE
	
	# Jangan ganggu kalau lagi sibuk
	if enemy.is_attacking or enemy.is_hurt or enemy.is_dead:
		return RUNNING
	
	var target = blackboard.get_var("target", null)
	if not is_instance_valid(target): return FAILURE
		
	var dir = (target.global_position - enemy.global_position).normalized()
	enemy.velocity.x = dir.x * enemy.stats.speed
	
	# Visual Flip
	if enemy.visuals:
		enemy.visuals.scale.x = 1 if dir.x > 0 else -1
	
	# Animasi Walk
	if enemy.animation_player.has_animation("Walk"):
		if enemy.animation_player.current_animation != "Walk":
			enemy.animation_player.play("Walk")
			
	return RUNNING
