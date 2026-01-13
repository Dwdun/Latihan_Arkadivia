class_name PlayerStats
extends Resource

@export_group("Movement")
@export var move_speed: float = 200.0
@export var acceleration: float = 800.0 # Seberapa cepat mencapai max speed
@export var friction: float = 1000.0    # Seberapa cepat berhenti (biar tidak licin)

@export_group("Jump")
@export var jump_force: float = -400.0
@export var gravity_scale: float = 1.0
@export var max_jumps: int = 1 # Set ke 1 agar tidak bisa double jump
@export var coyote_time: float = 0.1    # Waktu toleransi jatuh
@export var jump_buffer: float = 0.1    # Waktu toleransi tekan tombol sebelum mendarat

@export_group("Combat")
@export var max_health: int = 100
@export var base_damage: int = 10

# ... variabel combat lama ...

@export_group("Wall Mechanics")
@export var wall_slide_speed: float = 150.0  # Kecepatan maksimal merosot ke bawah
@export var wall_jump_force: Vector2 = Vector2(400, -500) # X = Dorong menjauh, Y = Dorong ke atas
