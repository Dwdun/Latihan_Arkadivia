extends Control

# Path ke Level 1 Anda (Ganti sesuai nama file asli Anda)
@export_file("*.tscn") var level_1_path: String

func _ready() -> void:
	if GlobalUI:
		GlobalUI.hide_ui()
	# Sambungkan sinyal tombol secara kode (atau via editor)
	$CenterContainer/VBoxContainer/BEnchanter.pressed.connect(_on_a_pressed)
	$CenterContainer/VBoxContainer/BExecutor.pressed.connect(_on_b_pressed)
	$CenterContainer/VBoxContainer/BExit.pressed.connect(_on_exit_pressed)

func _on_a_pressed():
	print("Memilih Enchanter...")
	# 1. Simpan Pilihan ke GameManager
	GameManager.select_character("enchanter")
	
	# 2. Pindah ke Level 1 lewat SceneManager
	# ID "start" harus sesuai dengan ID Pintu di Level 1
	SceneManager.change_scene(level_1_path, "start")

func _on_b_pressed():
	print("Memilih Executor...")
	# 1. Simpan Pilihan ke GameManager
	GameManager.select_character("executioner")
	
	# 2. Pindah ke Level 1
	SceneManager.change_scene(level_1_path, "start")

func _on_exit_pressed():
	get_tree().quit()
