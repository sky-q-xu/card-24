extends Node
#signals
signal round_started(card_data: Array)
signal game_won
signal game_lost
#variables
var cards: Array = []		#will be cards dealed
var round: int = 0 #starts on round 0
var score: int = 0 #sets score at start to 0

func deal_new_round() -> void:
	cards = []		#resets hand
	for i in 4: #counts how many cards are still needed
		var v := randi_range(1, 13) #
		cards.append({
			"value": float(v),
			"display": _value_to_display(v),
			"suit": randi_range(0, 3)
		})
	round += 1
	emit_signal("round_started", cards.duplicate())

func on_merge(idx_a: int, idx_b: int, result: float) -> void:
	var hi := maxi(idx_a, idx_b)
	var lo := mini(idx_a, idx_b)

	cards.remove_at(hi)
	cards.remove_at(lo)
	cards.append({ "value": result, "display": _format_value(result), "suit": 0 })

	if len(cards) == 1:
		if abs(cards[0].value - 24.0) < 0.0001:
			score += 1
			emit_signal("game_won")
		else:
			score -= 1
			emit_signal("game_lost")

func _value_to_display(v: int) -> String:
	match v:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		_: return str(v)

func _format_value(v: float) -> String:
	if v == floorf(v):
		return str(int(v))
	return str(v)
