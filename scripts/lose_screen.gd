extends CanvasLayer

func _ready() -> void:
	hide()
	GameManager.game_lost.connect(_show_lose)

func _show_lose() -> void:
	show()

func _on_new_deal_pressed() -> void:
	hide()
	GameManager.deal_new_round()
