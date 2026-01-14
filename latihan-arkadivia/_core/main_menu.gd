extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.S
	

func _on_new_game_pressed() -> void: # Load new game
	get_tree().change_scene_to_file("res://levels/dummy_level.tscn")
	# get_tree().change_scene_to_file()


func _on_load_pressed() -> void: # Load saved game
	get_tree().change_scene_to_file("res://_core/load_menu.tscn")
	pass # Replace with function body.


func _on_settings_pressed() -> void: # Go to settings
	get_tree().change_scene_to_file("res://_core/settings_menu.tscn")


func _on_quit_pressed() -> void: # Quit the game
	get_tree().quit()


func _on_credit_pressed() -> void: # Load credit
	get_tree().change_scene_to_file("res://_core/credit.tscn")


func _on_mute_master_pressed() -> void: # Mute master volume
	var bus_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_index, not AudioServer.is_bus_mute(bus_index))


func _on_mute_music_pressed() -> void: # Mute music
	var bus_index := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_mute(bus_index, not AudioServer.is_bus_mute(bus_index))
