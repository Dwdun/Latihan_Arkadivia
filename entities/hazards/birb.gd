extends Node2D

@export var speed: float = 100.0
@export var wait_time: float = 0.5
@onready var hitbox: HitboxComponent = $HitboxComponent

# Ambil referensi Marker
@onready var a = $A
@onready var b = $B

var position_a: Vector2
var position_b: Vector2
var target_position: Vector2

var is_waiting: bool = false

func _ready():
	position_a = a.global_position
	position_b = b.global_position
	
	a.queue_free()
	b.queue_free()
	
	target_position = position_b

func _physics_process(delta):
	$AnimationPlayer.play("Idle")
	if is_waiting:
		return
	if hitbox:
			hitbox.reset_hitbox()

	global_position = global_position.move_toward(target_position, speed * delta)
	if global_position.distance_to(target_position) < 1.0:
		_switch_target()

func _switch_target():
	is_waiting = true
	await get_tree().create_timer(wait_time).timeout
	
	if target_position == position_a:
		target_position = position_b
	else:
		target_position = position_a
		
	is_waiting = false
