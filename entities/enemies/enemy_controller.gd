class_name EnemyController
extends CharacterBody2D

@export var stats: EnemyStats

# --- KOMPONEN ---
@onready var visuals: Node2D = $Visuals
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_component: HealthComponent = $HealthComponent
@onready var bt_player: BTPlayer = $BTPlayer
@onready var vision_component: VisionComponent = $VisionComponent
var pickup_scene = preload("res://entities/player/pickup_item.tscn")

@onready var body_hitbox: HitboxComponent = $Visuals/BodyHitbox

var body_damage_cooldown: float = 0.0
var body_reset_time: float = 1.0

# --- STATE VARIABLES ---
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var attack_cooldowns: Dictionary = {}
var is_attacking: bool = false
var is_hurt: bool = false
var is_dead: bool = false

func _ready() -> void:
	if not stats:
		push_error("ENEMY STATS KOSONG! Pasang Resource di Inspector.")
		set_physics_process(false)
		return

	bt_player.blackboard.set_var("target", null)

	health_component.max_health = stats.max_health
	health_component.current_health = stats.max_health

	if body_hitbox:
		body_hitbox.damage = stats.contact_damage
		body_hitbox.knockback_force = 200.0

	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	animation_player.animation_finished.connect(_on_animation_finished)

	if animation_player.has_animation("Idle"):
		animation_player.play("Idle")
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * stats.gravity_scale * delta

	for k in attack_cooldowns.keys():
		if attack_cooldowns[k] > 0: attack_cooldowns[k] -= delta

	if body_hitbox and not is_dead:
		body_damage_cooldown -= delta
		if body_damage_cooldown <= 0:
			body_hitbox.reset_hitbox()
			body_damage_cooldown = body_reset_time
	# Friksi
	if is_attacking or is_hurt or is_dead:
		velocity.x = move_toward(velocity.x, 0, stats.friction * delta)
	for k in attack_cooldowns.keys():
		if attack_cooldowns[k] > 0: attack_cooldowns[k] -= delta
	
	_update_vision()
	move_and_slide()

func can_use_attack(index: int) -> bool:
	if index >= stats.attacks.size(): return false
	var atk = stats.attacks[index]
	return attack_cooldowns.get(atk, 0.0) <= 0

func perform_attack(index: int, target_pos: Vector2):
	if is_attacking or is_hurt or is_dead: return
	
	var atk = stats.attacks[index]
	attack_cooldowns[atk] = atk.cooldown
	is_attacking = true
	
	animation_player.play(atk.animation_name)
	
	# SETUP HITBOX SERANGAN
	var atk_hitbox = visuals.get_node_or_null("AttackHitbox")
	if atk_hitbox and atk_hitbox is HitboxComponent:
		atk_hitbox.damage = atk.damage
		# Jika tipe melee, set knockback
		if atk is EnemyAttackMelee:
			atk_hitbox.knockback_force = atk.knockback_force
	
	# LOGIKA LUNGE
	if atk is EnemyAttackMelee and atk.lunge_speed > 0:
		var dir = (target_pos - global_position).normalized()
		visuals.scale.x = 1 if dir.x > 0 else -1 # Hadap target
		velocity = Vector2(dir.x * atk.lunge_speed, -150) # Loncat sedikit

func _on_player_seen(body):
	if body is CharacterBody2D: 
		bt_player.blackboard.set_var("target", body)

func _on_player_lost(body):
	if body == bt_player.blackboard.get_var("target", null):
		bt_player.blackboard.set_var("target", null)

func _on_damaged(amount: int, source_pos: Vector2, knockback_force: float):
	if is_dead: return
	is_hurt = true
	is_attacking = false
	animation_player.play("Hurt")
	
	var dir = (global_position - source_pos).normalized()
	
	var strength = knockback_force if knockback_force > 0 else 250.0
	
	velocity = dir * strength

func _on_died():
	is_dead = true
	collision_layer = 0
	collision_mask = 1
	if body_hitbox:
		body_hitbox.set_deferred("monitoring", false)
	
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

func _on_animation_finished(anim_name: String):
	if anim_name == "Die":
		queue_free()

	if anim_name == "Attack":
		is_attacking = false
		# Jangan lupa matikan hitbox attack
		var atk_hitbox = visuals.get_node_or_null("AttackHitbox")
		if atk_hitbox: atk_hitbox.set_deferred("monitoring", false)
		
		if animation_player.has_animation("Idle"):
			animation_player.play("Idle")
			
	if anim_name == "Hurt":
		is_hurt = false
		is_attacking = false 
		if animation_player.has_animation("Idle"):
			animation_player.play("Idle")

func _update_vision():
	if vision_component.can_see_player():
		bt_player.blackboard.set_var("target", vision_component.player)
	else:
		bt_player.blackboard.set_var("target", null)
