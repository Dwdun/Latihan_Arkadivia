extends Control

func _ready() -> void:
	# Pastikan slider menampilkan nilai yang tersimpan di Global
	$MarginContainer/Control/VBoxContainer/VolumeMasterSlider.value = Global.settings["master_volume"]
	$MarginContainer/Control/VBoxContainer/VolumeMusicSlider.value = Global.settings["music_volume"]
	
	# (Opsional) Cek status Mute jika punya Checkbox Mute
	# $MuteCheckbox.button_pressed = Global.settings["master_is_muted"]



func _on_volume_master_slider_value_changed(value: float) -> void:
	Global.settings["master_volume"] = value
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_volume_music_slider_value_changed(value: float) -> void:
	Global.settings["music_volume"] = value
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
