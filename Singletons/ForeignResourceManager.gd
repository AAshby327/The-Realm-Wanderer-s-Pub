extends Node

var resource_paths := {}

var foreign_resource_dir := "user://custom_resources/"


static func is_resource_foreign(resource : Resource) -> bool:
	return resource.resource_path.begins_with("res://")

func register_foreign_resource(resource : Resource) -> void:
	
	if resource.resource_path.is_empty():
		var resource_name := resource.resource_name + "_" + Time.get_datetime_string_from_system().replace(":", "-")
		resource.take_over_path(foreign_resource_dir + resource_name + ".tres")
	
	if not resource.resource_path.contains("::"):
		if not FileAccess.file_exists(resource.resource_path):
			ResourceSaver.save(resource, resource.resource_path)
	
	resource_paths[resource.resource_path] = resource.resource_name

func unregister_foreign_resource(resource : Resource) -> void:
	resource_paths.erase(resource.resource_path)
