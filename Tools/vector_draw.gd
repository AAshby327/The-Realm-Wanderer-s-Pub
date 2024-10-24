extends Control

@export var color : Color = Color.PURPLE
@export var width := 50.0
@onready var camera :=  get_viewport().get_camera_3d()

func _draw() -> void:
	
	var vector := Vector3(10, 10, 10)
	var origin := Vector3(0, 0, 0)
	
	var start := camera.unproject_position(origin)
	var end := camera.unproject_position(origin + vector)
	
	draw_line(end, start.direction_to(end), color, width)
	
