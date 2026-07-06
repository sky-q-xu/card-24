extends CanvasLayer

func _ready() -> void:
	hide()
	GameManager.game_won.connect(_show_win)

func _show_win() -> void:
	$CenterContainer/VBoxContainer/ScoreLabel.text = "Score: %d" % GameManager.score
	show()

func _on_next_round_pressed() -> void:
	hide()
	GameManager.deal_new_round()
