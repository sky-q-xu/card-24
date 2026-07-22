extends CanvasLayer

@onready var title_label: Label = $Background/CenterContainer/VBoxContainer/TitleLabel
@onready var solution_label: Label = $Background/CenterContainer/VBoxContainer/SolutionLabel
@onready var score_label: Label = $Background/CenterContainer/VBoxContainer/ScoreLabel

func _ready() -> void:
	hide()
	GameManager.game_given_up.connect(_on_game_given_up)

func _on_game_given_up(solvable: bool, solution: String) -> void:
	if solvable:
		title_label.text = "You could have solved it!  −2 points"
		solution_label.text = solution
		solution_label.visible = true
	else:
		title_label.text = "No solution exists for this hand!"
		solution_label.visible = false
	score_label.text = "Score: %d" % GameManager.score
	$Background.modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property($Background, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)

func _on_next_round_pressed() -> void:
	hide()
	GameManager.deal_new_round()
