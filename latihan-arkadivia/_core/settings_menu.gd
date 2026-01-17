extends Control

func _ready() -> void:
	$MarginContainer/Control/VBoxContainer/VolumeMasterSlider.value = Global.settings["master_volume"]
	$MarginContainer/Control/VBoxContainer/VolumeMusicSlider.value = Global.settings["music_volume"]
	

func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://_core/main_menu.tscn")
	

func _on_volume_master_slider_value_changed(value: float) -> void:
	Global.settings["master_volume"] = value
	SettingsManager.apply_settings()
	SettingsManager.save_settings()



func _on_volume_music_slider_value_changed(value: float) -> void:
	Global.settings["music_volume"] = value
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
