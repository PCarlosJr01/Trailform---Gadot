extends Area2D

signal crashed_into_self

@export var move_speed: float = 420.0
@export var stop_distance: float = 6.0
@export var head_radius: float = 10.0

@export var trail_spacing: float = 5.0
@export var collision_radius: float = 12.0
@export var safe_head_points: int = 16

@onready var trail_line: Line2D = $"../TrailLine"

var trail_points: Array[Vector2] = []
var is_game_over: bool = false
var is_active: bool = false


func _ready() -> void:
	reset_for_new_round()


func _physics_process(delta: float) -> void:
	if is_game_over or not is_active:
		return

	var mouse_position: Vector2 = get_global_mouse_position()
	var direction: Vector2 = mouse_position - global_position

	if direction.length() > stop_distance:
		global_position += direction.normalized() * move_speed * delta

	_record_trail_points(global_position)
	_update_trail_line()
	_check_self_collision()

	queue_redraw()


func set_active(active: bool) -> void:
	is_active = active


func reset_for_new_round() -> void:
	is_game_over = false
	is_active = false

	trail_points.clear()

	if trail_line != null:
		trail_line.clear_points()

	trail_points.append(global_position)
	_update_trail_line()

	queue_redraw()


func _record_trail_points(current_position: Vector2) -> void:
	if trail_points.is_empty():
		trail_points.append(current_position)
		return

	var last_point: Vector2 = trail_points[trail_points.size() - 1]
	var distance_to_current: float = last_point.distance_to(current_position)

	if distance_to_current < trail_spacing:
		return

	var direction_to_current: Vector2 = (current_position - last_point).normalized()
	var points_to_add: int = floori(distance_to_current / trail_spacing)

	for i in range(points_to_add):
		last_point += direction_to_current * trail_spacing
		trail_points.append(last_point)


func _update_trail_line() -> void:
	trail_line.clear_points()

	for point in trail_points:
		trail_line.add_point(trail_line.to_local(point))

	if trail_points.is_empty() or trail_points[trail_points.size() - 1].distance_to(global_position) > 0.5:
		trail_line.add_point(trail_line.to_local(global_position))


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
	is_active = false
	print("Game Over: head touched body")
	crashed_into_self.emit()


func _draw() -> void:
	draw_circle(Vector2.ZERO, head_radius, Color.WHITE)
