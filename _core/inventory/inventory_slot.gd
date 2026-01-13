extends Button

@onready var icon_rect: TextureRect = $Icon
@onready var quantity_lbl: Label = $Quantity

var my_item: ItemData

func set_item(item: ItemData, amount: int):
	my_item = item
	
	# Update Visual
	icon_rect.texture = item.icon
	
	# Jika jumlah > 1, tampilkan angka. Jika 1, sembunyikan (biar bersih)
	if amount > 1:
		quantity_lbl.text = str(amount)
		quantity_lbl.visible = true
	else:
		quantity_lbl.visible = false

	# Tooltip bawaan Godot (muncul kalau mouse hover)
	tooltip_text = item.name + "\n" + item.description
