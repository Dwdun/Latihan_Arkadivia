extends Node2D

@export var bottom:int
@export var top:int
@export var right:int
@export var left:int

func _ready() -> void:
	GameManager.camera_bottom = bottom
	GameManager.camera_left = left
	GameManager.camera_top = top
	GameManager.camera_right = right
	GameManager.camera_zoom = 4
