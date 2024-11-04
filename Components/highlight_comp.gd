class_name HighlightComp extends Node

@export var highlight_color := Color.WHITE

var hovering := false
var selected := false

func set_color(color : Color) -> void:
	pass

func set_visibility(visible : bool) -> void:
	pass

func _on_mouse_hover(enabled : bool) -> void:
	
	hovering = enabled
	
	if selected: return
	
	set_color(highlight_color)
	set_visibility(enabled)

func _on_selected(peer_id : int) -> void:
	selected = true
	
	set_color(MultiplayerController.player_instances[peer_id].player_color)
	set_visibility(true)

func _on_deselected(_peer_id : int) -> void:
	selected = false
	
	set_visibility(hovering)
	if hovering:
		set_color(highlight_color)

#region Config
func _enter_tree() -> void:
	var parent := get_parent()
	if parent is Prop:
		parent.mouse_hover.connect(_on_mouse_hover)
		parent.selected.connect(_on_selected)
		parent.deselected.connect(_on_deselected)

func _exit_tree() -> void:
	var parent := get_parent()
	if parent is Prop:
		parent.mouse_hover.disconnect(_on_mouse_hover)
		parent.selected.disconnect(_on_selected)
		parent.deselected.disconnect(_on_deselected)
#endregion
