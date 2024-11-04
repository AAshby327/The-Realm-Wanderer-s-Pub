@tool class_name Prop extends RigidBody3D

signal resized
signal mouse_hover(entered : bool)
signal selected(peer_id : int)
signal deselected(peer_id : int)

@export var size := 1.0 :
	set(value):
		
		if size != value:
			_set_size(value)
			size = value

@export var collision_enabled := true :
	set(value):
		
		if collision_enabled == value:
			return
		
		collision_enabled = value
		for child in get_children(true):
			if child is CollisionShape3D:
				child.disabled = not collision_enabled

var selecting_peer := 0 :
	set(value):
		
		if selecting_peer == value:
			return
		
		if value == 0:
			deselected.emit(selecting_peer)
		else:
			selected.emit(value)
		
		selecting_peer = value

func _set_size(new_size : float) -> void:
	resized.emit()

func set_mouse_hover(enable : bool) -> void:
	mouse_hover.emit(enable)

func select() -> void:
	pass

func deselect() -> void:
	pass
