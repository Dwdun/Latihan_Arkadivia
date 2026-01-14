extends Control

func _ready() -> void:
	hide()
	$AnimationPlayer.play("RESET")

func resume():
	hide()
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	
func pause():
	show()
	get_tree().paused = true
	$AnimationPlayer.play("blur")

func esc_pressed():
	if Input.is_action_just_pressed("pause") and get_tree().paused == false:
		pause()
	elif Input.is_action_just_pressed("pause") and get_tree().paused == true:
		resume()


func _on_resume_button_pressed() -> void:
	resume()


func _on_restart_button_pressed() -> void:
	resume()
	get_tree().reload_current_scene()


func _on_settings_button_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://_core/settings_menu.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _process(_delta):
	esc_pressed()

func _on_exit_to_main_menu_button_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://_core/main_menu.tscn")
