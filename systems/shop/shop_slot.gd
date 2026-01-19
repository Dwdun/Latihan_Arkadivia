extends Button

var my_listing: ShopListing
var parent_ui: Control

func setup(listing: ShopListing, current_stock: int, ui_ref: Control):
	my_listing = listing
	parent_ui = ui_ref
	
	# Tampilan Barang
	$HBoxContainer/TextureRect.texture = listing.item_to_sell.icon
	var qty_sell = listing.quantity_sell
	var stock_str = "∞" # Simbol infinity
	
	if current_stock != -1:
		stock_str = str(current_stock)
	
	var name_txt = listing.item_to_sell.name
	# Tambahkan info stok di nama
	if current_stock == -1:
		name_txt += " (∞)"
	else:
		name_txt += " (x" + str(current_stock) + ")"
	
	$HBoxContainer/LabelName.text = listing.item_to_sell.name
	
	# Tampilan Harga (Format string manual)
	var cost_text = ""
	
	# 1. Harga Gold
	if listing.price_gold > 0:
		cost_text += str(listing.price_gold) + " G "
	
	# 2. Harga Item
	for req in listing.required_items:
		var item = req["item"] as ItemData
		var amt = req["amount"]
		cost_text += "+ %d %s " % [amt, item.name]
	
	$HBoxContainer/LabelCost.text = cost_text

func _pressed():
	if parent_ui:
		parent_ui.on_buy_attempt(my_listing)
