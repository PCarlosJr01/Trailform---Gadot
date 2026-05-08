extends Area2D

signal crashed_into_self

@export var move_speed: float = 420.0
@export var stop_distance: float = 6.0
@export var head_radius: float = 10.0

@export var trail_spacing: float = 8.0
@export var collision_radius: float = 12.0
@export var safe_head_points: int = 12

@onready var trail_line: Line2D = $"../TrailLine"

var trail_points: Array[Vector2] = []
var is_game_over: bool = false


func _ready() -> void:
	reset_trail()


func _physics_process(delta: float) -> void:
	if is_game_over:
		return

	var mouse_position: Vector2 = get_global_mouse_position()
	var direction: Vector2 = mouse_position - global_position

	if direction.length() > stop_distance:
		global_position += direction.normalized() * move_speed * delta

	_add_trail_point(global_position)
	_check_self_collision()

	queue_redraw()


func reset_trail() -> void:
	trail_points.clear()
	trail_points.append(global_position)

	trail_line.clear_points()
	trail_line.add_point(global_position)


func _add_trail_point(point: Vector2) -> void:
	var last_point: Vector2 = trail_points[trail_points.size() - 1]

	if last_point.distance_to(point) < trail_spacing:
		return

	trail_points.append(point)
	trail_line.add_point(point)


func _check_self_collision() -> void:
	if trail_points.size() <= safe_head_points:
		return

	var check_until_index: int = trail_points.size() - safe_head_points

	for i in range(check_until_index):
		var body_point: Vector2 = trail_points[i]

		if global_position.distance_to(body_point) <= collision_radius:
			_game_over()
			return


func _game_over() -> void:
	is_game_over = true
	print("Game Over: head touched body")
	crashed_into_self.emit()


func _draw() -> void:
	draw_circle(Vector2.ZERO, head_radius, Color.WHITE)
