class_name ShopListing
extends Resource

@export_group("Barang Dagangan")
@export var item_to_sell: ItemData
@export var quantity_sell: int = 1

@export_group("Stok")
@export var initial_stock: int = -1 # -1 artinya Unlimited (Tak Terbatas)

@export_group("Biaya (Cost)")
@export var price_gold: int = 100
@export var required_items: Array[Dictionary] = []
