class_name Player extends CharacterBody3D

enum SELECT_STATE {
	## When this player instance is not interacting with props (not authority or player is in gui).
	NULL,
	SINGLE_SELECT,
	RECTANGLE_SELECT,
	DRAGGING,
}

@export var movement_speed := 5.0
@export var jump_velocity := 4.5
@export var camera_sensitivity := 0.005
@export var reach : float = 15.0
@export var drop_velocity_dampening := 0.15

@export var player_color : Color

@onready var camera : Camera3D = $Camera3D
@onready var selection_rectangle : NinePatchRect = $Camera3D/CanvasLayer/SelectionRectangle
@onready var selection_frustrum : Area3D = $Camera3D/SelectionFrustum

var peer_id : int : 
	get: return get_multiplayer_authority()

var space_state : PhysicsDirectSpaceState3D : 
	get: return get_world_3d().direct_space_state

var _select_state : SELECT_STATE = SELECT_STATE.NULL

var mouse_2d_position : Vector2
#var mouse_3d_position : Vector3

var selected := {}
#var mouse_3d_last_position : Vector3
var drag_velocity := Vector3.ZERO
var mouse_collider_intersect : CollisionObject3D 

var selection_rectangle_start : Vector2
var props_inside_rectangle := {}


#region Multiplayer Config
func _enter_tree() -> void:
	# Register player in MultiplayerController
	if multiplayer.get_unique_id() == peer_id:
		assert(MultiplayerController.local_player == null, \
				"Two player instences of local authority")
		
		MultiplayerController.local_player = self
	
	MultiplayerController.player_instances[peer_id] = self

func _ready() -> void:
	# Set camera
	if peer_id == multiplayer.get_unique_id():
		camera.make_current()
		_select_state = SELECT_STATE.SINGLE_SELECT

func _exit_tree() -> void:
	# Unregister player in MultiplayerController
	if MultiplayerController.local_player == self:
		MultiplayerController.local_player = null
	
	MultiplayerController.player_instances.erase(peer_id)
#endregion

func _unhandled_input(event: InputEvent) -> void:
	
	if not is_multiplayer_authority() or _select_state == SELECT_STATE.NULL: 
		return
	
	if _select_state == SELECT_STATE.NULL: return
	
	if event is InputEventMouseMotion:
		
		mouse_2d_position = event.position
		
		match _select_state:
			SELECT_STATE.SINGLE_SELECT:
				
				var time_seconds := Time.get_ticks_usec() / 1000000
		
				# Move camera in captured mode
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					camera.rotation.x = clamp(camera.rotation.x - event.relative.y*camera_sensitivity, -PI/2, PI/2)
					rotation.y += -event.relative.x*camera_sensitivity
				
				var mouse_ray_end := camera.project_position(mouse_2d_position, reach)
				var params := PhysicsRayQueryParameters3D.new()
				params.from = camera.project_ray_origin(mouse_2d_position)
				params.to = mouse_ray_end
				
				var intersect := space_state.intersect_ray(params)
				var new_collider : CollisionObject3D
				
				if intersect:
					#mouse_3d_position = intersect.position
					new_collider = intersect.collider
				else:
					#mouse_3d_position = mouse_ray_end
					new_collider = null
				
				# Set intersect hover
				if mouse_collider_intersect != new_collider:
					if mouse_collider_intersect is Prop:
						mouse_collider_intersect.set_mouse_hover(false)
					if new_collider is Prop:
						new_collider.set_mouse_hover(true)
				
				mouse_collider_intersect = new_collider
			
			SELECT_STATE.RECTANGLE_SELECT:
				_update_rect_select()
				
				
	elif event is InputEventMouseButton:
		var left_button_pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
		var left_button_released = event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	
		match _select_state:
			SELECT_STATE.SINGLE_SELECT:
				
				if left_button_pressed:
					var multi_select := Input.is_action_pressed("multi-select")
					
					if mouse_collider_intersect is Prop: ## Add more for in world buttons and stuff
						if not multi_select and mouse_collider_intersect.selecting_peer == 0:
							deselect_all()
						select(mouse_collider_intersect)
						_init_drag()
					else:
						if not multi_select:
							deselect_all()
						_init_rect_select()
					return
					
			SELECT_STATE.RECTANGLE_SELECT:
				if left_button_released:
					_select_rect()
					return
			
			SELECT_STATE.DRAGGING:
				if left_button_released:
					_drop()
					return

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("toggle_mouse_capture"):
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.is_action_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Move player
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0, movement_speed)
		velocity.z = move_toward(velocity.z, 0, movement_speed)

	move_and_slide()
	
	if _select_state == SELECT_STATE.DRAGGING:
		_drag_selected()
		#mouse_3d_last_position = mouse_3d_position
		
func select(prop : Prop) -> bool:
	
	assert(multiplayer.get_unique_id() == peer_id, \
	"Player instance of remote authority calling select_prop().")
	
	if not is_instance_valid(prop):
		return false
	
	if prop.selecting_peer != 0:
		return false
	
	prop.selecting_peer = peer_id
	selected[prop] = Vector3.ZERO
	
	return true


func deselect(prop : Prop) -> void:
	
	if not is_instance_valid(prop):
		return
	
	if prop.selecting_peer != peer_id:
		return
	
	prop.selecting_peer = 0
	selected.erase(prop)

func deselect_all() -> void:
	for prop in selected.keys():
		deselect(prop)

func _init_rect_select() -> void:
	selection_rectangle_start = mouse_2d_position
	_select_state = SELECT_STATE.RECTANGLE_SELECT

func _update_rect_select() -> void:
	var t : float = min(selection_rectangle_start.y, mouse_2d_position.y)
	var b : float = max(selection_rectangle_start.y, mouse_2d_position.y)
	var l : float = min(selection_rectangle_start.x, mouse_2d_position.x)
	var r : float = max(selection_rectangle_start.x, mouse_2d_position.x)
	
	selection_rectangle.position = Vector2(l, t)
	selection_rectangle.size = Vector2(r - l, b - t)
	
	selection_rectangle.visible = true 
	selection_frustrum.monitoring = true
	
	# Set selection frustrum shape
	$Camera3D/SelectionFrustum/CollisionShape3D.shape.points = [
			Vector3.ZERO,
			camera.project_local_ray_normal(Vector2(l, t)) * reach,
			camera.project_local_ray_normal(Vector2(r, t)) * reach,
			camera.project_local_ray_normal(Vector2(r, b)) * reach,
			camera.project_local_ray_normal(Vector2(l, b)) * reach,
		]

func _select_rect() -> void:
	selection_rectangle.hide()
	for prop in props_inside_rectangle.keys():
		select(prop)
		#props_inside_rectangle.erase(prop)
	selection_frustrum.monitoring = false
	_select_state = SELECT_STATE.SINGLE_SELECT

func _init_drag() -> void:
	_select_state = SELECT_STATE.DRAGGING
	for prop in selected:
		if prop is Prop:
			selected[prop] = prop.position - mouse_collider_intersect.global_position
			prop.lock_rotation = true

func _drag_selected() -> void:
	#drag_velocity = (mouse_3d_position - mouse_3d_last_position) / delta
	# TODO: Calculate velocity for when the objects are dropped.
	
	# Get drag position
	var psqp := PhysicsShapeQueryParameters3D.new()
	var drag_dist := reach * 0.75
	psqp.motion = camera.project_position(mouse_2d_position, drag_dist) \
			- camera.project_ray_origin(mouse_2d_position)
	
	var exclude_rids : Array[RID] = [self.get_rid()]
	for prop in selected:
		if prop is Prop:
			exclude_rids.append(prop.get_rid())
	psqp.exclude = exclude_rids
	
	var max_dist_fract := 1.0
	for prop in selected:
		for child in prop.get_children():
			if child is CollisionShape3D:
				psqp.shape = child.shape
				psqp.transform = Transform3D(child.global_basis, camera.global_position)
				
				var cast_safe := space_state.cast_motion(psqp)[0] as float
				if cast_safe < max_dist_fract:
					max_dist_fract = cast_safe
	drag_dist *= max_dist_fract
	var drag_origin_3d := camera.project_position(mouse_2d_position, drag_dist)
	
	# TODO: put gap between props and colliding body
	
	# Move objects
	for prop in selected:
		prop.position = drag_origin_3d + selected[prop]

func _drop() -> void:
	_select_state = SELECT_STATE.SINGLE_SELECT
	for prop in selected:
		if prop is Prop:
			selected[prop] = Vector3.ZERO
			prop.lock_rotation = false
			prop.linear_velocity = drag_velocity * drop_velocity_dampening

func _on_selection_frustum_body_entered(body: Node3D) -> void:
	if body is Prop:
		body.set_mouse_hover(true)
		props_inside_rectangle[body] = null

func _on_selection_frustum_body_exited(body: Node3D) -> void:
	if body is Prop:
		body.set_mouse_hover(false)
		props_inside_rectangle.erase(body)
