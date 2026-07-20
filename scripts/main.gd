extends Node2D

const CARD_SCENE = preload("res://scenes/card.tscn")

@onready var operator_bar = $OperatorBar
@onready var _card_slots: Node2D = $GameBoard/CardSlots
@onready var _deck: Node2D = $GameBoard/Deck

const DEAL_STAGGER := 0.12
const DEAL_DURATION := 0.35
const JITTER_POS := 10.0
const JITTER_ROT := 0.12

var _live_cards: Array = []

signal _merge_resolved(op: String)

func _ready() -> void:
	GameManager.round_started.connect(_on_round_started)
	GameManager.deal_new_round(false)

func _on_round_started(card_data: Array) -> void:
	for card in _live_cards:
		card.queue_free()
	_live_cards.clear()
	var slots := _card_slots.get_children()
	for i in range(card_data.size()):
		var c: Card = CARD_SCENE.instantiate()
		c.setup(card_data[i].value, card_data[i].display, card_data[i].suit)
		c.set_face_down()
		c.global_position = _deck.global_position
		c.scale = Vector2(0.6, 0.6)
		c.input_enabled = false
		c.dropped_on.connect(_on_card_dropped_on)
		add_child(c)
		_live_cards.append(c)
		_animate_deal(c, slots[i].global_position, i)

const FLIP_DURATION := 0.12

func _animate_deal(card: Card, target_position: Vector2, index: int) -> void:
	var final_pos := target_position + Vector2(
		randf_range(-JITTER_POS, JITTER_POS),
		randf_range(-JITTER_POS, JITTER_POS)
	)
	var final_rot := randf_range(-JITTER_ROT, JITTER_ROT)
	var tween := create_tween()
	tween.tween_interval(index * DEAL_STAGGER)
	tween.tween_property(card, "global_position", final_pos, DEAL_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, DEAL_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "rotation", final_rot, DEAL_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale:x", 0.0, FLIP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): card.reveal_face())
	tween.tween_property(card, "scale:x", 1.0, FLIP_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): card.input_enabled = true)

func _on_card_dropped_on(source: Card, target: Card) -> void:
	_set_cards_interactive(false)
	operator_bar.activate()

	@warning_ignore("confusable_local_declaration")
	operator_bar.operator_selected.connect(func(op): _merge_resolved.emit(op), CONNECT_ONE_SHOT)
	operator_bar.cancelled.connect(func(): _merge_resolved.emit(""), CONNECT_ONE_SHOT)

	var op: String = await _merge_resolved

	if op == "":
		source.global_position = source._original_position
		source.rotation = source._original_rotation
		_set_cards_interactive(true)
		return

	var result = _apply_op(source.value, target.value, op)
	if result == null:
		operator_bar.deactivate()
		_set_cards_interactive(true)
		return

	var slide := create_tween()
	slide.tween_property(source, "global_position", target.global_position, 0.18) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await slide.finished

	var idx_a := _card_index(source)
	var idx_b := _card_index(target)
	var hi := maxi(idx_a, idx_b)
	var lo := mini(idx_a, idx_b)

	var merged: Card = CARD_SCENE.instantiate()
	merged.setup(result, GameManager.format_value(result), 0)
	merged.global_position = target.global_position
	merged.rotation = target.rotation
	add_child(merged)
	merged.show_as_merged(
		op,
		{"value": source.value, "display": source.display, "suit": source.suit},
		source._original_position, source._original_rotation,
		{"value": target.value, "display": target.display, "suit": target.suit},
		target.global_position, target.rotation
	)
	merged.dropped_on.connect(_on_card_dropped_on)
	merged.unmerged.connect(_on_card_unmerged)

	_live_cards.remove_at(hi)
	_live_cards.remove_at(lo)
	_live_cards.append(merged)

	source.queue_free()
	target.queue_free()

	GameManager.on_merge(idx_a, idx_b, result)
	_set_cards_interactive(true)

func _on_card_unmerged(merged: Card) -> void:
	var merged_idx := _card_index(merged)

	var card_a: Card = CARD_SCENE.instantiate()
	card_a.setup(merged._merge_source_data.value, merged._merge_source_data.display, merged._merge_source_data.suit)
	card_a.global_position = merged._merge_source_pos
	card_a.rotation = merged._merge_source_rot
	card_a.dropped_on.connect(_on_card_dropped_on)
	card_a.unmerged.connect(_on_card_unmerged)
	add_child(card_a)

	var card_b: Card = CARD_SCENE.instantiate()
	card_b.setup(merged._merge_target_data.value, merged._merge_target_data.display, merged._merge_target_data.suit)
	card_b.global_position = merged._merge_target_pos
	card_b.rotation = merged._merge_target_rot
	card_b.dropped_on.connect(_on_card_dropped_on)
	card_b.unmerged.connect(_on_card_unmerged)
	add_child(card_b)

	GameManager.on_unmerge(merged_idx, merged._merge_source_data, merged._merge_target_data)
	_live_cards.remove_at(merged_idx)
	_live_cards.push_back(card_a)
	_live_cards.push_back(card_b)

	merged.queue_free()
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
