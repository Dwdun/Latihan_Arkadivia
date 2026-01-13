class_name EnemyStats
extends Resource

@export_group("Vitality")
@export var max_health: int = 30
@export var contact_damage: int = 5 # Damage jika player menabrak badan musuh

@export_group("Movement")
@export var speed: float = 50.0
@export var friction: float = 800.0
@export var gravity_scale: float = 1.0

@export_group("Arsenal")
# PENTING: Gunakan Array[Resource] untuk menghindari error validasi Godot
@export var attacks: Array[Resource] = []
