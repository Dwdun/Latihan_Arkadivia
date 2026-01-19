@tool
extends BTAction

@export var method_name: String = ""
@export var wait_for_finish: bool = true 

# Variable untuk mengingat apakah task ini sudah kita jalankan atau belum
var _has_started: bool = false

# Fungsi ini dipanggil otomatis saat Node ini pertama kali aktif (Enter)
func _enter() -> void:
	_has_started = false

func _tick(delta: float) -> Status:
	if not agent.has_method(method_name):
		return FAILURE
	
	# A. Jika task BELUM dimulai
	if not _has_started:
		# Cek apakah Boss sedang sibuk gara-gara task LAIN?
		# Jika ya, kita ngalah (FAILURE) agar Tree cari jalan lain
		if agent.get("is_attacking"):
			return FAILURE 
		
		# Jalankan fungsi Boss!
		agent.call(method_name)
		_has_started = true
		
		# Jika mode "Chase" (wait=false), langsung lapor Sukses
		if not wait_for_finish:
			return SUCCESS
		
		return RUNNING

	# B. Jika task SUDAH dimulai (Sedang menunggu animasi)
	if wait_for_finish:
		# Cek apakah Boss masih sibuk?
		if agent.get("is_attacking"):
			return RUNNING # Masih animasi, jangan ganggu
		else:
			return SUCCESS # Animasi selesai! Lapor ke Cooldown.
			
	return SUCCESS
