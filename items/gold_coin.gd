extends Area2D

@export var amount: int = 1
@onready var sprite = $Sprite2D

# Setup animasi naik-turun (Tweening)
var start_y: float

func _ready() -> void:
	start_y = position.y
	
	# Sambungkan sinyal tabrakan
	body_entered.connect(_on_body_entered)
	
	# Animasi Floating (Naik turun cantik)
	_start_floating_anim()

func _start_floating_anim():
	var tween = create_tween().set_loops()
	# Naik 5 pixel dalam 1 detik, lalu turun lagi
	tween.tween_property(self, "position:y", start_y - 5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", start_y + 5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body):
	if body.is_in_group("player"):
		_collect_coin()

func _collect_coin():
	# 1. Tambah Gold ke Global
	InventoryManager.add_gold(amount)
	
	# 2. Efek Suara (Opsional, jika ada AudioManager)
	# AudioManager.play_sfx("coin_pickup")
	
	# 3. Efek Visual (Langsung hilang atau animasi)
	# Kita matikan deteksi agar tidak ambil 2x
	set_deferred("monitoring", false)
	
	# Bikin efek 'Puff' atau langsung hapus
	# Agar simple: Tween transparansi lalu hapus
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2) # Fade out
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2) # Membesar sedikit
	tween.tween_callback(queue_free)
