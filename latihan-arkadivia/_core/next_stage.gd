extends Control

var base_stage = "res://levels/dummy_level_"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not FileAccess.file_exists(next_stage()):
		$PanelContainer/VBoxContainer/NextStageButton.hide()
	hide()
	
func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_to_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://_core/main_menu.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()

func next_stage():
	var next = Global.current_stage + 1
	var next_stage_path = base_stage + str(next) + ".tscn"
	return next_stage_path
	

func _on_next_stage_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(next_stage())
	Global.current_stage += 1
	SavingSystem.save_game()
