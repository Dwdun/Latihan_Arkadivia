extends HSlider

@export var bus_index: int

func _ready() -> void:
	bus_index = AudioServer.get_bus_index("Master")
	# Load nilai awal dari Save Data
	value = Global.settings["master_volume"]
	
	value_changed.connect(_on_value_changed)

func _on_value_changed(val: float) -> void:
	# 1. Update Global Data
	Global.settings["master_volume"] = val
	
	# 2. Terapkan Audio & Save File
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
