extends Node

var ensure_solvable: bool = false

signal round_started(card_data: Array)
signal game_won
signal game_lost

var cards: Array = []
var round: int = 1
var score: int = 0

func deal_new_round(increment_round: bool = true) -> void:
	var vals := _pick_four()
	if ensure_solvable:
		var tries := 0
		while not Solver.can_reach_24(vals) and tries < 100:
			vals = _pick_four()
			tries += 1
	else:
		# 2:3 solvable:unsolvable ratio (40% solvable, 60% unsolvable)
		var want_solvable := randf() < 0.4
		var tries := 0
		while Solver.can_reach_24(vals) != want_solvable and tries < 200:
			vals = _pick_four()
			tries += 1
	cards = []
	for v in vals:
		cards.append({
			"value": float(v),
			"display": _value_to_display(v),
			"suit": randi_range(0, 3)
		})
	if increment_round:
		round += 1
	emit_signal("round_started", cards.duplicate())

func _pick_four() -> Array:
	var vals := []
	for i in 4:
		vals.append(randi_range(1, 13))
	return vals

func on_merge(idx_a: int, idx_b: int, result: float) -> void:
	var hi := maxi(idx_a, idx_b)
	var lo := mini(idx_a, idx_b)

	cards.remove_at(hi)
	cards.remove_at(lo)
	cards.append({ "value": result, "display": format_value(result), "suit": 0 })

	if len(cards) == 1:
		if abs(cards[0].value - 24.0) < 0.0001:
			score += 1
			emit_signal("game_won")
		else:
			score -= 1
			emit_signal("game_lost")

func on_unmerge(merged_idx: int, data_a: Dictionary, data_b: Dictionary) -> void:
	cards.remove_at(merged_idx)
	cards.push_back(data_a)
	cards.push_back(data_b)

func _value_to_display(v: int) -> String:
	match v:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		_: return str(v)

func format_value(v: float) -> String:
	if absf(v - roundf(v)) < 1e-9:
		var i := int(roundf(v))
		match i:
			1: return "A"
			11: return "J"
			12: return "Q"
			13: return "K"
		return str(i)
	var sign_str := "-" if v < 0.0 else ""
	var abs_v := absf(v)
	for d in range(2, 10001):
		var n := roundi(abs_v * d)
		if absf(float(n) / float(d) - abs_v) < 1e-9:
			var g := _gcd(n, d)
			var num := n / g
			var den := d / g
			var rem := den
			while rem % 2 == 0: rem /= 2
			while rem % 5 == 0: rem /= 5
			if rem != 1:
				if num > den:
					var whole := num / den
					var numer := num % den
					return "%s%d %d/%d" % [sign_str, whole, numer, den]
				return "%s%d/%d" % [sign_str, num, den]
			break
	return str(v)

func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a
