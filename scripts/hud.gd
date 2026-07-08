extends CanvasLayer

@onready var round_label: Label = $GridContainer/RoundLabel
@onready var score_label: Label = $GridContainer/ScoreLabel
@onready var solvable_toggle: Button = $GridContainer/SolvableToggle

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

func _on_solvable_toggled() -> void:
	GameManager.ensure_solvable = !GameManager.ensure_solvable
	solvable_toggle.text = "Solvable: ON" if GameManager.ensure_solvable else "Solvable: OFF"
