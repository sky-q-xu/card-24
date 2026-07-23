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
var _auto_solving: bool = false
var _discard_count: int = 0

signal _merge_resolved(op: String)

func _ready() -> void:
	GameManager.round_started.connect(_on_round_started)
	GameManager.game_given_up.connect(_on_game_given_up)
	GameManager.deal_new_round(false)
	_create_walls()

func _create_walls() -> void:
	var vp := get_viewport_rect().size
	const T := 200.0  # thick enough that no card can tunnel through in one frame
	var walls := [
		[Vector2(-T * 0.5, vp.y * 0.5), Vector2(T, vp.y + T * 2)],        # left
		[Vector2(vp.x + T * 0.5, vp.y * 0.5), Vector2(T, vp.y + T * 2)],  # right
		[Vector2(vp.x * 0.5, -T * 0.5), Vector2(vp.x + T * 2, T)],        # top
		[Vector2(vp.x * 0.5, vp.y + T * 0.5), Vector2(vp.x + T * 2, T)],  # bottom
	]
	for w in walls:
		var sb := StaticBody2D.new()
		sb.position = w[0]
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = w[1]
		cs.shape = rect
		sb.add_child(cs)
		add_child(sb)

func _on_game_given_up(solvable: bool, steps: Array) -> void:
	if solvable:
		_auto_solve_animation(steps)  # fire-and-forget coroutine

func _find_card_with_value(val: float, exclude: Card = null) -> Card:
	for card in _live_cards:
		if card != exclude and abs(card.value - val) < 1e-9:
			return card
	return null

func _spawn_leaves_from_data(data: Dictionary, pos: Vector2) -> Array:
	if not data.get("is_merged", false):
		var c: Card = CARD_SCENE.instantiate()
		c.setup(float(data["value"]), data["display"], data.get("suit", 0))
		c.global_position = pos
		c.input_enabled = false
		c.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		c.freeze = true
		return [c]
	var leaves: Array = []
	leaves.append_array(_spawn_leaves_from_data(data["merge_tgt_data"], data["merge_tgt_pos"]))
	leaves.append_array(_spawn_leaves_from_data(data["merge_src_data"], data["merge_src_pos"]))
	return leaves

func _auto_solve_animation(steps: Array) -> void:
	_auto_solving = true
	_set_cards_interactive(false)
	# Cancel any in-progress operator selection
	_merge_resolved.emit("")
	operator_bar.deactivate()
	# Immediately stop all card physics so nothing goes flying
	for card in _live_cards:
		card.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		card.freeze = true
		card.linear_velocity = Vector2.ZERO
		card.angular_velocity = 0.0

	# Silently decompose any already-merged cards back to their leaf cards so the
	# solver steps (which use the original 4 values) can find them on the board.
	var merged_snapshot: Array = _live_cards.filter(func(c: Card): return c.is_merged)
	for mc in merged_snapshot:
		var leaf_nodes := _spawn_leaves_from_data(_card_data(mc), mc.global_position)
		_live_cards.erase(mc)
		mc.queue_free()
		for leaf in leaf_nodes:
			add_child(leaf)
			_live_cards.append(leaf)

	for step in steps:
		if not _auto_solving:
			return
		var a_val: float = step["a_val"]
		var b_val: float = step["b_val"]
		var op: String = step["op"]
		var result_val: float = step["result_val"]

		var source := _find_card_with_value(a_val)
		var target := _find_card_with_value(b_val, source)
		if source == null or target == null:
			break

		source.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		source.freeze = true
		source.linear_velocity = Vector2.ZERO
		target.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		target.freeze = true
		target.linear_velocity = Vector2.ZERO

		var slide_dest: Vector2
		if source.is_merged:
			slide_dest = target.get_center()
		else:
			slide_dest = target.get_center() - Vector2(Card.CARD_W * 0.5, Card.CARD_H * 0.5)
		var slide := create_tween()
		slide.tween_property(source, "global_position", slide_dest, 0.30) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await slide.finished
		if not _auto_solving or not is_instance_valid(source) or not is_instance_valid(target):
			return

		var idx_a := _card_index(source)
		var idx_b := _card_index(target)
		var hi := maxi(idx_a, idx_b)
		var lo := mini(idx_a, idx_b)
		var src_data := _card_data(source)
		var tgt_data := _card_data(target)
		var src_pos := source.global_position
		var src_rot := source.rotation
		var tgt_pos := target.global_position
		var tgt_rot := target.rotation
		var tgt_center := target.get_center()

		var shrink := create_tween()
		shrink.tween_property(source, "scale", Vector2.ZERO, 0.12) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		shrink.parallel().tween_property(target, "scale", Vector2.ZERO, 0.12) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await shrink.finished
		if not _auto_solving:
			return

		source.queue_free()
		target.queue_free()
		_live_cards.remove_at(hi)
		_live_cards.remove_at(lo)

		var merged: Card = CARD_SCENE.instantiate()
		merged.setup(result_val, GameManager.format_value(result_val), 0)
		merged.global_position = tgt_center
		merged.rotation = 0.0
		merged.scale = Vector2(0.0, 1.0)
		merged.input_enabled = false
		merged.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		merged.freeze = true
		add_child(merged)
		merged.show_as_merged(op, src_data, src_pos, src_rot, tgt_data, tgt_pos, tgt_rot)
		_live_cards.append(merged)

		var unfold := create_tween()
		unfold.tween_property(merged, "scale:x", 1.0, 0.28) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await unfold.finished
		if not _auto_solving:
			return

	# Pause so the player can see the final result, then start next round
	await get_tree().create_timer(2.0).timeout
	if _auto_solving:
		_auto_solving = false
		GameManager.deal_new_round()

func _animate_to_discard(card: Card, delay: float) -> void:
	card.input_enabled = false
	card.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	card.freeze = true
	card.linear_velocity = Vector2.ZERO
	card.angular_velocity = 0.0
	var dest: Vector2 = $GameBoard/DiscardPile.global_position
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(card, "global_position", dest, 0.30) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(card, "scale", Vector2(0.5, 0.5), 0.30)
	tween.parallel().tween_property(card, "rotation", 0.0, 0.20)
	tween.tween_callback(card.queue_free)

func _update_discard_pile() -> void:
	$GameBoard/DiscardPile/Layer0.visible = _discard_count >= 1
	$GameBoard/DiscardPile/Layer1.visible = _discard_count >= 2
	$GameBoard/DiscardPile/Layer2.visible = _discard_count >= 3
	var lbl: Label = $GameBoard/DiscardPile/CountLabel
	lbl.text = str(_discard_count) if _discard_count > 0 else ""

func _on_round_started(card_data: Array) -> void:
	_auto_solving = false
	_discard_count += _live_cards.size()
	for i in _live_cards.size():
		_animate_to_discard(_live_cards[i], i * 0.06)
	_live_cards.clear()
	_update_discard_pile()
	var slots := _card_slots.get_children()
	for i in range(card_data.size()):
		var c: Card = CARD_SCENE.instantiate()
		c.setup(card_data[i].value, card_data[i].display, card_data[i].suit)
		c.set_face_down()
		c.global_position = _deck.global_position
		c.scale = Vector2(0.6, 0.6)
		c.input_enabled = false
		c.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		c.freeze = true
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
	tween.tween_callback(func(): card.input_enabled = true; card.freeze = false)

func _on_card_dropped_on(source: Card, target: Card) -> void:
	_set_cards_interactive(false)
	# Freeze both cards so physics doesn't fight the animations
	source.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	source.freeze = true
	source.linear_velocity = Vector2.ZERO
	target.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	target.freeze = true
	target.linear_velocity = Vector2.ZERO

	operator_bar.activate()

	@warning_ignore("confusable_local_declaration")
	operator_bar.operator_selected.connect(func(op): _merge_resolved.emit(op), CONNECT_ONE_SHOT)
	operator_bar.cancelled.connect(func(): _merge_resolved.emit(""), CONNECT_ONE_SHOT)

	var op: String = await _merge_resolved

	if op == "":
		source.global_position = source._original_position
		source.rotation = source._original_rotation
		source.freeze = false
		_set_cards_interactive(true)
		return

	var result = _apply_op(source.value, target.value, op)
	if result == null:
		operator_bar.deactivate()
		source.freeze = false
		_set_cards_interactive(true)
		return

	# Slide source onto target — align centers so bar cards don't land offset
	var slide_dest: Vector2
	if source.is_merged:
		slide_dest = target.get_center()
	else:
		slide_dest = target.get_center() - Vector2(Card.CARD_W * 0.5, Card.CARD_H * 0.5)
	var slide := create_tween()
	slide.tween_property(source, "global_position", slide_dest, 0.18) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await slide.finished

	# Capture all data before freeing cards
	var idx_a := _card_index(source)
	var idx_b := _card_index(target)
	var hi := maxi(idx_a, idx_b)
	var lo := mini(idx_a, idx_b)
	var src_data := _card_data(source)
	var tgt_data := _card_data(target)
	var src_orig_pos := source._original_position
	var src_orig_rot := source._original_rotation
	var tgt_pos := target.global_position
	var tgt_rot := target.rotation
	var tgt_center := target.get_center()

	# Shrink both cards to nothing
	var shrink := create_tween()
	shrink.tween_property(source, "scale", Vector2.ZERO, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	shrink.parallel().tween_property(target, "scale", Vector2.ZERO, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await shrink.finished

	source.queue_free()
	target.queue_free()

	# Create bar card collapsed on the x axis, frozen during animation
	var merged: Card = CARD_SCENE.instantiate()
	merged.setup(result, GameManager.format_value(result), 0)
	merged.global_position = tgt_center
	merged.rotation = 0.0
	merged.scale = Vector2(0.0, 1.0)
	merged.input_enabled = false
	merged.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	merged.freeze = true
	add_child(merged)
	merged.show_as_merged(op, src_data, src_orig_pos, src_orig_rot, tgt_data, tgt_pos, tgt_rot)
	merged.dropped_on.connect(_on_card_dropped_on)
	merged.unmerged.connect(_on_card_unmerged)

	_live_cards.remove_at(hi)
	_live_cards.remove_at(lo)
	_live_cards.append(merged)
	GameManager.on_merge(idx_a, idx_b, result)

	# Unfold bar from center outward
	var unfold := create_tween()
	unfold.tween_property(merged, "scale:x", 1.0, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await unfold.finished

	merged.freeze = false
	merged.input_enabled = true
	_set_cards_interactive(true)

func _on_card_unmerged(merged: Card) -> void:
	var merged_idx := _card_index(merged)

	# Capture constituent data before animation
	var src_data := merged._merge_source_data.duplicate(true)
	var tgt_data := merged._merge_target_data.duplicate(true)
	var src_pos := merged._merge_source_pos
	var src_rot := merged._merge_source_rot
	var tgt_pos := merged._merge_target_pos
	var tgt_rot := merged._merge_target_rot

	# Fold bar shut
	merged.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	merged.freeze = true
	var fold := create_tween()
	fold.tween_property(merged, "scale:x", 0.0, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fold.finished

	GameManager.on_unmerge(merged_idx, src_data, tgt_data)
	_live_cards.remove_at(merged_idx)
	merged.queue_free()

	# Spawn constituent cards at original positions, collapsed and frozen.
	# If a constituent was itself a merged bar card, reconstruct it as one.
	var card_a: Card = CARD_SCENE.instantiate()
	card_a.setup(src_data.value, src_data.display, src_data.suit)
	card_a.global_position = src_pos
	card_a.rotation = src_rot
	card_a.scale = Vector2.ZERO
	card_a.input_enabled = false
	card_a.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	card_a.freeze = true
	card_a.dropped_on.connect(_on_card_dropped_on)
	card_a.unmerged.connect(_on_card_unmerged)
	add_child(card_a)
	if src_data.get("is_merged", false):
		card_a.show_as_merged(
			src_data.merge_op,
			src_data.merge_src_data,
			src_data.merge_src_pos,
			src_data.merge_src_rot,
			src_data.merge_tgt_data,
			src_data.merge_tgt_pos,
			src_data.merge_tgt_rot
		)

	var card_b: Card = CARD_SCENE.instantiate()
	card_b.setup(tgt_data.value, tgt_data.display, tgt_data.suit)
	card_b.global_position = tgt_pos
	card_b.rotation = tgt_rot
	card_b.scale = Vector2.ZERO
	card_b.input_enabled = false
	card_b.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	card_b.freeze = true
	card_b.dropped_on.connect(_on_card_dropped_on)
	card_b.unmerged.connect(_on_card_unmerged)
	add_child(card_b)
	if tgt_data.get("is_merged", false):
		card_b.show_as_merged(
			tgt_data.merge_op,
			tgt_data.merge_src_data,
			tgt_data.merge_src_pos,
			tgt_data.merge_src_rot,
			tgt_data.merge_tgt_data,
			tgt_data.merge_tgt_pos,
			tgt_data.merge_tgt_rot
		)

	_live_cards.push_back(card_a)
	_live_cards.push_back(card_b)

	# Pop cards back in
	var pop := create_tween()
	pop.tween_property(card_a, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.parallel().tween_property(card_b, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop.finished

	card_a.freeze = false
	card_b.freeze = false
	card_a.input_enabled = true
	card_b.input_enabled = true
	_set_cards_interactive(true)

func _card_data(card: Card) -> Dictionary:
	var data := {"value": card.value, "display": card.display, "suit": card.suit, "is_merged": card.is_merged}
	if card.is_merged:
		data["bar_text"] = card._bar_text
		data["merge_op"] = card._merge_op
		data["merge_src_data"] = card._merge_source_data.duplicate(true)
		data["merge_src_pos"] = card._merge_source_pos
		data["merge_src_rot"] = card._merge_source_rot
		data["merge_tgt_data"] = card._merge_target_data.duplicate(true)
		data["merge_tgt_pos"] = card._merge_target_pos
		data["merge_tgt_rot"] = card._merge_target_rot
	return data

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
