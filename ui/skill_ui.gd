extends Control

@onready var icon_sprite: Sprite2D = $Icon
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Dengar sinyal jika animasi selesai
	anim_player.animation_finished.connect(_on_animation_finished)

func setup_skill(skill_resource: BaseSkill):
	if skill_resource and skill_resource.icon:
		icon_sprite.texture = skill_resource.icon
		icon_sprite.frame = 0
		# Reset speed scale agar normal
		anim_player.speed_scale = 1.0 

func play_cooldown_animation(cooldown_time: float):
	anim_player.play("cooldown")
	
	if cooldown_time > 0:
		# Rumus: 1 detik (durasi asli) / cooldown = speed yang pas
		anim_player.speed_scale = 1.0 / cooldown_time
	else:
		anim_player.speed_scale = 1.0

func _on_animation_finished(anim_name: String):
	if anim_name == "cooldown":
		# KEMBALIKAN KE FRAME 0 (READY)
		icon_sprite.frame = 0
