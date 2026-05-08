extends Node2D

enum GameState {
	WAITING,
	COUNTDOWN,
	PLAYING,
	GAME_OVER
}

@export var countdown_duration: float = 3.0

@export var tile_size: Vector2 = Vector2(8, 8)
@export var arena_tiles: Vector2i = Vector2i(20, 20)

@export var camera_padding: float = 12.0
@export var max_camera_zoom: float = 3.0

@onready var player = $Player
@onready var start_label: Label = $UI/StartLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_camera: Camera2D = $GameCamera
@onready var arena_tiles_layer: TileMapLayer = $ArenaTiles

var game_state: GameState = GameState.WAITING
var countdown_left: float = 0.0
var arena_rect: Rect2


func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	game_camera.enabled = true

	_update_arena_rect()

	player.crashed_into_self.connect(_on_player_crashed_into_self)
	_apply_arena_to_player()

	_reset_player_position()
	player.reset_for_new_round()

	start_label.visible = true
	start_label.text = "Click or Press Space to Start"

	score_label.visible = true
	_update_score_label()


func _process(delta: float) -> void:
	if game_state == GameState.COUNTDOWN:
		countdown_left -= delta

		if countdown_left > 0.0:
			start_label.text = str(ceili(countdown_left))
		else:
			_start_playing()

	if game_state == GameState.PLAYING:
		_update_score_label()


func _unhandled_input(event: InputEvent) -> void:
	if _is_start_input(event):
		if game_state == GameState.WAITING:
			_start_countdown()
		elif game_state == GameState.GAME_OVER:
			_start_countdown()


func _is_start_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	if event is InputEventKey:
		return event.pressed and event.keycode == KEY_SPACE

	return false


func _start_countdown() -> void:
	game_state = GameState.COUNTDOWN
	countdown_left = countdown_duration

	_update_arena_rect()
	_apply_arena_to_player()

	_reset_player_position()
	player.reset_for_new_round()
	player.set_active(false)

	_update_score_label()

	start_label.visible = true
	start_label.text = str(ceili(countdown_left))


func _start_playing() -> void:
	game_state = GameState.PLAYING

	player.reset_for_new_round()
	player.set_active(true)

	_update_score_label()

	start_label.visible = false


func _on_player_crashed_into_self() -> void:
	game_state = GameState.GAME_OVER

	_update_score_label()

	start_label.visible = true
	start_label.text = "Game Over\nScore: " + str(player.get_score()) + "\nClick or Press Space to Restart"


func _update_score_label() -> void:
	score_label.text = "Score: " + str(player.get_score())


func _update_arena_rect() -> void:
	var arena_pixel_size: Vector2 = Vector2(
		arena_tiles.x * tile_size.x,
		arena_tiles.y * tile_size.y
	)

	var arena_position: Vector2 = -arena_pixel_size * 0.5
	arena_rect = Rect2(arena_position, arena_pixel_size)

	arena_tiles_layer.position = Vector2.ZERO

	_update_camera()
	queue_redraw()


func _update_camera() -> void:
	game_camera.global_position = Vector2.ZERO

	var viewport_size: Vector2 = get_viewport_rect().size
	var padded_arena_size: Vector2 = arena_rect.size + Vector2(camera_padding, camera_padding) * 2.0

	var zoom_x: float = viewport_size.x / padded_arena_size.x
	var zoom_y: float = viewport_size.y / padded_arena_size.y
	var target_zoom: float = min(zoom_x, zoom_y)

	target_zoom = clamp(target_zoom, 1.0, max_camera_zoom)

	game_camera.zoom = Vector2(target_zoom, target_zoom)


func _apply_arena_to_player() -> void:
	player.play_area = arena_rect


func _reset_player_position() -> void:
	player.global_position = Vector2.ZERO


func _on_viewport_size_changed() -> void:
	_update_arena_rect()
	_apply_arena_to_player()

	if game_state != GameState.PLAYING:
		_reset_player_position()
		player.reset_for_new_round()
		_update_score_label()


func _draw() -> void:
	draw_rect(arena_rect, Color("328c34ff"), true)
	draw_rect(arena_rect, Color(0.196, 0.549, 0.204, 1.0), false, 2.0)
