extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var animation_player = $AnimationPlayer

@export var stats: EnemyStats

var pickup_scene = preload("res://entities/player/pickup_item.tscn")

func _ready() -> void:
	health_component.damaged.connect(_on_damaged)

func _on_damaged(amount: int, source_pos: Vector2, knockback_force: float):
	animation_player.play("Die")
	if stats and stats.loot_table.size() > 0:
		drop_loot()

func drop_loot():
	for loot in stats.loot_table:
		var chance = loot.get("chance", 1.0)
		var roll = randf()

		if roll <= chance:
			var item = loot.get("item")
			var qty = loot.get("amount", 1)

			if item:
				spawn_pickup(item, qty)

func spawn_pickup(item: ItemData, qty: int):
	var pickup = pickup_scene.instantiate()

	pickup.global_position = global_position + Vector2(0, -20)
	pickup.setup(item, qty)
	get_parent().call_deferred("add_child", pickup)
