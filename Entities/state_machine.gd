class_name StateMachine extends Node

signal state_changing(new_state : State)

@export var state : State

func _ready() -> void:
	if state:
		state.set_processes(true)
		state._state_begin()

func change_state(new_state : State) -> void:
	
	print("Changing state to ", new_state)
	
	if state == new_state: return
	
	state_changing.emit(new_state)
	
	if state:
		state._state_end()
		state.set_processes(false)
	
	state = new_state
	
	if state:
		state._state_begin()
		state.set_processes(true)
