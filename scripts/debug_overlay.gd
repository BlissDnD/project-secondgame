extends CanvasLayer

@export var label: RichTextLabel

var lines: Array[String] = []
var max_lines: int = 20

# Path to Godot's internal log file
var log_file_path: String = "user://logs/godot.log"
var file: FileAccess
var last_position: int = 0

func _ready() -> void:
	visible = true
	
	# Connect your existing custom logger just in case
	if LoggerConsole.has_signal("message_logged"):
		LoggerConsole.message_logged.connect(_on_message_logged)
	
	# Open Godot's native log file to read standard prints
	if FileAccess.file_exists(log_file_path):
		file = FileAccess.open(log_file_path, FileAccess.READ)
		if file:
			# Skip to the end of the current log so we only get NEW prints
			last_position = file.get_length()
	else:
		push_error("Engine logging is not enabled in Project Settings!")


func _process(_delta: float) -> void:
	# Periodically check if Godot wrote anything new to the terminal log
	if file:
		file.seek(last_position)
		while file.get_position() < file.get_length():
			var line = file.get_line()
			if line.strip_edges() != "":
				_on_message_logged(line)
		last_position = file.get_position()


func _on_message_logged(message: String) -> void:
	lines.append(message)

	if lines.size() > max_lines:
		lines.pop_front()

	if label:
		label.clear()
		for line in lines:
			label.append_text(line + "\n")
