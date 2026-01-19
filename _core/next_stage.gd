extends Control

var next_level_path: String = ""
var next_door_id: String = ""

func _ready() -> void:
	hide()

func setup_victory(target_path: String, door_id: String):
	next_level_path = target_path
	next_door_id = door_id
	Global.current_stage += 1
	GameManager.current_level_path = next_level_path
	GameManager.last_checkpoint_pos = Vector2.INF 
	GameManager.last_checkpoint_level = next_level_path 

	SavingSystem.save_game()
	print("Level Selesai! Progress Tersimpan ke: ", next_level_path)

	show()
	$AnimationPlayer.play("blur")
	get_tree().paused = true

func _on_next_stage_button_pressed() -> void:
	resume_game()
	if next_level_path != "":
		SceneManager.change_scene(next_level_path, next_door_id)
	else:
		print("Error: Path level selanjutnya kosong!")

func _on_restart_button_pressed() -> void:
	resume_game()
	SceneManager.change_scene(get_tree().current_scene.scene_file_path, "start")

func _on_exit_to_main_menu_button_pressed() -> void:
	resume_game()
	GameManager.reset_game_data()
	SceneManager.change_scene("res://_core/main_menu.tscn", "", false)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func resume_game():
	get_tree().paused = false
	hide()
