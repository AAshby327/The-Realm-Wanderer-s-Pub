class_name MeshHighlightComp extends HighlightComp

@export var alpha := 0.5
@export var mesh_nodes : Array[MeshInstance3D]
@export var highlight_child_meshes := true

@onready var highlight_material := load("res://Assets/Shaders and Materials/highlight_material.tres") as StandardMaterial3D

var _mesh_instances : Array[MeshInstance3D]

func _ready() -> void:
	hide()
	set_highlight_material()

func set_color(color : Color) -> void:
	color.a = highlight_material.albedo_color.a
	highlight_material.albedo_color = color

func hide() -> void:
	highlight_material.albedo_color.a = 0.0

func show() -> void:
	highlight_material.albedo_color.a = alpha

func set_highlight_material() -> void:
	# clear previous material overlays
	for mesh_inst in _mesh_instances:
		if mesh_inst.material_overlay == highlight_material:
			mesh_inst.material_overlay = null
	
	# Find mesh children
	_mesh_instances = mesh_nodes.duplicate()
	if highlight_child_meshes:
		for mesh_inst in mesh_nodes:
			_mesh_instances.append_array(_get_mesh_children(mesh_inst))
	
	# Apply material overlay
	for mesh_inst in _mesh_instances:
		mesh_inst.material_overlay = highlight_material


func _get_mesh_children(root : Node) -> Array[MeshInstance3D]:
	var found_meshes : Array[MeshInstance3D]
	
	for child in root.get_children(true):
		if child is MeshInstance3D:
			found_meshes.append(child)
		
		found_meshes.append_array(_get_mesh_children(child))
	
	return found_meshes
