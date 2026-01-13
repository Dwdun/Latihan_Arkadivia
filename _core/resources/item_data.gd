class_name ItemData
extends Resource

# --- KATEGORI ITEM ---
enum Type {
	CONSUMABLE, # Potion, Makanan
	CURRENCY,   # Koin khusus, Token
	KEY_ITEM,   # Kunci, Peta
	OTHER       # Material crafting, sampah
}

@export_group("Identity")
@export var name: String = "Item Name"
@export_multiline var description: String = "Deskripsi item disini."
@export var icon: Texture2D
@export var type: Type = Type.OTHER

@export_group("Settings")
@export var max_stack: int = 99 # Default 99 sesuai request
@export var price: int = 10     # Harga jual (0 jika tidak bisa dijual)
@export var can_sell: bool = true
# can_drop di sini maksudnya: "Apakah item ini BISA didapat dari monster?" 
# atau "Apakah item ini bisa dibuang?" 
# Sesuai request 'tidak ada fitur buang', kita anggap ini untuk Loot Table nanti.
@export var is_droppable: bool = true 

# Fungsi helper untuk mengecek tipe
func is_consumable() -> bool: return type == Type.CONSUMABLE
func is_key_item() -> bool: return type == Type.KEY_ITEM
