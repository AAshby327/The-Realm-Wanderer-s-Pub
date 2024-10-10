@tool
class_name Toy extends Prop



#
#
#const COLLIDER_PREFIX := "model_collider_"
#
#@export var model : PackedScene :
	#set(value):
		#
		#if model != value:
			#model = value
			#_add_model()
		#
		##model = value
		##
		##if _model_scene:
			##_model_scene.free()
			##_model_scene = null
		##
		##if model and model.can_instantiate():
			##_model_scene = model.instantiate()
			##add_child(_model_scene)
			##
			##if Engine.is_editor_hint():
				##_model_scene.owner = get_tree().edited_scene_root
#
#var _model_scene : Node
#
#var _outline_meshes : Array[MeshInstance3D]
#
#
#func _set_outline_visibility(outline_visible : bool) -> void:
	#for mesh in _outline_meshes:
		#mesh.visible = outline_visible
#
#func _add_model() -> void:
	#
	## Remove old model and outlines
	#if _model_scene:
		#_model_scene.free()
		#_model_scene = null
	#_outline_meshes.clear()
	#
	## Remove old collision shapes
	#for child in get_children(true):
		#if child is CollisionShape3D:
			#child.queue_free()
	#
	#if model and model.can_instantiate():
		#_model_scene = model.instantiate()
		#
		#add_child(_model_scene)
		#
		#_add_convex_collider(_model_scene)
		#_add_outline(_model_scene)
		#
		#if Engine.is_editor_hint():
			#_model_scene.owner = get_tree().edited_scene_root
#
#func _add_outline(scene : Node) -> void:
	#
	### use https://www.youtube.com/watch?v=CG0TMH8D8kY&ab_channel=Octodemy
	#
	#
	#var new_outline_mesh : MeshInstance3D = null
	#
	#if scene is MeshInstance3D and scene.mesh:
		#new_outline_mesh = MeshInstance3D.new()
		#new_outline_mesh.mesh = scene.mesh.create_outline(outline_thickness)
		#new_outline_mesh.name = "outline_" + scene.name
		#
		#scene.add_child(new_outline_mesh)
		#
		#if Engine.is_editor_hint():
			#new_outline_mesh.owner = scene
		#
		#_outline_meshes.append(new_outline_mesh)
	#
	#for child in scene.get_children(true):
		#if child != new_outline_mesh:
			#_add_outline(child)
#
#func _add_convex_collider(scene : Node) -> void:
	#
	#if scene is MeshInstance3D and scene.mesh:
		#var new_collider := CollisionShape3D.new()
		#new_collider.shape = scene.mesh.create_convex_shape(true, true)
		#
		## Set to scale:
		#if scene.scale != Vector3.ONE:
			#var new_points := new_collider.shape.points as PackedVector3Array
			#if new_points:
				#for i in range(new_points.size()):
					#new_points[i] = new_points[i] * scene.scale
				#
				#new_collider.shape.set_points(new_points)
		#
		#new_collider.name = COLLIDER_PREFIX + scene.name
		#
		#add_child(new_collider)
		#
		#new_collider.position = scene.global_position - global_position
		#
		#if Engine.is_editor_hint():
			#new_collider.owner = get_tree().edited_scene_root
	#
	#for child in scene.get_children(true):
		#_add_convex_collider(child)
#
