extends CharacterBody3D

@export var movement_speed := 5.0
@export var jump_velocity := 4.5
@export var camera_sensitivity := 0.01

@onready var camera := $Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			camera.rotation.x = clamp(camera.rotation.x - event.relative.y*camera_sensitivity, -PI/2, PI/2)
			rotation.y += -event.relative.x*camera_sensitivity
	
	
## Drag and drop
#func _input(event: InputEvent) -> void:
	#var intersect = get_mouse_intersect(event.position)
	#
	#if event is InputEventMouse:
		#if intersect: mouse_position = intersect.position
	#
	#if event is InputEventMouseButton:
		#var left_button_pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
		#var left_button_released = event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
		#
		#if left_button_released:
			#dragging = false
			#drag_and_drop(intersect)
		#elif left_button_pressed:
			#dragging = true
			#drag_and_drop(intersect)


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



# Drag and drop code:
var dragging_collider
var mouse_position
var dragging := false

func _process(delta: float) -> void:
	if dragging_collider:
		dragging_collider.global_position = mouse_position

func drag_and_drop(intersect : Dictionary) -> void:
	if not dragging_collider and dragging:
		dragging_collider = intersect.collider
		dragging_collider.set_collision_layer(false)
	elif dragging_collider:
		dragging_collider.set_collision_layer(true)
		dragging_collider = null
		

func get_mouse_intersect(mouse_pos) -> Dictionary:
	var current_camera := get_viewport().get_camera_3d()
	var params := PhysicsRayQueryParameters3D.new()
	params.from = current_camera.project_ray_origin(mouse_pos)
	params.to = current_camera.project_position(mouse_pos, 1000)
	
	var world_space := get_world_3d().direct_space_state
	return world_space.intersect_ray(params)
