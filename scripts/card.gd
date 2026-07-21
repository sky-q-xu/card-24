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

const CARD_W := 120.0
const CARD_H := 180.0
const BAR_HW := 120.0
const BAR_HH := 40.0
# Offset applied to back card so its top-left corner peeks above/left of the front card
const STACK_OFFSET_X := 16.0
const STACK_OFFSET_Y := 30.0

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
	s.bg_color = Color(0.86, 0.86, 0.86, 1)
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.45, 0.45, 0.45, 1)
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_left = 16
	s.corner_radius_bottom_right = 16
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

	# Back card (StackLayer1 = source): shifted up-left so its top-left corner
	# peeks above and to the left of the front card. Both TopLabel and BottomLabel
	# are set but BottomLabel ends up hidden behind StackLayer0.
	var hw := CARD_W * 0.5  # 60
	var hh := CARD_H * 0.5  # 90
	$StackLayer1.offset_left   = -hw - STACK_OFFSET_X
	$StackLayer1.offset_top    = -hh - STACK_OFFSET_Y
	$StackLayer1.offset_right  =  hw - STACK_OFFSET_X
	$StackLayer1.offset_bottom =  hh - STACK_OFFSET_Y
	$StackLayer1.add_theme_stylebox_override("panel", _make_card_style(src_data.value))
	$StackLayer1/TopLabel.text = src_data.display
	$StackLayer1/TopLabel.add_theme_font_size_override("font_size", 22)
	$StackLayer1/BottomLabel.text = src_data.display
	$StackLayer1/BottomLabel.add_theme_font_size_override("font_size", 22)
	$StackLayer1.visible = true

	# Front card (StackLayer0 = target): centered at node origin so it peeks
	# 50 px above the bar top and 50 px below the bar bottom.
	$StackLayer0.offset_left   = -hw
	$StackLayer0.offset_top    = -hh
	$StackLayer0.offset_right  =  hw
	$StackLayer0.offset_bottom =  hh
	$StackLayer0.add_theme_stylebox_override("panel", _make_card_style(tgt_data.value))
	$StackLayer0/TopLabel.text = tgt_data.display
	$StackLayer0/TopLabel.add_theme_font_size_override("font_size", 22)
	$StackLayer0/BottomLabel.text = tgt_data.display
	$StackLayer0/BottomLabel.add_theme_font_size_override("font_size", 22)
	$StackLayer0.visible = true

	# Bar in front of both cards
	$Panel.offset_left  = -BAR_HW; $Panel.offset_top    = -BAR_HH
	$Panel.offset_right =  BAR_HW; $Panel.offset_bottom =  BAR_HH
	$Panel.add_theme_stylebox_override("panel", _make_merged_style())
	$Panel/TopLabel.visible = false
	$Panel/BottomLabel.visible = false
	$Panel/BarLabel.text = src_data.display + " " + _OP_SYMBOL.get(op, op) + " " + tgt_data.display
	$Panel/BarLabel.visible = true

	# Collision shapes cover only the bar (the interactive target)
	var bar_shape := RectangleShape2D.new()
	bar_shape.size = Vector2(BAR_HW * 2.0, BAR_HH * 2.0)
	$CollisionShape2D.shape = bar_shape
	$CollisionShape2D.position = Vector2.ZERO
	$Area2D/CollisionShape2D.shape = bar_shape
	$Area2D/CollisionShape2D.position = Vector2.ZERO

func _color_for_value(v: float) -> Color:
	match int(v) if absf(v - roundf(v)) < 1e-9 else -1:
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
		_:  return Color(0.85, 0.85, 0.85)

func _is_mouse_over() -> bool:
	var local := to_local(get_viewport().get_mouse_position())
	if is_merged:
		# Union of bar + front card + back card (shifted up-left)
		var bar   := Rect2(-BAR_HW, -BAR_HH, BAR_HW * 2.0, BAR_HH * 2.0)
		var front := Rect2(-CARD_W * 0.5, -CARD_H * 0.5, CARD_W, CARD_H)
		var back  := Rect2(-CARD_W * 0.5 - STACK_OFFSET_X, -CARD_H * 0.5 - STACK_OFFSET_Y,
				CARD_W, CARD_H)
		return bar.has_point(local) or front.has_point(local) or back.has_point(local)
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
			else:
				if _dragging:
					_dragging = false
					z_index = 0
					# Short tap on the bar specifically = unmerge
					if is_merged and (event.global_position - _press_position).length() < 8.0:
						var local := to_local(event.global_position)
						if Rect2(-BAR_HW, -BAR_HH, BAR_HW * 2.0, BAR_HH * 2.0).has_point(local):
							global_position = _original_position
							rotation = _original_rotation
							input_enabled = false
							emit_signal("unmerged", self)
							return
					freeze = false
					linear_velocity = _tracked_velocity
					_check_drop()

	if event is InputEventMouseMotion and _dragging:
		_tracked_velocity = event.velocity
		global_position = event.global_position + _drag_offset
		_clamp_drag_to_walls()

func _clamp_drag_to_walls() -> void:
	var vp := get_viewport_rect().size
	var pos := global_position
	if is_merged:
		pos.x = clampf(pos.x, BAR_HW, vp.x - BAR_HW)
		pos.y = clampf(pos.y, BAR_HH + STACK_OFFSET_Y, vp.y - BAR_HH)
	else:
		pos.x = clampf(pos.x, 0.0, vp.x - CARD_W)
		pos.y = clampf(pos.y, 0.0, vp.y - CARD_H)
	global_position = pos

func _check_drop() -> void:
	for area in $Area2D.get_overlapping_areas():
		var target = area.get_parent()
		if target != self and target is Card:
			emit_signal("dropped_on", self, target)
			return
