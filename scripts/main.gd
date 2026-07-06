extends Node2D

@export var CARD_SCENE: PackedScene
@onready var operator_popup: OperatorPopup = $OperatorPopup

var _live_cards: Array = []

signal _merge_resolved(op: String)  # "" = cancelled, else the operator string

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
	get_parent().add_child(merged)
	merged.dropped_on.connect(_on_card_dropped_on)

	_live_cards.remove_at(hi)
	_live_cards.remove_at(lo)
	_live_cards.append(merged)

	source.queue_free()
	target.queue_free()

	GameManager.on_merge(idx_a, idx_b, result)
	_set_cards_interactive(true)

func _apply_op(a: float, b: float, op: String) -> Variant:
	if op == "*":
		return a * b
	if op == "-":
		return a - b
	if op == "+":
		return a + b
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
