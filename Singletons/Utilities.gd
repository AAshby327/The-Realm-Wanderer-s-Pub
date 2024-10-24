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

static func cmp_vectors(v1, v2, precision := 0.0000001) -> bool:
	
	var v1_type := typeof(v1)
	var v2_type := typeof(v2)
	
	if v1_type != v2_type and \
	(v1_type == TYPE_VECTOR2 or v1_type == TYPE_VECTOR3 or v1_type == TYPE_VECTOR4):
		push_error("Cannot compare vector types ", type_string(v1_type), " and ",\
		type_string(v2_type), ".")
		return false
	
	return (v1 - v2).length_squared() < precision ** 2
	


static func add_weighted_normals(mesh : Mesh) -> Error:
		
	var mdt_error : Error
	var mdt_surfaces : Array[MeshDataTool]
	
	for s in range(mesh.get_surface_count()):
		var mdt := MeshDataTool.new()
		mdt_error = mdt.create_from_surface(mesh, s)
		
		if mdt_error: return mdt_error
		mdt_surfaces.append(mdt)
		
		for v in range(mdt.get_vertex_count()):
			
			
			var new_normal := Vector3.ZERO
			var faces := mdt.get_vertex_faces(v)
			
			for f in faces:
				
				if mdt.get_face_normal(f) == new_normal: continue
				
				new_normal += mdt.get_face_normal(f)
			
			new_normal = new_normal.normalized()
			
			if new_normal == Vector3.ZERO: continue
			
			mdt.set_vertex_normal(v, new_normal)
			
		mesh = ArrayMesh.new()
		mdt_error = mdt.commit_to_surface(mesh)
		
		if mdt_error: return mdt_error
	
	mesh.clear_surfaces()
	for mdt in mdt_surfaces:
		mdt_error = mdt.commit_to_surface(mesh)
		if mdt_error: return mdt_error
	
	return OK

static func create_smooth_mesh(mesh : Mesh) -> ArrayMesh:
	
	if not mesh is ArrayMesh:
		var st := SurfaceTool.new()
		var arr_mesh := ArrayMesh.new()
		for s in range(mesh.get_surface_count()):
			st.append_from(mesh, s, Transform3D.IDENTITY)
			st.commit(arr_mesh)
		
		mesh = arr_mesh
	
	var result := ArrayMesh.new()
	
	var mdt_error : Error
	var mdt_surfaces : Array[MeshDataTool]
	
	for s in range(mesh.get_surface_count()):
		var mdt := MeshDataTool.new()
		mdt_error = mdt.create_from_surface(mesh, s)
		
		if mdt_error: return result
		mdt_surfaces.append(mdt)
		
		for v in range(mdt.get_vertex_count()):
			
			print("--------------------------------------")
			prints("Vertex:", v, mdt.get_vertex_normal(v))
			var new_normal := Vector3.ZERO
			var faces := mdt.get_vertex_faces(v)
			var face_normals : PackedVector3Array
			
			for f in faces:
				var normal := mdt.get_face_normal(f)
				prints("face:", f, normal)
				if not face_normals.has(normal):
					
					face_normals.append(normal)
					new_normal += normal
					
						
			#new_normal = new_normal.normalized()
			prints("setting:", new_normal)
			
			mdt.set_vertex_normal(v, new_normal)
			
		mdt_error = mdt.commit_to_surface(result)
		
		if mdt_error: return result
	
	for mdt in mdt_surfaces:
		mdt_error = mdt.commit_to_surface(result)
	
	return result


static func create_continuous_normals(mesh : Mesh) -> ArrayMesh:
	
	if not mesh is ArrayMesh:
		#print("Converting to Array")
		var st := SurfaceTool.new()
		var arr_mesh := ArrayMesh.new()
		for s in range(mesh.get_surface_count()):
			st.append_from(mesh, s, Transform3D.IDENTITY)
			st.commit(arr_mesh)
		
		mesh = arr_mesh
	
	var result_mesh := ArrayMesh.new()
	
	var mdt_surfaces : Array[MeshDataTool]
	var vertices : PackedVector3Array
	var faces : Array[PackedInt32Array]
	var face_normals : PackedVector3Array
	
	for s in mesh.get_surface_count():
		var mdt := MeshDataTool.new()
		mdt_surfaces.append(mdt)
		mdt.create_from_surface(mesh, s)
		
		# Record vertices
		for v in range(mdt.get_vertex_count()):
			var vertex := mdt.get_vertex(v)
			if not vertices.has(vertex):
				vertices.append(vertex)
		
		# Record faces
		for f in range(mdt.get_face_count()):
			var face_vertices : PackedInt32Array
			for v in range(3):
				var vertex := mdt.get_vertex(mdt.get_face_vertex(f, v))
				var vertex_id := vertices.find(vertex)
				assert(vertex_id >= 0, "Face Vertex not found")
				
				face_vertices.append(vertex_id)
			
			faces.append(face_vertices)
			face_normals.append(mdt.get_face_normal(f))
	
	# Connect faces to vertices
	var vertex_faces : Array[PackedInt32Array]
	vertex_faces.resize(vertices.size())
	
	for f in range(faces.size()):
		for v in faces[f]:
			vertex_faces[v].append(f)
	
	## Calculate normals
	var vertex_normals : PackedVector3Array
	for v in range(vertices.size()):
		var normal := Vector3.ZERO
		var unique_face_normals : PackedVector3Array
		
		prints(v, "--------------------------------")
		
		for f in vertex_faces[v]:
			
			var is_unique := true
			for un in unique_face_normals:
				if un.is_equal_approx(face_normals[f]):
					is_unique = false
					break
			
			if is_unique:
				prints(f, face_normals[f])
				normal += face_normals[f]
				unique_face_normals.append(face_normals[f])
			
		print(normal)
		vertex_normals.append(normal.normalized())
	
	## Set normals
	for mdt in mdt_surfaces:
		for v in range(mdt.get_vertex_count()):
			var position := mdt.get_vertex(v)
			var vertex_id := vertices.find(position)
			
			mdt.set_vertex_normal(v, vertex_normals[vertex_id])
		
		mdt.commit_to_surface(result_mesh)
	
	return result_mesh


static func mesh_to_array_mesh(mesh : Mesh) -> ArrayMesh:
	
	mesh = mesh.duplicate(true)
	
	if mesh is ArrayMesh: return mesh
	
	var arr_mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	
	for s in range(mesh.get_surface_count()):
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.create_from(mesh, s)
		st.commit(arr_mesh)
	
	return arr_mesh
	


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
