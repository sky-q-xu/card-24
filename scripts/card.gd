class_name Card
extends RigidBody2D

signal dropped_on(source: Card, target: Card)
signal unmerged(card: Card)

var value: float
var display: String
var suit: int

var input_enabled: bool = true
var _dragging: bool = false
var _drag_offset: Vector2
var _original_position: Vector2
var _original_rotation: float
var _tracked_velocity: Vector2 = Vector2.ZERO
var _press_position: Vector2 = Vector2.ZERO

var is_merged: bool = false
var _merge_op: String = ""
var _merge_source_data: Dictionary = {}
var _merge_target_data: Dictionary = {}
var _merge_source_pos: Vector2 = Vector2.ZERO
var _merge_target_pos: Vector2 = Vector2.ZERO
var _merge_source_rot: float = 0.0
var _merge_target_rot: float = 0.0
var _bar_text: String = ""
var _leaf_count: int = 0
var _badge_w: float = 0.0

const CARD_W := 120.0
const CARD_H := 180.0
const STACK_OFFSET_X := 16.0
const STACK_OFFSET_Y := 30.0
const BADGE_H := 48.0
const BADGE_GAP := 2.0
const BADGE_FONT_SIZE := 14
const BADGE_CHAR_W := 10.0   # estimated px per character at BADGE_FONT_SIZE
const BADGE_PAD_X := 16.0    # total horizontal padding inside badge
const BADGE_MIN_W := 52.0

func _make_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_left = 16
	s.corner_radius_bottom_right = 16
	return s

func _make_card_style(v: float) -> StyleBoxFlat:
	var s := _make_style(_color_for_value(v))
	s.border_width_left = 2; s.border_width_top = 2
	s.border_width_right = 2; s.border_width_bottom = 2
	s.border_color = Color(0, 0, 0, 0.25)
	return s

func _make_merged_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.95, 0.93, 0.88, 1.0)
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.3, 0.24, 0.18, 1.0)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	return s

func setup(v: float, d: String, s: int) -> void:
	value = v
	display = d
	suit = s
	$Panel.add_theme_stylebox_override("panel", _make_style(_color_for_value(v)))
	$Panel/TopLabel.text = d
	$Panel/BottomLabel.text = d

func set_face_down() -> void:
	$Panel.add_theme_stylebox_override("panel", _make_style(Color(1, 1, 1, 1)))
	$Panel/TopLabel.visible = false
	$Panel/BottomLabel.visible = false

func reveal_face() -> void:
	$Panel.add_theme_stylebox_override("panel", _make_style(_color_for_value(value)))
	$Panel/TopLabel.visible = true
	$Panel/BottomLabel.visible = true

func get_center() -> Vector2:
	if is_merged:
		return global_position
	return global_position + Vector2(CARD_W * 0.5, CARD_H * 0.5)

const _OP_SYMBOL := {"+": "+", "-": "−", "*": "×", "/": "÷"}

# Returns a flat list of all individual (leaf) card data dicts, front first.
func _flatten_to_leaves(data: Dictionary) -> Array:
	if not data.get("is_merged", false):
		return [data]
	var leaves := []
	# tgt = front constituent, src = back constituent
	leaves.append_array(_flatten_to_leaves(data.get("merge_tgt_data", {})))
	leaves.append_array(_flatten_to_leaves(data.get("merge_src_data", {})))
	return leaves

func show_as_merged(op: String, src_data: Dictionary, src_pos: Vector2, src_rot: float,
		tgt_data: Dictionary, tgt_pos: Vector2, tgt_rot: float) -> void:
	is_merged = true
	_merge_op = op
	_merge_source_data = src_data.duplicate()
	_merge_target_data = tgt_data.duplicate()
	_merge_source_pos = src_pos
	_merge_source_rot = src_rot
	_merge_target_pos = tgt_pos
	_merge_target_rot = tgt_rot

	# Flatten to individual leaf cards: target = front, source = behind
	var leaves := []
	leaves.append_array(_flatten_to_leaves(tgt_data))
	leaves.append_array(_flatten_to_leaves(src_data))
	_leaf_count = mini(leaves.size(), 4)

	var hw := CARD_W * 0.5
	var hh := CARD_H * 0.5
	var layer_nodes := [$StackLayer0, $StackLayer1, $StackLayer2, $StackLayer3]

	# Show one StackLayer per leaf, each shifted diagonally back
	for i in range(4):
		var layer: Control = layer_nodes[i]
		if i >= _leaf_count:
			layer.visible = false
			continue
		var leaf: Dictionary = leaves[i]
		var ox := -float(i) * STACK_OFFSET_X
		var oy := -float(i) * STACK_OFFSET_Y
		layer.offset_left   = -hw + ox
		layer.offset_top    = -hh + oy
		layer.offset_right  =  hw + ox
		layer.offset_bottom =  hh + oy
		var corner_text: String = leaf.get("display", "?")
		layer.add_theme_stylebox_override("panel", _make_card_style(leaf.value))
		layer.get_node("TopLabel").text = corner_text
		layer.get_node("BottomLabel").text = corner_text
		layer.visible = true

	# Hide the main card face (Panel body) — it becomes the side badge
	$Panel/TopLabel.visible = false
	$Panel/BottomLabel.visible = false

	# Build expression string for badge, wrapping merged constituents in parens
	var src_expr: String = src_data.get("bar_text", src_data.display)
	var tgt_expr: String = tgt_data.get("bar_text", tgt_data.display)
	if src_data.get("is_merged", false):
		src_expr = "(" + src_expr + ")"
	if tgt_data.get("is_merged", false):
		tgt_expr = "(" + tgt_expr + ")"
	_bar_text = src_expr + " " + _OP_SYMBOL.get(op, op) + " " + tgt_expr

	# Square badge to the LEFT of the stack — expands to fit the expression
	_badge_w = maxf(BADGE_MIN_W, float(_bar_text.length()) * BADGE_CHAR_W + BADGE_PAD_X)
	var stack_left := -hw - (_leaf_count - 1) * STACK_OFFSET_X
	var badge_right := stack_left - BADGE_GAP
	$Panel.offset_left   = badge_right - _badge_w
	$Panel.offset_top    = -BADGE_H * 0.5
	$Panel.offset_right  = badge_right
	$Panel.offset_bottom =  BADGE_H * 0.5
	$Panel.add_theme_stylebox_override("panel", _make_merged_style())
	$Panel/BarLabel.add_theme_font_size_override("font_size", BADGE_FONT_SIZE)
	$Panel/BarLabel.add_theme_color_override("font_color", Color.BLACK)
	$Panel/BarLabel.text = _bar_text
	$Panel/BarLabel.visible = true

	# Collision shape covers the front card body
	var card_shape := RectangleShape2D.new()
	card_shape.size = Vector2(CARD_W, CARD_H)
	$CollisionShape2D.shape = card_shape
	$CollisionShape2D.position = Vector2.ZERO
	$Area2D/CollisionShape2D.shape = card_shape
	$Area2D/CollisionShape2D.position = Vector2.ZERO

func _color_for_value(v: float) -> Color:
	if absf(v - roundf(v)) >= 1e-9:
		var hue := fmod(absf(v) * 0.618033988749, 1.0)
		return Color.from_hsv(hue, 0.55, 0.88)
	match int(roundf(v)):
		1:  return Color(1.0, 0.85, 0.3)
		2:  return Color(0.5, 0.85, 0.5)
		3:  return Color(1.0, 0.5,  0.4)
		4:  return Color(0.4, 0.7,  1.0)
		5:  return Color(0.75, 0.5, 1.0)
		6:  return Color(0.3, 0.8,  0.8)
		7:  return Color(1.0, 0.6,  0.8)
		8:  return Color(0.15, 0.2, 0.53)
		9:  return Color(1.0, 0.65, 0.3)
		10: return Color(0.6, 0.9,  0.4)
		11: return Color(1.0, 0.4,  0.8)
		12: return Color(0.125, 0.55, 0.55)
		13: return Color(0.9, 0.3,  0.3)
		24: return Color(1.0, 0.9,  0.0)
		_:
			var hue := fmod(absf(roundf(v)) * 0.618033988749, 1.0)
			return Color.from_hsv(hue, 0.55, 0.88)

func _is_mouse_over() -> bool:
	var local := to_local(get_viewport().get_mouse_position())
	if is_merged:
		var hw := CARD_W * 0.5
		var hh := CARD_H * 0.5
		# Check each visible stack layer
		for i in range(_leaf_count):
			var ox := -float(i) * STACK_OFFSET_X
			var oy := -float(i) * STACK_OFFSET_Y
			if Rect2(-hw + ox, -hh + oy, CARD_W, CARD_H).has_point(local):
				return true
		# Check badge rect
		var stack_left := -hw - (_leaf_count - 1) * STACK_OFFSET_X
		var badge_right := stack_left - BADGE_GAP
		if Rect2(badge_right - _badge_w, -BADGE_H * 0.5, _badge_w, BADGE_H).has_point(local):
			return true
		return false
	return Rect2(0.0, 0.0, CARD_W, CARD_H).has_point(local)

func _input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_mouse_over():
				_original_position = global_position
				_original_rotation = rotation
				_dragging = true
				_press_position = event.global_position
				_tracked_velocity = Vector2.ZERO
				_drag_offset = global_position - event.global_position
				z_index = 10
				freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
				freeze = true
				linear_velocity = Vector2.ZERO
				$CollisionShape2D.disabled = true
			else:
				if _dragging:
					_dragging = false
					z_index = 0
					# Short tap anywhere on the merged stack = unmerge
					if is_merged and (event.global_position - _press_position).length() < 8.0:
						global_position = _original_position
						rotation = _original_rotation
						input_enabled = false
						emit_signal("unmerged", self)
						return
					freeze = false
					$CollisionShape2D.disabled = false
					linear_velocity = _tracked_velocity.limit_length(1400.0)
					_check_drop()

	if event is InputEventMouseMotion and _dragging:
		_tracked_velocity = event.velocity
		global_position = event.global_position + _drag_offset
		_clamp_drag_to_walls()

func _clamp_drag_to_walls() -> void:
	var vp := get_viewport_rect().size
	var pos := global_position
	if is_merged:
		var hw := CARD_W * 0.5
		var hh := CARD_H * 0.5
		var n := _leaf_count
		# Left edge is the badge; right/bottom edge is the front card
		var left_margin := hw + (n - 1) * STACK_OFFSET_X + BADGE_GAP + _badge_w
		pos.x = clampf(pos.x, left_margin, vp.x - hw)
		pos.y = clampf(pos.y, hh + (n - 1) * STACK_OFFSET_Y, vp.y - hh)
	else:
		pos.x = clampf(pos.x, 0.0, vp.x - CARD_W)
		pos.y = clampf(pos.y, 0.0, vp.y - CARD_H)
	global_position = pos

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _dragging:
		return
	var vp := get_viewport_rect().size
	var pos := state.transform.origin
	# Emergency clamp: snap escaped cards back into the viewport
	var escape_margin := 50.0
	if pos.x < -escape_margin or pos.x > vp.x + escape_margin \
			or pos.y < -escape_margin or pos.y > vp.y + escape_margin:
		var safe_x := clampf(pos.x, 0.0, vp.x - CARD_W)
		var safe_y := clampf(pos.y, 0.0, vp.y - CARD_H)
		state.transform = Transform2D(state.transform.get_rotation(), Vector2(safe_x, safe_y))
		state.linear_velocity = Vector2.ZERO

func _check_drop() -> void:
	for area in $Area2D.get_overlapping_areas():
		var target = area.get_parent()
		if target != self and target is Card:
			emit_signal("dropped_on", self, target)
			return
