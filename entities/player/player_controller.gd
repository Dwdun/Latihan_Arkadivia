class_name PlayerController
extends CharacterBody2D

@export var stats: PlayerStats 

@export var equipped_skills: Array[BaseSkill] = []

@onready var limbo_hsm: LimboHSM = $LimboHSM

var temp_active_skill: BaseSkill = null

var temp_dash_speed: float = 0.0
var temp_dash_duration: float = 0.0

var temp_skill_damage: int = 0
var temp_skill_anim: String = ""

var temp_knockback: Vector2 = Vector2.ZERO

var knockback_lock_timer: float = 0.0

var is_dead_flag: bool = false
var temp_skill_can_charge: bool = false
var temp_skill_max_charge: float = 0.0
var temp_skill_multiplier: float = 1.0

var current_mana: int = 0
signal mana_changed(current, max)

@onready var health_component: HealthComponent = $HealthComponent

@onready var visuals: Marker2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D 
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var camera_shaker: Camera2D = $Camera2D
var jump_count: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var input_axis: float = 0.0

func _ready() -> void:
	$Camera2D.limit_bottom = GameManager.camera_bottom
	$Camera2D.limit_top = GameManager.camera_top
	$Camera2D.limit_left = GameManager.camera_left
	$Camera2D.limit_right = GameManager.camera_right
	$Camera2D.zoom.x = GameManager.camera_zoom
	$Camera2D.zoom.y = GameManager.camera_zoom
	if not stats:
		push_error("STATS BELUM DIPASANG! Pasang resource PlayerStats di Inspector.")
		set_physics_process(false)
		return
	
	if stats:
		current_mana = stats.max_mana
		if GlobalUI:
			GlobalUI.update_mana_ui(current_mana, stats.max_mana)
		health_component.max_health = stats.max_health

		health_component.current_health = stats.max_health 
	
	var basic_hitbox = visuals.get_node_or_null("Hitbox") 
	if basic_hitbox:
		basic_hitbox.hit_connected.connect(_on_basic_attack_hit)
	
	if GlobalUI:
		GlobalUI.show_ui()
	
	health_component.died.connect(_on_died)
	health_component.damaged.connect(_on_damaged)
	health_component.health_changed.connect(_on_health_changed)

	_on_health_changed(health_component.current_health, health_component.max_health)
	
	_initialize_hsm()

func _physics_process(delta: float) -> void:
	if coyote_timer > 0:
		coyote_timer -= delta
		
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = stats.jump_buffer

	if is_on_floor():
		jump_count = 0
	input_axis = Input.get_axis("move_left", "move_right")
	
	if not is_on_floor():
		velocity.y += gravity * stats.gravity_scale * delta
	
	if Input.is_action_just_pressed("attack"):
		limbo_hsm.dispatch("attack_started")
	
	for skill in equipped_skills:
		if skill.has_method("tick_cooldown"):
			skill.tick_cooldown(delta)

	if Input.is_action_just_pressed("dash"):
		use_skill(0)
		
	if Input.is_action_just_pressed("skill_1"):
		use_skill(1)

	if not is_on_floor():
		var final_gravity = gravity * stats.gravity_scale

		if velocity.y > 0:
			final_gravity *= 1.5 
			
		velocity.y += final_gravity * delta
		velocity.y = min(velocity.y, 1000.0) 
	move_and_slide()

func apply_dash_data(speed: float, duration: float):
	temp_dash_speed = speed
	temp_dash_duration = duration

func _on_basic_attack_hit():
	gain_mana(1)

func gain_mana(amount: int):
	current_mana += amount
	if current_mana > stats.max_mana:
		current_mana = stats.max_mana
	if GlobalUI:
		GlobalUI.update_mana_ui(current_mana, stats.max_mana)

func use_skill(index: int):
	var current_state = limbo_hsm.get_active_state()
	if current_state.name == "Attack" or current_state.name == "Dead" or current_state.name == "Cast":
		return 

	if index < equipped_skills.size() and equipped_skills[index] != null:
		var skill = equipped_skills[index]
		if not skill.is_ready():
			print("Skill sedang Cooldown!")
			return

		if current_mana >= skill.mana_cost:
			current_mana -= skill.mana_cost
			if GlobalUI: GlobalUI.update_mana_ui(current_mana, stats.max_mana)
			temp_active_skill = skill 
			skill.execute(self, stats) 
			skill.start_cooldown()
			
		else:
			print("Mana tidak cukup!")
			_show_no_mana_feedback()

func _show_no_mana_feedback():
	var tween = create_tween()
	tween.tween_property(visuals, "modulate", Color.CYAN, 0.1)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.1)

func _initialize_hsm():
	var idle_node = load("res://entities/player/states/idle_state.gd").new()
	var move_node = load("res://entities/player/states/move_state.gd").new()
	var air_node = load("res://entities/player/states/air_state.gd").new()
	var dash_node = load("res://entities/player/states/dash_state.gd").new()
	var attack_node = load("res://entities/player/states/attack_state.gd").new()
	var cast_node = load("res://entities/player/states/cast_state.gd").new()
	var wall_slide_node = load("res://entities/player/states/wall_slide_state.gd").new()
	var wall_jump_node = load("res://entities/player/states/wall_jump_state.gd").new()
	var knockback_node = load("res://entities/player/states/knockback_state.gd").new()

	idle_node.name = "Idle"
	move_node.name = "Move"
	air_node.name = "Air"
	dash_node.name = "Dash"
	attack_node.name = "Attack"
	cast_node.name = "Cast"
	wall_slide_node.name = "WallSlide"
	wall_jump_node.name = "WallJump"
	knockback_node.name = "Knockback"

	limbo_hsm.add_child(idle_node)
	limbo_hsm.add_child(move_node)
	limbo_hsm.add_child(air_node)
	limbo_hsm.add_child(dash_node)
	limbo_hsm.add_child(attack_node)
	limbo_hsm.add_child(cast_node)
	limbo_hsm.add_child(wall_slide_node)
	limbo_hsm.add_child(wall_jump_node)
	limbo_hsm.add_child(knockback_node)

	limbo_hsm.add_transition(idle_node, move_node, "move_started")
	limbo_hsm.add_transition(idle_node, air_node, "jump_started")
	limbo_hsm.add_transition(idle_node, air_node, "fall_started")

	limbo_hsm.add_transition(move_node, idle_node, "state_ended") 
	limbo_hsm.add_transition(move_node, air_node, "jump_started")
	limbo_hsm.add_transition(move_node, air_node, "fall_started")

	limbo_hsm.add_transition(air_node, idle_node, "state_ended")
	limbo_hsm.add_transition(air_node, move_node, "move_started")

	limbo_hsm.add_transition(idle_node, dash_node, "dash_started")
	limbo_hsm.add_transition(move_node, dash_node, "dash_started")
	limbo_hsm.add_transition(air_node, dash_node, "dash_started")

	limbo_hsm.add_transition(dash_node, air_node, "fall_started")
	limbo_hsm.add_transition(dash_node, idle_node, "state_ended")
	limbo_hsm.add_transition(dash_node, move_node, "move_started")
	
	limbo_hsm.add_transition(idle_node, attack_node, "attack_started")
	limbo_hsm.add_transition(move_node, attack_node, "attack_started")
	limbo_hsm.add_transition(air_node, attack_node, "attack_started")

	limbo_hsm.add_transition(attack_node, idle_node, "state_ended")
	limbo_hsm.add_transition(air_node, wall_slide_node, "wall_slide_started")

	limbo_hsm.add_transition(wall_slide_node, air_node, "fall_started")
	limbo_hsm.add_transition(wall_slide_node, idle_node, "state_ended")
	
	limbo_hsm.add_transition(wall_slide_node, wall_jump_node, "wall_jump")
	limbo_hsm.add_transition(wall_jump_node, air_node, "state_ended")
	
	limbo_hsm.add_transition(attack_node, dash_node, "dash_started")

	limbo_hsm.add_transition(attack_node, cast_node, "skill_cast_started")
	
	limbo_hsm.add_transition(idle_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(move_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(air_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(dash_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(attack_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(cast_node, knockback_node, "knockback_started")
	limbo_hsm.add_transition(wall_slide_node, knockback_node, "knockback_started")

	limbo_hsm.add_transition(knockback_node, idle_node, "state_ended")
	limbo_hsm.add_transition(knockback_node, air_node, "fall_started")

	limbo_hsm.initial_state = idle_node
	limbo_hsm.initialize(self)
	limbo_hsm.set_active(true)
	
	limbo_hsm.add_transition(idle_node, cast_node, "skill_cast_started")
	limbo_hsm.add_transition(move_node, cast_node, "skill_cast_started")
	limbo_hsm.add_transition(air_node, cast_node, "skill_cast_started")
	limbo_hsm.add_transition(cast_node, idle_node, "state_ended")

func apply_recoil(direction: Vector2):
	velocity += direction * 20
	move_and_slide()

func prepare_skill_attack(dmg: int, anim: String, charging: bool = false, charge_time: float = 0.0, mult: float = 1.0):
	temp_skill_damage = dmg
	temp_skill_anim = anim
	temp_skill_can_charge = charging
	temp_skill_max_charge = charge_time
	temp_skill_multiplier = mult

func _on_died():
	if not is_physics_processing(): return
	
	print("PLAYER MATI! Requesting Respawn...")
	
	set_physics_process(false)
	set_process(false)
	$CollisionShape2D.set_deferred("disabled", true)

	GameManager.respawn_player()
func perform_jump():
	velocity.y = stats.jump_force
	jump_count += 1
	jump_buffer_timer = 0 
	coyote_timer = 0
	apply_squash_stretch(0.8, 1.2)

func apply_squash_stretch(x_scale: float, y_scale: float):
	if visuals:
		var current_facing = sign(visuals.scale.x)
		if current_facing == 0: current_facing = 1
		visuals.scale = Vector2(1 * current_facing, 1) 
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.set_ease(Tween.EASE_OUT)
		visuals.scale = Vector2(x_scale * current_facing, y_scale)
		tween.tween_property(visuals, "scale", Vector2(1.0 * current_facing, 1.0), 0.15)

func add_ghost_trail():
	if not sprite.texture: return

	var ghost = Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes

	var max_frame_index = (sprite.hframes * sprite.vframes) - 1

	if sprite.frame > max_frame_index:
		ghost.frame = max_frame_index
	else:
		ghost.frame = sprite.frame

	ghost.global_position = sprite.global_position 
	ghost.scale = visuals.scale 
	ghost.modulate = Color(0.5, 0.5, 1.0, 0.5) 
	ghost.z_index = -1 
	
	get_parent().add_child(ghost)
	
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ghost.queue_free)
func _on_damaged(amount: int, source_pos: Vector2, knockback_force: float):
	if is_dead_flag: return

	GameManager.hit_stop(0.00, 0)

	_start_iframe_blink()
	
	var dir = (global_position - source_pos).normalized()
	var knock_dir = Vector2(sign(dir.x), -0.8).normalized() 
	var force = knockback_force if knockback_force > 0 else 300.0
	temp_knockback = knock_dir * force
	limbo_hsm.dispatch("knockback_started")
	
func _start_iframe_blink():
	var duration = health_component.iframe_duration
	var tween = create_tween()

	tween.set_loops() 
	tween.tween_property(visuals, "modulate:a", 0.2, 0.1)
	tween.tween_property(visuals, "modulate:a", 1.0, 0.1)
	get_tree().create_timer(duration).timeout.connect(func():
		tween.kill()
		visuals.modulate.a = 1.0
	)

func trigger_skill_cooldown():
	if temp_active_skill and temp_active_skill.has_method("start_cooldown"):
		temp_active_skill.start_cooldown()
		temp_active_skill = null

func _on_health_changed(current_val: int, max_val: int):
	if GlobalUI.has_method("update_hp_ui"):
		GlobalUI.update_hp_ui(current_val, max_val)
