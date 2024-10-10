@tool
extends EditorScript

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	
	var dir := "res://Assets/Space Kit/"
	
	for file in DirAccess.get_files_at(dir):
		
		if file.get_extension() == "glb" or file.get_extension() == "gltf":
			var packed_gltf := load(dir + file) as PackedScene
			var scene = packed_gltf.instantiate()
			
			Utilities.change_ownership(scene, null)
			
			var main = scene
			while main.get_child_count(true) == 1 and main.get_child(0) is Node3D:
				main = main.get_child(0)
			
			main.get_parent().remove_child(main)
			scene.free()
			
			if main is Node3D:
				main.position = Vector3.ZERO
			
			var file_name := file.split(".")[0]
			
			Utilities.save_scene(main, dir + file_name + ".tscn")


static func export_model_tscn(imported_model_path : String, tscn_path : String) -> Error:
	
	if not FileAccess.file_exists(imported_model_path):
		return ERR_FILE_NOT_FOUND
	
	var ext := imported_model_path.get_extension()
	if not Utilities.equals_any(ext, ["glb", "gltf", "blend", "fbx"]):
		return ERR_FILE_UNRECOGNIZED
	
	var packed_scene := load(imported_model_path) as PackedScene
	
	if not packed_scene:
		return ERR_FILE_CANT_OPEN
	
	var scene = packed_scene.instantiate()
	
	Utilities.change_ownership(scene, null)
	
	# Trim unnecessary container nodes
	var main = scene
	while main.get_child_count(true) == 1 and main.get_child(0).get_class() == "Node3D":
		main = main.get_child(0)
	Utilities.remove_from_tree(main)
	if scene != main:
		scene.free()
	
	if main is Node3D:
		main.position = Vector3.ZERO
	
	var new_file_path := imported_model_path.split(".")[0] + ".tscn"
		
	return Utilities.save_scene(main, new_file_path)
