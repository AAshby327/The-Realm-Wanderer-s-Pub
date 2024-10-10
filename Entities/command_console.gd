extends Window

const MAX_ARGS := 16


@export var target : Node :
	set(value):
		target = value
		$CanvasLayer/Panel/VSplitContainer/HBoxContainer/Target.text = str(target.get_path()) + ">"


@onready var text_box := $CanvasLayer/Panel/VSplitContainer/RichTextLabel as RichTextLabel

@onready var command_line := $CanvasLayer/Panel/VSplitContainer/HBoxContainer/LineEdit as LineEdit

func new_line(count := 1) -> void:
	if count <= 0: return
	
	var text := ""
	for c in range(count):
		text += "\n"
	
	text_box.text += text

func print_line(text : String) -> void:
	text_box.text += text + "\n"

func back_line(count := 1) -> void:
	
	if count <= 0: return
	
	var lines = text_box.text.split("\n")
	
	text_box.text = "\n".join(lines.slice(0, -count))

func clear() -> void:
	text_box.text = ""


func _ready() -> void:
	target = self


func _on_focus_entered() -> void:	
	if command_line:
		if not command_line.has_focus():
			command_line.set_caret_column(command_line.text.length())
			command_line.grab_focus()


func _on_line_edit_text_submitted(new_text: String) -> void:
	
	print_line($CanvasLayer/Panel/VSplitContainer/HBoxContainer/Target.text + " " + new_text)
	command_line.clear()
	
	var args := new_text.split(" ", false, MAX_ARGS)
	args.resize(MAX_ARGS)
	
	match args[0].to_lower():
		"help", "h":
			print_line("Help string.")
		
		"ct":
			if args[1].is_relative_path() or args[1].is_absolute_path():
				target = target.get_node(args[1])
			else:
				print_line("Invalid path.")
		
		"lc":
			var include_internal := args[1].to_lower() == "t" or args[1].to_lower() == "true"
			
			print_line("\nChildren of " + target.name + ":\n")
			
			for child in target.get_children(include_internal):
				print_line("\t" + child.name + "  [" + child.get_class() + "]")
			
			new_line()
		
		"clear", "cl":
			clear()
		
		"lp":
			print_line("\nProperties of " + target.name + ":\n")
			for p in target.get_property_list():
				var type := type_string(p.type)
				if p.type == TYPE_OBJECT:
					type = p.class_name
				print_line("\t" + p.name + "\t[" + type + "]")
			new_line()
		
		"lm":
			print_line("\nMethods of " + target.name + ":\n")
			for m in target.get_method_list():
				print_line("\t" + m.name)
			new_line()
		
		"call", "c":
			if target.has_method(args[1]):
				target.call(args[1])
			else:
				print_line("Method not recognized.")
		
		_:
			print_line("Command \"%s\" not recognized.\n" % args[0])
