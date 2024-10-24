class_name Player extends CharacterBody3D

@export var movement_speed := 5.0
@export var jump_velocity := 4.5
@export var camera_sensitivity := 0.005
@export var reach : float = 15.0
@export var drop_velocity_dampening := 0.15

@export var player_color : Color

@onready var camera : Camera3D = $Camera3D

var peer_id : int : 
	get: return get_multiplayer_authority()

var selected := {}

var mouse_2d_position : Vector2
var mouse_3d_position : Vector3

var mouse_collider_intersect : CollisionObject3D :
	set(new_collider):
		
		if new_collider == mouse_collider_intersect: return
		
		# Remove highlight
		if mouse_collider_intersect is DragDropComp:
			mouse_collider_intersect.set_highlight(false)
		
		# Add highlight
		if new_collider is DragDropComp and new_collider.selecting_peer == 0:
			new_collider.set_highlight(true)
		
		mouse_collider_intersect = new_collider

var dragging := false
var mouse_3d_last_position : Vector3
var drag_velocity := Vector3.ZERO


func _enter_tree() -> void:
	if multiplayer.get_unique_id() == peer_id:
		
		assert(MultiplayerController.local_player == null, "Two player instences of local authority")
		
		MultiplayerController.local_player = self
		#camera.make_current()
	
	MultiplayerController.player_instances[peer_id] = self

func _exit_tree() -> void:
	if MultiplayerController.local_player == self:
		MultiplayerController.local_player = null
	
	MultiplayerController.player_instances.erase(peer_id)

func _unhandled_input(event: InputEvent) -> void:
	
	if not is_multiplayer_authority(): return
		
	if event is InputEventMouseMotion:
		
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			camera.rotation.x = clamp(camera.rotation.x - event.relative.y*camera_sensitivity, -PI/2, PI/2)
			rotation.y += -event.relative.x*camera_sensitivity
		
		mouse_2d_position = event.position
		var mouse_ray_end := camera.project_position(mouse_2d_position, reach)
		
		var params := PhysicsRayQueryParameters3D.new()
		params.collide_with_areas = not dragging
		params.from = camera.project_ray_origin(mouse_2d_position)
		params.to = mouse_ray_end
		
		var intersect := get_world_3d().direct_space_state.intersect_ray(params)
		
		if intersect:
			mouse_3d_position = intersect.position
			
			mouse_collider_intersect = intersect.collider
			
		else:
			mouse_3d_position = mouse_ray_end
			mouse_collider_intersect = null
	
	if event is InputEventMouseButton:
		#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		var left_button_pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
		var left_button_released = event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
		
		if left_button_pressed:			
			var multi_select := Input.is_action_pressed("multi-select")
			
			if mouse_collider_intersect is DragDropComp:
		
				if mouse_collider_intersect.selecting_peer == 0:
					if not multi_select:
						deselect_all()
					select(mouse_collider_intersect)
					
					drag(mouse_collider_intersect.body.global_position)
			else:
				# Rectangle select here
				if not multi_select:
					deselect_all()
		
		elif left_button_released and dragging:
			drop()
			


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		
		if event.is_action_pressed("toggle_mouse_capture") or event.is_action_pressed("ui_cancel"):
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0, movement_speed)
		velocity.z = move_toward(velocity.z, 0, movement_speed)

	move_and_slide()
	
	
	# Drag selected objects
	if dragging:
		
		drag_velocity = (mouse_3d_position - mouse_3d_last_position) / delta
		
		# Get drag position
		var params := PhysicsShapeQueryParameters3D.new()
		var drag_dist := reach * 0.75
		params.motion = camera.project_position(mouse_2d_position, drag_dist) - camera.project_ray_origin(mouse_2d_position)
		var exclude_rids : Array[RID] = [self.get_rid()]
		params.margin = 0.01
		
		for drag_drop in selected:
			if drag_drop is DragDropComp:
				exclude_rids.append(drag_drop.body.get_rid())
		
		params.exclude = exclude_rids
		
		var iter := 0
		
		var max_dist_fract := 1.0
		for drag_drop in selected:
			for child in drag_drop.body.get_children():
				if child is CollisionShape3D:
					params.shape = child.shape
					
					params.transform = Transform3D(child.global_basis, camera.global_position)
					
					var cast_safe := get_world_3d().direct_space_state.cast_motion(params)[0] as float
					if cast_safe < max_dist_fract:
						max_dist_fract = cast_safe
					
					if iter % 37 == 0:
						print(get_world_3d().direct_space_state.intersect_shape(params))
						print(child.global_position - child.global_position.normalized() * cast_safe)
						prints(params.transform.origin - camera.global_position)
		
		#print(max_dist_fract)
		drag_dist *= max_dist_fract
		var drag_origin_3d := camera.project_position(mouse_2d_position, drag_dist)
		
		# Move objects
		for drag_drop in selected:
			drag_drop.body.position = drag_origin_3d + selected[drag_drop]
	
	mouse_3d_last_position = mouse_3d_position


func select(drag_drop : DragDropComp) -> bool:
	
	assert(multiplayer.get_unique_id() == peer_id, \
	"Player instance of remote authority calling select_prop().")
	
	if not is_instance_valid(drag_drop):
		return false
	
	if drag_drop.selecting_peer != 0:
		return false
	
	drag_drop.selecting_peer = peer_id
	selected[drag_drop] = Vector3.ZERO
	
	return true


func deselect(drag_drop : DragDropComp) -> void:
	
	if not is_instance_valid(drag_drop):
		return
	
	if drag_drop.selecting_peer != peer_id:
		return
	
	drag_drop.selecting_peer = 0
	selected.erase(drag_drop)

func deselect_all() -> void:
	for drag_drop in selected.keys():
		deselect(drag_drop)

func drag(mouse_origin : Vector3) -> void:
	dragging = true
	
	for drag_drop in selected:
		if drag_drop is DragDropComp:
			selected[drag_drop] = drag_drop.body.position - mouse_origin
			#drag_drop.body.sleeping = true
			drag_drop.body.lock_rotation = true

func drop() -> void:
	dragging = false
	for drag_drop in selected:
		if drag_drop is DragDropComp:
			selected[drag_drop] = Vector3.ZERO
			#drag_drop.body.sleeping = false
			drag_drop.body.lock_rotation = false
			drag_drop.body.linear_velocity = drag_velocity * drop_velocity_dampening
