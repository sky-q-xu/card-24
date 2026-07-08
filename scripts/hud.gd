extends CanvasLayer

@onready var round_label: Label = $GridContainer/RoundLabel
@onready var score_label: Label = $GridContainer/ScoreLabel
@onready var solvable_toggle: CheckButton = $GridContainer/SolvableToggle

func _ready() -> void:
	GameManager.round_started.connect(_on_round_started)
	GameManager.game_won.connect(_on_game_won)

func _on_round_started(_cards: Array) -> void:
	round_label.text = "Round: %d" % GameManager.round
	score_label.text = "Score: %d" % GameManager.score

func _on_game_won() -> void:
	score_label.text = "Score: %d" % GameManager.score

func _on_new_deal_pressed() -> void:
	GameManager.deal_new_round(false)

func _on_solvable_toggled(pressed: bool) -> void:
	GameManager.ensure_solvable = pressed
	solvable_toggle.text = "Solvable: ON" if pressed else "Solvable: OFF"
