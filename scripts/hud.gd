extends CanvasLayer

@onready var round_label: Label = $GridContainer/RoundLabel
@onready var score_label: Label = $GridContainer/ScoreLabel
@onready var solvable_toggle: Button = $GridContainer/SolvableToggle
@onready var give_up_button: Button = $GiveUpButton

func _ready() -> void:
	GameManager.round_started.connect(_on_round_started)
	GameManager.game_won.connect(_on_score_changed)
	GameManager.game_given_up.connect(_on_game_given_up)

func _on_round_started(_cards: Array) -> void:
	round_label.text = "                       Round: %d" % GameManager.round
	score_label.text = "Score: %d" % GameManager.score
	give_up_button.disabled = false

func _on_score_changed() -> void:
	score_label.text = "Score: %d" % GameManager.score

func _on_game_given_up(_solvable: bool, _solution: String) -> void:
	score_label.text = "Score: %d" % GameManager.score
	give_up_button.disabled = true

func _on_new_deal_pressed() -> void:
	GameManager.deal_new_round(false)

func _on_solvable_toggled() -> void:
	GameManager.ensure_solvable = !GameManager.ensure_solvable
	solvable_toggle.text = "Solvable: ON" if GameManager.ensure_solvable else "Solvable: OFF"

func _on_give_up_pressed() -> void:
	GameManager.give_up()
