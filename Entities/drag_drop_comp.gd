class_name DragDropComp extends CollisionShape3D

enum PERMISSION {
	AUTHORITY,
	ANY,
}

@export var drag_drop_enabled := true

@export var permission_mode : PERMISSION = PERMISSION.ANY

var authority : int
