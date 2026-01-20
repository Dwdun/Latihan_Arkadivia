extends Control

# Ganti ini dengan path Level 1 Anda yang asli
@export_file("*.tscn") var level_1_path: String = "res://levels/level_1.tscn" 

func _ready() -> void:
	if GlobalUI: GlobalUI.hide_ui()
	
	# Hubungkan sinyal (jika belum via editor)
	# Pastikan nama node tombol Anda sesuai di Editor
	#if has_node("CenterContainer/VBoxContainer/BEnchanter"):
		#$CenterContainer/VBoxContainer/HBoxContainer/TextureRect2/BEnchanter.pressed.connect(_on_a_pressed)
		#$CenterContainer/VBoxContainer/HBoxContainer/TextureRect/BExecutor.pressed.connect(_on_b_pressed)
		#$CenterContainer/VBoxContainer/BExit.pressed.connect(_on_back_pressed) # Ubah jadi Back
#
#func _on_a_pressed():
	#print("Memilih Enchanter...")
	#GameManager.select_character("enchanter")
	#_start_game()
#
#func _on_b_pressed():
	#print("Memilih Executor...")
	#GameManager.select_character("executioner")
	#_start_game()
#
func _start_game():
	# Pindah ke Level 1, cari pintu ID "start"
	SceneManager.change_scene(level_1_path, "start")

#func _on_back_pressed():
	## Kembali ke Main Menu Utama (Menu Teman)
	## Ganti path ini sesuai lokasi scene Main Menu teman Anda
	#get_tree().change_scene_to_file("res://_core/main_menu.tscn")


func _on_b_executor_pressed() -> void:
	print("Memilih Executor...")
	GameManager.select_character("executioner")
	_start_game()


func _on_b_enchanter_pressed() -> void:
	print("Memilih Enchanter...")
	GameManager.select_character("enchanter")
	_start_game()


func _on_b_exit_pressed() -> void:
	# Kembali ke Main Menu Utama (Menu Teman)
	# Ganti path ini sesuai lokasi scene Main Menu teman Anda
	get_tree().change_scene_to_file("res://_core/main_menu.tscn")
