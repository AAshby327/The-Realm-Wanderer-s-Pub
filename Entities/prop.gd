@tool
class_name Prop extends RigidBody3D

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
			
#@onready var highlight_material : StandardMaterial3D = OUTLINE_MATERIAL.duplicate()


var selecting_peer := 0

# Code from https://github.com/gdquest-demos/godot-shaders/blob/main/godot/Demos/Outline/Outline3D/SmoothNormalsMeshInstance.gd
#static func create_smoothed_normals(mesh : Mesh) -> ArrayMesh:
	#
	#var new_mesh := ArrayMesh.new()
	#var materials := []
	#
	#var st := SurfaceTool.new()
	#var mdt := MeshDataTool.new()
	#
	#for s in mesh.get_surface_count():
		#st.begin(Mesh.PRIMITIVE_TRIANGLES)
		#st.create_from(mesh, s)
		#st.deindex()
		#
		#var data := st.commit_to_arrays()
		#
		#st.begin(Mesh.PRIMITIVE_TRIANGLES)
		#st.set_smooth_group(1)
		#
		#for v in data[ArrayMesh.ARRAY_VERTEX]:
			#st.add_vertex(v)
		#
		#st.generate_normals()
		#
		#data[ArrayMesh.ARRAY_COLOR] = _convert_normals_to_color(st.commit_to_arrays())
		#
		#new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	#
	#return new_mesh
	#
#
#static func _convert_normals_to_color(data: Array) -> PackedColorArray:
	#var normals: PackedVector3Array = data[ArrayMesh.ARRAY_NORMAL]
#
	#var out_color := PackedColorArray()
	#for normal in normals:
		#out_color.append(
			#Color(normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5, 1.0)
		#)
#
	#return out_color
#
#static func add_smooth_outline(mesh_inst : MeshInstance3D) -> Error:
	#
	#if not mesh_inst or not mesh_inst.mesh: return ERR_DOES_NOT_EXIST
	#
	#const PRECISION := 0.0001
	#var outline_mat := OUTLINE_MATERIAL.duplicate()
	#
	#var faces := mesh_inst.mesh.get_faces()
	#var unique_vertices := PackedVector3Array()
	#var face_normals := PackedVector3Array()
	#var vertex_faces : Array[PackedInt32Array]
	#var vertex_normals := PackedVector3Array()
	#
	#for f in range(int(faces.size() / 3)):
		#for v in range(3):
			#
			## Find each individual vertex in the mesh
			#var vertex := faces[f*3 + v]
			#if not unique_vertices.has(vertex):
				#unique_vertices.append(vertex)
				#vertex_faces.resize(unique_vertices.size())
			#
			#var vertex_id := unique_vertices.find(vertex)
			#vertex_faces[vertex_id].append(f)
		#
		## Calculate face normals
		#var a := faces[f*3]
		#var b := faces[f*3+1]
		#var c := faces[f*3+2]
		#var dir := (c - a).cross(b - a)
		#face_normals.append(dir.normalized())
	#
	## Calculate vertex normals
	#vertex_normals.resize(unique_vertices.size())
	#for v in range(unique_vertices.size()):
		#var unique_normals := PackedVector3Array()
		#var vertex_normal := Vector3.ZERO
		#
		#for f in vertex_faces[v]:
			#if not unique_normals.has(face_normals[f]):
				#vertex_normal += face_normals[f]
				#unique_normals.append(vertex_normal)
		#
		#vertex_normals[v] = vertex_normal.normalized()
	#
	## Set normals as vertex colors
	#var new_mesh := ArrayMesh.new()
	#for s in range(mesh_inst.mesh.get_surface_count()):
		#
		#var data_arrays := mesh_inst.mesh.surface_get_arrays(s)
		#var material := mesh_inst.mesh.surface_get_material(s)
		#
		#var vertices := data_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		#var colors := PackedColorArray()
		#for surface_vertex in vertices:
			#var unique_index := 0
			#for unique_vertex in unique_vertices:
				#if Utilities.cmp_vectors(surface_vertex, unique_vertex, PRECISION):
					#break
				#else:
					#unique_index += 1
			#
			#if unique_index >= unique_vertices.size():
				#push_error("Vertex not found: ", surface_vertex)
				#return ERR_BUG
			#
			#var normal := vertex_normals[unique_index]
			#var normal_color := Color(normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5, 1.0)
			#colors.append(normal_color)
		#
		#data_arrays[Mesh.ARRAY_COLOR] = colors
		#new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data_arrays)
		#
		#if material:
			##material.next_pass = outline_mat
			#new_mesh.surface_set_material(s, material)
		##mesh_inst.set_surface_override_material(s, material)
		#
	#
	#mesh_inst.mesh = new_mesh
	#mesh_inst.material_overlay = OUTLINE_MATERIAL.duplicate()
	#
	#return OK
#


func _set_size(new_size : float) -> void:
	pass


#func set_highlight_visibility(enabled : bool) -> void:
	#if enabled:
		#highlight_material.albedo_color = Color(highlight_color, 0.1)
		#$barrel.material_overlay = highlight_material
	#else:
		#$barrel.material_overlay = null
#
#func set_select_visibility(enabled : bool) -> void:
	#if enabled:
		#highlight_material.albedo_color = Color(select_color, 0.1)
		#$barrel.material_overlay = highlight_material
	#else:
		#$barrel.material_overlay = null
		
