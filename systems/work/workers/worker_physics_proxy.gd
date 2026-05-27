extends PhysicalItemBody
class_name WorkerPhysicsProxy

signal proxy_sleep_ready(proxy: WorkerPhysicsProxy)

@export var sleep_speed_threshold: float = 12.0
@export var sleep_time_required: float = 0.35

var worker: Worker = null
var _sleep_timer: float = 0.0


func setup_from_worker(source_worker: Worker, initial_velocity: Vector2 = Vector2.ZERO) -> void:
	worker = source_worker

	if worker != null:
		global_position = worker.global_position
		rotation = worker.rotation

	linear_velocity = initial_velocity
	angular_velocity = 0.0
	freeze = false
	show()


func _physics_process(delta: float) -> void:
	if linear_velocity.length() <= sleep_speed_threshold:
		_sleep_timer += delta
	else:
		_sleep_timer = 0.0

	if _sleep_timer >= sleep_time_required:
		proxy_sleep_ready.emit(self)
