class_name Player extends CharacterBody3D

@export var movement_speed := 5.0
@export var jump_velocity := 4.5
@export var camera_sensitivity := 0.005
@export var reach := 7.5
@export var drop_velocity_dampening := 0.2

var peer_id : int : 
	get:
		return get_multiplayer_authority()

var selected_props := {}

var mouse_3d_position : Vector3
var mouse_collider_intersect : CollisionObject3D

var dragging := false
var mouse_3d_last_position : Vector3
var drag_velocity := Vector3.ZERO



#var drag_item : DragDropComp = null

@onready var camera := $Camera3D

func _enter_tree() -> void:
	if multiplayer.get_unique_id() == peer_id:
		
		assert(MultiplayerController.local_player == null, "Two player instences of local authority")
		
		MultiplayerController.local_player = self

func _exit_tree() -> void:
	if MultiplayerController.local_player == self:
		MultiplayerController.local_player = null

func _unhandled_input(event: InputEvent) -> void:
		
	if event is InputEventMouseMotion:
		
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			camera.rotation.x = clamp(camera.rotation.x - event.relative.y*camera_sensitivity, -PI/2, PI/2)
			rotation.y += -event.relative.x*camera_sensitivity
		
		var current_camera := get_viewport().get_camera_3d()
		var params := PhysicsRayQueryParameters3D.new()
		params.from = current_camera.project_ray_origin(event.position)
		var mouse_ray_end := current_camera.project_position(event.position, reach)
		params.to = mouse_ray_end
		
		var intersect := get_world_3d().direct_space_state.intersect_ray(params)
		
		
		if intersect:
			mouse_3d_position = intersect.position
			mouse_collider_intersect = intersect.collider
			
			# highlight prop
		
		else:
			mouse_3d_position = mouse_ray_end
			mouse_collider_intersect = null

	
	if event is InputEventMouseButton:
		#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		var left_button_pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
		var left_button_released = event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
		
		if left_button_pressed:			
			var multi_select := Input.is_action_pressed("multi-select")
			
			if mouse_collider_intersect is Prop:
		
				if mouse_collider_intersect.selecting_peer == 0:
					if not multi_select:
						deselect_all_props()
					select_prop(mouse_collider_intersect)
				
				drag()
			else:
				# Rectangle select here
				if not multi_select:
					deselect_all_props()
		
		elif left_button_released and dragging:
			drop()
			

	#elif event.is_action_pressed("ui_cancel"):
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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
		
		for prop in selected_props:
			prop.position = mouse_3d_position + selected_props[prop]
	
	mouse_3d_last_position = mouse_3d_position


func select_prop(prop : Prop) -> bool:
	
	assert(multiplayer.get_unique_id() == peer_id, \
	"Player instance of remote authority calling select_prop().")
	
	if not is_instance_valid(prop):
		return false
	
	if prop.selecting_peer != 0:
		return false
	
	prop.selecting_peer = peer_id
	prop.set_select_visibility(true)
	selected_props[prop] = Vector3.ZERO
	
	return true


func deselect_prop(prop : Prop) -> void:
	
	if not is_instance_valid(prop):
		return
	
	if prop.selecting_peer != peer_id:
		return
	
	prop.selecting_peer = 0
	prop.set_select_visibility(false)
	selected_props.erase(prop)

func deselect_all_props() -> void:
	for prop in selected_props.keys():
		deselect_prop(prop)

func drag() -> void:
	dragging = true
	for prop in selected_props:
		if prop is Prop:
			selected_props[prop] = prop.position - mouse_3d_position
			prop.collision_enabled = false
			prop.sleeping = true

func drop() -> void:
	dragging = false
	for prop in selected_props:
		if prop is Prop:
			selected_props[prop] = Vector3.ZERO
			prop.collision_enabled = true
			prop.sleeping = false
			prop.linear_velocity = drag_velocity * drop_velocity_dampening
