class_name Utilities

static func remove_from_tree(node : Node) -> void:
	var parent := node.get_parent()
	if parent:
		parent.remove_child(node)

static func equals_any(val, possibilities : Array) -> bool:
	for p in possibilities:
		if val == p:
			return true
	return false

static func make_local(scene : Node, delete_old : bool = false) -> void:
	var parent := scene.get_parent()
	
	if not parent:
		push_error("Scene does not have a parent.")
		return
	
	var new_scene = scene.duplicate()
	
	parent.add_child(new_scene, true)
	change_ownership(new_scene, parent)
	new_scene.scene_file_path = ""
	
	if delete_old:
		scene.free()


static func change_ownership(node : Node, owner : Node) -> void:
	
	if node != owner:
		node.owner = owner
	
	for child in node.get_children(true):
		change_ownership(child, owner)
	
static func save_scene(scene : Node, path : String) -> Error:
	
	scene = scene.duplicate()
	change_ownership(scene, scene)
	
	var packed_scene := PackedScene.new()
	packed_scene.pack(scene)
	
	const FLAGS := ResourceSaver.FLAG_BUNDLE_RESOURCES \
				+ ResourceSaver.FLAG_CHANGE_PATH \
				+ ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS
	
	return ResourceSaver.save(packed_scene, path, FLAGS)
