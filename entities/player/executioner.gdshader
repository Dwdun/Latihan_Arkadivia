shader_type canvas_item;
uniform float cut_off_x = 80.0; // Jarak dalam pixel

void fragment() {
    // Hitung posisi pixel lokal relatif terhadap origin sprite
    if (UV.x * 80.0 > cut_off_x) { 
        COLOR.a = 0.0; // Buat pixel jadi transparan jika lewat batas
    }
}