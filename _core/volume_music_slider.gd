extends HSlider

@export var bus_index: int

func _ready() -> void:
	bus_index = AudioServer.get_bus_index("Music")
	# Load nilai awal dari Save Data
	value = Global.settings["music_volume"]
	
	value_changed.connect(_on_value_changed)	

func _on_value_changed(val: float) -> void:
	Global.settings["music_volume"] = val
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
