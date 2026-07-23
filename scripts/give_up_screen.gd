extends CanvasLayer

func _ready() -> void:
	hide()
	GameManager.game_given_up.connect(_on_game_given_up)

func _on_game_given_up(solvable: bool, _steps: Array) -> void:
	if solvable:
		return  # main.gd handles solvable case with card animation
	# Slide the banner up from the bottom
	$Banner.position.y = $Banner.size.y
	show()
	var tween := create_tween()
	tween.tween_property($Banner, "position:y", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _on_next_round_pressed() -> void:
	hide()
	GameManager.deal_new_round()
