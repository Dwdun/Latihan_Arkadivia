extends CanvasLayer

@onready var hp_label: Label = $HPLabel
func _ready() -> void:
	# Default: Sembunyi saat game baru dinyalakan (Booting)
	hide_ui()

func update_hp_ui(current: int, max_hp: int):
	if hp_label:
		# Format teks: "HP: 50 / 100"
		hp_label.text = "HP: %s / %s" % [str(current), str(max_hp)]

func show_ui():
	visible = true

func hide_ui():
	visible = false
	# Opsional: Jika inventory sedang terbuka, tutup paksa
	# if $InventoryUI.visible: $InventoryUI.toggle_inventory()
