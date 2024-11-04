class_name MeshHighlightComp extends HighlightComp

const HIGHLIGHT_MATERIAL_RESOURCE : StandardMaterial3D = preload("res://Assets/Shaders and Materials/highlight_material.tres")

@export var alpha := 0.5
@export var mesh_nodes : Array[MeshInstance3D]
@export var highlight_child_meshes := true

@onready var highlight_material_instance : StandardMaterial3D

#@onready var highlight_material := load("res://Assets/Shaders and Materials/highlight_material.tres") as StandardMaterial3D

var _mesh_instances : Array[MeshInstance3D]

func _ready() -> void:
	
	highlight_material_instance = HIGHLIGHT_MATERIAL_RESOURCE.duplicate()
	#highlight_material_instance.setup_local_to_scene()
	
	set_visibility(false)
	set_highlight_material()

func set_color(color : Color) -> void:
	color.a = highlight_material_instance.albedo_color.a
	highlight_material_instance.albedo_color = color

func set_visibility(visible : bool) -> void:
	highlight_material_instance.albedo_color.a = alpha if visible else 0.0

#func hide() -> void:
	#highlight_material_instance.albedo_color.a = 0.0
#
#func show() -> void:
	#highlight_material_instance.albedo_color.a = alpha

func set_highlight_material() -> void:
	# clear previous material overlays
	for mesh_inst in _mesh_instances:
		if mesh_inst.material_overlay == highlight_material_instance:
			mesh_inst.material_overlay = null
	
	# Find mesh children
	_mesh_instances = mesh_nodes.duplicate()
	if highlight_child_meshes:
		for mesh_inst in mesh_nodes:
			_mesh_instances.append_array(_get_mesh_children(mesh_inst))
	
	# Apply material overlay
	for mesh_inst in _mesh_instances:
		mesh_inst.material_overlay = highlight_material_instance


func _get_mesh_children(root : Node) -> Array[MeshInstance3D]:
	var found_meshes : Array[MeshInstance3D]
	
	for child in root.get_children(true):
		if child is MeshInstance3D:
			found_meshes.append(child)
		
		found_meshes.append_array(_get_mesh_children(child))
	
	return found_meshes
