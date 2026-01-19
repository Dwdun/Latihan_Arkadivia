extends Button

@onready var icon_rect: TextureRect = $Icon
@onready var quantity_lbl: Label = $Quantity

var my_item: ItemData

func _ready() -> void:
	# Sambungkan sinyal 'pressed' (Klik / Enter) ke fungsi kita
	pressed.connect(_on_slot_pressed)

func set_item(item: ItemData, amount: int):
	my_item = item
	icon_rect.texture = item.icon
	
	if amount > 1:
		quantity_lbl.text = str(amount)
		quantity_lbl.visible = true
	else:
		quantity_lbl.visible = false
	
	# Update Tooltip dengan Info Heal
	var tooltip = item.name
	if item.type == ItemData.Type.CONSUMABLE:
		tooltip += "\nHeal: " + str(item.effect_amount) + " HP"
	tooltip += "\n" + item.description
	
	tooltip_text = tooltip

func _on_slot_pressed():
	if my_item:
		# Panggil Manager untuk memproses item ini
		InventoryManager.use_item(my_item)
		
		# Karena InventoryUI me-refresh (menghancurkan & membuat ulang slot) 
		# setelah update, fokus WASD akan hilang/reset. 
		# Kita biarkan UI Utama yang mengatur reset fokusnya nanti.
