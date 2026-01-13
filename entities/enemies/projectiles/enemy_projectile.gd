class_name EnemyProjectile
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 0
var lifetime: float = 5.0

func setup(pos: Vector2, dir: Vector2, speed: float, dmg: int):
	global_position = pos
	velocity = dir.normalized() * speed
	damage = dmg
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D):
	# Kena Dinding
	queue_free() # Atau spawn partikel ledakan

func _on_area_entered(area: Area2D):
	# Kena Player (HurtboxComponent)
	if area is HurtboxComponent:
		area.take_damage(damage, global_position)
		queue_free()
