class_name PropSaveFile extends Resource

@export var scene : PackedScene

@export var dependencies := {}

func pack(scene_root : Node) -> Error:
	
	#var scene_copy = scene_root.duplicate()
	
	#_extract_dependencies(scene_copy, scene_copy)
	
	return OK# scene.pack(scene_copy)


func _extract_dependencies(node_copy : Node, owner : Node) -> void:
	
	if node_copy.owner != owner:
		return
	
	if node_copy is MeshInstance3D:
		dependencies[owner.get_path_to(node_copy)] = node_copy.mesh.duplicate(true)
		node_copy.mesh = null
	elif node_copy is CollisionShape3D:
		dependencies[owner.get_path_to(node_copy)] = node_copy.shape.duplicate(true)
		node_copy.shape = null
	
	for child in node_copy.get_children(true):
		_extract_dependencies(child, owner)
	
