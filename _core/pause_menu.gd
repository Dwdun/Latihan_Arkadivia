extends Control

@onready var main_container = $PanelContainer # Atau MainContainer (sesuaikan nama node)
@onready var settings_container = $SettingsContainer # Pastikan Anda sudah membuat node ini (Langkah 2)

func _ready() -> void:
	hide()
	settings_container.hide()
	main_container.show()
	$AnimationPlayer.play("RESET")

func resume():
	hide()
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	
func pause():
	# Reset tampilan ke menu utama pause setiap kali dibuka
	settings_container.hide()
	main_container.show()
	
	show()
	get_tree().paused = true
	$AnimationPlayer.play("blur")

func _unhandled_input(event):
	# Gunakan unhandled_input agar tidak konflik saat mengetik (kalau ada input teks)
	if event.is_action_pressed("pause"): # Pastikan Input Map "pause" (biasanya Esc) sudah ada
		if get_tree().paused:
			resume()
		else:
			pause()

# --- TOMBOL UTAMA ---

func _on_resume_button_pressed() -> void:
	resume()

func _on_restart_button_pressed() -> void:
	resume()
	# Gunakan SceneManager agar transisi halus
	SceneManager.change_scene(get_tree().current_scene.scene_file_path, "start")

func _on_settings_button_pressed() -> void:
	# JANGAN pindah scene. Cukup tukar visibilitas panel.
	main_container.hide()
	settings_container.show()

func _on_exit_to_main_menu_button_pressed() -> void:
	resume()

	GameManager.set_cutscene_mode(false)
	GameManager.reset_game_data()

	SceneManager.change_scene("res://_core/main_menu.tscn", "", false)

func _on_quit_button_pressed() -> void:
	# Opsional: Save otomatis sebelum keluar?
	# SavingSystem.save_game() 
	get_tree().quit()

# --- TOMBOL DI DALAM SETTINGS CONTAINER ---

func _on_back_from_settings_pressed():
	# Tombol Back baru yang Anda buat di SettingsContainer
	settings_container.hide()
	main_container.show()
