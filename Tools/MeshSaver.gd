@tool
extends EditorScript

var input_dir : String = "res://Graphics/"

var output_dir : String = "res://Prop Meshes/"

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	
	print("Starting Process")
	
	var files := PackedStringArray()
	find_files(input_dir, files)
		
	for file in files:
		var p_scene := load(file)
		if p_scene is PackedScene:
			var scene := p_scene.instantiate() as Node
			
			var meshes := get_meshes(scene)
			if meshes.size() != 1:
				print("Multiple Meshes found in:")
				print(file)
			else:
				var mesh := meshes[0].duplicate(true)
				
				var save_path := file.replacen(input_dir, output_dir)
				var ext := save_path.get_extension()
				save_path = save_path.left(-(ext.length() + 1))
				save_path = save_path.replace(".", "_") + ".tres"
				
				var dir_result := DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
				if dir_result == OK:
					var result := ResourceSaver.save(mesh, save_path, 0)
					if result != OK:
						print(error_string(result))
						print(file)
			
			scene.free()

	files.clear()
	
	print("Task Complete.")


func find_files(dir : String, list : PackedStringArray) -> void:
	
	# Get files in dir
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".glb") or file.ends_with(".gltf") or file.ends_with(".tscn"):
			list.append(dir + file)
	
	# Recurse on directories within dir
	for sub_dir in DirAccess.get_directories_at(dir):
		find_files(dir + sub_dir + "/", list)


func get_meshes(scene : Node) -> Array[Mesh]:
	
	var found_meshes : Array[Mesh]
	
	if scene is MeshInstance3D:
		found_meshes.append(scene.mesh)
	
	for child in scene.get_children(true):
		found_meshes += get_meshes(child)
	
	return found_meshes
