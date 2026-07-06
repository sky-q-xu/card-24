extends Node2D

const CARD_SCENE = preload("res://scenes/card.tscn")

@onready var operator_popup: OperatorPopup = $UILayer/OperatorPopup
@onready var _card_slots: Node2D = $GameBoard/CardSlots

var _live_cards: Array = []

signal _merge_resolved(op: String)

func _ready() -> void:
	GameManager.round_started.connect(_on_round_started)
	GameManager.game_won.connect(_on_game_won)
	GameManager.game_lost.connect(_on_game_lost)
	GameManager.deal_new_round()

func _on_round_started(card_data: Array) -> void:
	for card in _live_cards:
		card.queue_free()
	_live_cards.clear()
	var slots := _card_slots.get_children()
	for i in range(card_data.size()):
		var c: Card = CARD_SCENE.instantiate()
		c.setup(card_data[i].value, card_data[i].display, card_data[i].suit)
		c.global_position = slots[i].global_position
		c.dropped_on.connect(_on_card_dropped_on)
		add_child(c)
		_live_cards.append(c)

func _on_game_won() -> void:
	pass  # WinScreen wired here later

func _on_game_lost() -> void:
	pass  # LoseScreen wired here later

func _on_card_dropped_on(source: Card, target: Card) -> void:
	_set_cards_interactive(false)
	var mid := (source.global_position + target.global_position) / 2.0
	operator_popup.show_at(mid)

	@warning_ignore("confusable_local_declaration")
	operator_popup.operator_selected.connect(func(op): _merge_resolved.emit(op), CONNECT_ONE_SHOT)
	operator_popup.cancelled.connect(func(): _merge_resolved.emit(""), CONNECT_ONE_SHOT)

	var op: String = await _merge_resolved

	if op == "":
		source.global_position = source._original_position
		_set_cards_interactive(true)
		return

	var result = _apply_op(source.value, target.value, op)
	if result == null:
		_set_cards_interactive(true)
		return

	var idx_a := _card_index(source)
	var idx_b := _card_index(target)
	var hi := maxi(idx_a, idx_b)
	var lo := mini(idx_a, idx_b)

	var merged: Card = CARD_SCENE.instantiate()
	merged.setup(result, _format_value(result), 0)
	merged.global_position = target.global_position
	add_child(merged)
	merged.dropped_on.connect(_on_card_dropped_on)

	_live_cards.remove_at(hi)
	_live_cards.remove_at(lo)
	_live_cards.append(merged)

	source.queue_free()
	target.queue_free()

	GameManager.on_merge(idx_a, idx_b, result)
	_set_cards_interactive(true)

func _apply_op(a: float, b: float, op: String) -> Variant:
	if op == "+":
		return a + b
	if op == "-":
		return a - b
	if op == "*":
		return a * b
	if op == "/":
		if b == 0.0:
			return null
		return a / b
	return null

func _card_index(card: Card) -> int:
	return _live_cards.find(card)

func _set_cards_interactive(enabled: bool) -> void:
	for card in _live_cards:
		card.input_enabled = enabled

func _format_value(v: float) -> String:
	if v == floorf(v):
		return str(int(v))
	return str(v)
