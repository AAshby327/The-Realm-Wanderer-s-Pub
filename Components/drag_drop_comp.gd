@tool class_name DragDropComp extends Area3D

@export var highlight_comp : HighlightComp
@export var highlight_color := Color.WHITE

var body : RigidBody3D
var selecting_peer := 0 :
	set(value):
		selecting_peer = value
		
		_set_highlight_to_selecting_peer()

func set_highlight(highlight_visible := true) -> void:
	if not highlight_comp: return
	
	if not highlight_visible:
		_set_highlight_to_selecting_peer()
		return
	
	highlight_comp.set_color(highlight_color)
	highlight_comp.show()

func _set_highlight_to_selecting_peer() -> void:
	if not highlight_comp: return
	
	if selecting_peer == 0:
		highlight_comp.hide()
	else:
		var player := MultiplayerController.player_instances[selecting_peer] as Player
		if player:
			highlight_comp.set_color(player.player_color)
			highlight_comp.show()
		else:
			highlight_comp.hide()

#region Config
func _enter_tree() -> void:
	if not body:
		var parent := get_parent()
		if parent is RigidBody3D:
			body = parent

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not body:
		warnings.append("This drag and drop component has no parent physics body.")
		
	return warnings
#endregion
