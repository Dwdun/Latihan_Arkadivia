class_name EnemyAttackDef
extends Resource

# Info Dasar
@export var attack_name: String = "Basic Attack"
@export var damage: int = 10
@export var cooldown: float = 1.5
@export var animation_name: String = "Attack"

# Logika AI (Kapan serangan ini dipakai?)
@export_group("AI Logic")
@export var min_range: float = 0.0 
@export var max_range: float = 60.0 # Jarak maksimal serangan ini bisa dipakai
