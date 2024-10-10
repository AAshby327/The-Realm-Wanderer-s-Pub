@tool
class_name Prop extends RigidBody3D

const OUTLINE_MATERIAL = preload("res://Assets/Shaders and Materials/highlight_material.tres")

@export var highlight_color : Color = Color.WHITE
@export var select_color : Color = Color.BLUE

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
			
@onready var highlight_material : StandardMaterial3D = OUTLINE_MATERIAL.duplicate()


var selecting_peer := 0



func _set_size(new_size : float) -> void:
	pass

func set_highlight_visibility(enabled : bool) -> void:
	if enabled:
		highlight_material.albedo_color = Color(highlight_color, 0.1)
		$barrel.material_overlay = highlight_material
	else:
		$barrel.material_overlay = null

func set_select_visibility(enabled : bool) -> void:
	if enabled:
		highlight_material.albedo_color = Color(select_color, 0.1)
		$barrel.material_overlay = highlight_material
	else:
		$barrel.material_overlay = null
		
