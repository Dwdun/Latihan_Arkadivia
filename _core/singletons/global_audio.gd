extends AudioStreamPlayer

# Mengambil referensi ke child node Timer
# Pastikan nama node Timer di scene tree sesuai ("StopTimer")
@onready var stop_timer = $StopTimer

func _ready():
	stop_timer.timeout.connect(_on_stop_timer_timeout)

func play_music_range(audio_file: AudioStream, start_time: float, stop_time: float):
	stream = audio_file
	play(start_time)

	var duration = stop_time - start_time
	if duration > 0:
		stop_timer.wait_time = duration
		stop_timer.start()
	else:
		stop_timer.stop()

func _on_stop_timer_timeout():
	stop()
