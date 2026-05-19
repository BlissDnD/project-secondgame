extends RefCounted
class_name DialogueRuntimeNode

var node_id: StringName = &""
var speaker_name: String = ""
var lines: Array[String] = []
var choices: Array[DialogueRuntimeChoice] = []
var next_node_id: StringName = &""
var ends_dialogue: bool = false
