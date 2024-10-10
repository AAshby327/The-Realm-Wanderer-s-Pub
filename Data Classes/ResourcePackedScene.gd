class_name ResourcePackedScene extends Resource

## Packed Scene with all dependencies removed.
@export var packed_scene : PackedScene

## Dictionary containing [property path] -> [resource path].
@export var resource_paths := {}

func pack(scene : Node) -> Error:
	
	resource_paths.clear()
	scene = scene.duplicate()
	
	_find_and_delete_dependencies(scene)
	
	scene.print_tree_pretty()
	
	packed_scene = PackedScene.new()
	return packed_scene.pack(scene)

## Code from https://forum.godotengine.org/t/ways-to-trace-usage-of-built-in-resources/1677/2
func _find_and_delete_dependencies(object : Object, path : String = "/" + object.name) -> void:
	
	var node := object as Node
	
	for property in object.get_property_list():
		if property.type == TYPE_OBJECT:
			var obj = object.get(property.name)
			
			if not obj: continue
			
			var property_path = path+":"+property.name
			
			if obj is Resource:
				resource_paths[NodePath(property_path)] = obj.resource_path
				
				# Find sub-resources
				_find_and_delete_dependencies(obj, property_path)
			
			# Remove dependencies
				if node:
					node.set(property.name, null)
					print("Removing: ", property.name)
	
	if node:
		for child in node.get_children(true):
			_find_and_delete_dependencies(child, path + "/" + child.name)
