extends Node2D

enum GameState {
	WAITING,
	COUNTDOWN,
	PLAYING,
	GAME_OVER
}

@export var countdown_duration: float = 3.0

@onready var player = $Player
@onready var start_label: Label = $UI/StartLabel

var game_state: GameState = GameState.WAITING
var countdown_left: float = 0.0


func _ready() -> void:
	player.crashed_into_self.connect(_on_player_crashed_into_self)

	_reset_player_position()
	player.reset_for_new_round()

	start_label.visible = true
	start_label.text = "Click or Press Space to Start"


func _process(delta: float) -> void:
	if game_state == GameState.COUNTDOWN:
		countdown_left -= delta

		if countdown_left > 0.0:
			start_label.text = str(ceili(countdown_left))
		else:
			_start_playing()


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

	_reset_player_position()
	player.reset_for_new_round()
	player.set_active(false)

	start_label.visible = true
	start_label.text = str(ceili(countdown_left))


func _start_playing() -> void:
	game_state = GameState.PLAYING

	player.reset_for_new_round()
	player.set_active(true)

	start_label.visible = false


func _on_player_crashed_into_self() -> void:
	game_state = GameState.GAME_OVER

	start_label.visible = true
	start_label.text = "Game Over\nClick or Press Space to Restart"


func _reset_player_position() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	player.global_position = viewport_size * 0.5
