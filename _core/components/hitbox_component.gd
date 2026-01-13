class_name HitboxComponent
extends Area2D

@export var damage: int = 10 
@export var knockback_force: float = 300.0

# --- JUICE SETTINGS ---
@export_group("Juice")
@export var hit_stop_duration: float = 0.15 
@export var screen_shake_amount: float = 2.0 

var hit_list: Array[Area2D] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	if area is HurtboxComponent:
		if area not in hit_list:
			var attack_success = false
			
			if area.has_method("take_damage"):
				attack_success = area.take_damage(damage, global_position, knockback_force)
			
			hit_list.append(area)
			
			if attack_success:
				_apply_hit_feel()

func _apply_hit_feel():
	if GameManager:
		GameManager.hit_stop(0.05, hit_stop_duration)
	
	var viewport = get_viewport()
	if viewport:
		var camera = viewport.get_camera_2d()
		if camera and camera.has_method("apply_shake"):
			camera.apply_shake(screen_shake_amount)
		
	var parent = get_parent()
	if parent:
		var owner_node = parent.get_parent()
		if owner_node and owner_node.has_method("apply_recoil"):
			if parent.get("scale"): 
				var recoil_dir = Vector2(-parent.scale.x, 0)
				owner_node.apply_recoil(recoil_dir)

func reset_hitbox():
	hit_list.clear()
