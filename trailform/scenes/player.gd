extends Area2D

signal crashed_into_self

@export var move_speed: float = 420.0
@export var stop_distance: float = 6.0

@export var trail_spacing: float = 3.0
@export var collision_radius: float = 6.0
@export var safe_head_points: int = 20
@export var visual_pixel_size: float = 2.0

@export var rotate_face_to_mouse: bool = true

@onready var trail_line: Line2D = $"../TrailLine"
@onready var face_sprite: Sprite2D = $FaceSprite

var trail_points: Array[Vector2] = []
var is_game_over: bool = false
var is_active: bool = false
var play_area: Rect2 = Rect2()
var total_distance_traveled: float = 0.0


func _ready() -> void:
	_configure_trail_line()
	_configure_face_sprite()
	reset_for_new_round()


func _physics_process(delta: float) -> void:
	if is_game_over or not is_active:
		return

	var previous_position: Vector2 = global_position
	var mouse_position: Vector2 = get_global_mouse_position()

	if play_area.size != Vector2.ZERO:
		mouse_position = Vector2(
			clamp(mouse_position.x, play_area.position.x, play_area.end.x),
			clamp(mouse_position.y, play_area.position.y, play_area.end.y)
		)

	var direction: Vector2 = mouse_position - global_position

	if direction.length() > stop_distance:
		global_position += direction.normalized() * move_speed * delta

		if rotate_face_to_mouse:
			rotation = direction.angle()

	if play_area.size != Vector2.ZERO:
		global_position = Vector2(
			clamp(global_position.x, play_area.position.x, play_area.end.x),
			clamp(global_position.y, play_area.position.y, play_area.end.y)
		)

	total_distance_traveled += previous_position.distance_to(global_position)

	_record_trail_points(global_position)
	_update_trail_line()
	_check_self_collision()


func set_active(active: bool) -> void:
	is_active = active


func reset_for_new_round() -> void:
	is_game_over = false
	is_active = false
	total_distance_traveled = 0.0

	trail_points.clear()

	if trail_line != null:
		trail_line.clear_points()

	trail_points.append(global_position)
	_update_trail_line()


func get_score() -> int:
	return floori(total_distance_traveled)


func _configure_trail_line() -> void:
	if trail_line == null:
		return

	trail_line.width = 8.0
	trail_line.default_color = Color.WHITE
	trail_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	trail_line.antialiased = false
	trail_line.begin_cap_mode = Line2D.LINE_CAP_NONE
	trail_line.end_cap_mode = Line2D.LINE_CAP_NONE
	trail_line.joint_mode = Line2D.LINE_JOINT_SHARP
	trail_line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _configure_face_sprite() -> void:
	if face_sprite == null:
		return

	face_sprite.centered = true
	face_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


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
	if trail_line == null:
		return

	trail_line.clear_points()

	for point in trail_points:
		trail_line.add_point(trail_line.to_local(_snap_to_visual_pixel(point)))

	if trail_points.is_empty() or trail_points[trail_points.size() - 1].distance_to(global_position) > 0.5:
		trail_line.add_point(trail_line.to_local(_snap_to_visual_pixel(global_position)))


func _snap_to_visual_pixel(point: Vector2) -> Vector2:
	return Vector2(
		round(point.x / visual_pixel_size) * visual_pixel_size,
		round(point.y / visual_pixel_size) * visual_pixel_size
	)


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
