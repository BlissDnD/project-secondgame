extends Node

signal message_logged(message: String)

func log(message: String) -> void:
	print(message)
	message_logged.emit(message)
