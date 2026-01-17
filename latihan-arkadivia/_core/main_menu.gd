extends Control

func _ready() -> void:
	SettingsManager.load_settings()
	SavingSystem.load_game()
	print(Global.data)
	print(Global.settings)

func _on_new_game_pressed() -> void: # Load new game
	get_tree().change_scene_to_file("res://levels/dummy_level_1.tscn")


func _on_load_pressed() -> void: # Load saved game
	var saved_game = "res://levels/dummy_level_" + str(int(Global.data["stage"])) + ".tscn"
	get_tree().change_scene_to_file(saved_game)
	print(saved_game)


func _on_settings_pressed() -> void: # Go to settings
	get_tree().change_scene_to_file("res://_core/settings_menu.tscn")


func _on_quit_pressed() -> void: # Quit the game
	get_tree().quit()


func _on_credit_pressed() -> void: # Load credit
	get_tree().change_scene_to_file("res://_core/credit.tscn")


func _on_mute_master_pressed() -> void: # Mute master volume
	var bus_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_index, not AudioServer.is_bus_mute(bus_index))
	print(AudioServer.is_bus_mute(bus_index))
	Global.settings["master_is_muted"] = AudioServer.is_bus_mute(bus_index)
	SettingsManager.apply_settings()
	SettingsManager.save_settings()


func _on_mute_music_pressed() -> void: # Mute music
	var bus_index := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_mute(bus_index, not AudioServer.is_bus_mute(bus_index))
	Global.settings["music_volume"] = 0
	Global.settings["music_is_muted"] = AudioServer.is_bus_mute(bus_index)
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
