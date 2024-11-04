class_name State extends Node

var enabled : bool :
	get:
		return is_processing()

func set_processes(enable : bool):
	set_process(enable)
	set_physics_process(enable)
	set_process_input(enable)
	set_process_shortcut_input(enable)
	set_process_unhandled_input(enable)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_processes(false)
	
## Abstract function, called when this state is enabled.
func _state_begin() -> void:
	pass

## Abstract function, called when this state is disabled.
func _state_end() -> void:
	pass
