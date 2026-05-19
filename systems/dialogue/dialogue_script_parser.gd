extends RefCounted
class_name DialogueScriptParser


static func parse_file(path: String) -> Dictionary:
	if path == "":
		push_warning("DialogueScriptParser: empty script path.")
		return {}

	if not FileAccess.file_exists(path):
		push_warning("DialogueScriptParser: file does not exist: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_warning("DialogueScriptParser: failed to open file: %s" % path)
		return {}

	var text := file.get_as_text()
	return parse_text(text)


static func parse_text(text: String) -> Dictionary:
	var nodes: Dictionary = {}
	var current_node: DialogueRuntimeNode = null

	var raw_lines := text.split("\n", false)

	for raw_line in raw_lines:
		var line := raw_line.strip_edges()

		if line == "":
			continue

		if line.begins_with("#"):
			continue

		if line.begins_with("::"):
			var node_id := StringName(line.substr(2).strip_edges())

			current_node = DialogueRuntimeNode.new()
			current_node.node_id = node_id
			nodes[node_id] = current_node
			continue

		if current_node == null:
			push_warning("Dialogue line outside node: %s" % line)
			continue

		if line.begins_with("?"):
			var choice := _parse_choice(line)

			if choice != null:
				current_node.choices.append(choice)

			continue

		if line.begins_with("->"):
			var target := line.substr(2).strip_edges()

			if target == "END":
				current_node.ends_dialogue = true
			else:
				current_node.next_node_id = StringName(target)

			continue

		var speaker_split_index := line.find(":")

		if speaker_split_index >= 0:
			current_node.speaker_name = line.substr(0, speaker_split_index).strip_edges()
			current_node.lines.append(line.substr(speaker_split_index + 1).strip_edges())
		else:
			current_node.lines.append(line)

	return nodes


static func _parse_choice(line: String) -> DialogueRuntimeChoice:
	var cleaned := line.substr(1).strip_edges()
	var parts := cleaned.split("->", false)

	if parts.size() < 2:
		push_warning("Invalid dialogue choice: %s" % line)
		return null

	var choice := DialogueRuntimeChoice.new()
	choice.label = parts[0].strip_edges()

	var target := parts[1].strip_edges()

	if target == "END":
		choice.ends_dialogue = true
	else:
		choice.target_node_id = StringName(target)

	return choice
