extends Area2D

@export var speed: float = 400.0
@export var damage: int = 10
@export var lifetime: float = 5.0 # Hapus otomatis setelah 5 detik

@export var slime_minion_scene: PackedScene
var is_phase_two_projectile: bool = false

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# 1. Sambungkan sinyal tabrakan
	body_entered.connect(_on_body_entered)
	
	# 2. Sambungkan sinyal keluar layar (Opsional, untuk safety)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
	
	# 3. Timer manual untuk lifetime (jika notifier gagal)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Gerakkan peluru lurus sesuai arah
	position += direction * speed * delta
	
	# (Opsional) Putar sprite sesuai arah
	rotation = direction.angle()

func _on_body_entered(body: Node2D):
	# A. Jika menabrak Tembok (World)
	# Pastikan TileMap atau Lantai Anda punya collision layer yang sesuai
	if body is TileMap or body is TileMapLayer or body is StaticBody2D:
		_destroy()
		return

	# B. Jika menabrak Player
	if body.is_in_group("player"):
		# Cek apakah player punya komponen darah?
		if body.has_node("HealthComponent"):
			# Cara 1: Panggil health component langsung
			body.get_node("HealthComponent").damage(damage)
			
		elif body.has_method("take_damage"):
			# Cara 2: Panggil fungsi take_damage di script player
			body.take_damage(damage)
			
		_destroy()

func _destroy():
	if is_phase_two_projectile and slime_minion_scene:
		_attempt_summon_minion()
	queue_free()

func _attempt_summon_minion():
	# 1. Cek berapa jumlah slime minion yang ada di arena saat ini
	# Kita gunakan Group khusus "summoned_minion" agar boss tidak ikut terhitung
	var current_minions = get_tree().get_nodes_in_group("summoned_minion")
	
	# 2. Aturan: Maksimal 2 slime
	if current_minions.size() < 2:
		var minion = slime_minion_scene.instantiate()
		minion.global_position = global_position
		
		# 3. PENTING: Masukkan ke group agar bisa dihitung nanti
		minion.add_to_group("summoned_minion")
		
		# 4. Spawn di world (menggunakan call_deferred agar aman saat physics process)
		get_tree().current_scene.call_deferred("add_child", minion)
