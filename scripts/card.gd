class_name Card
extends Node2D

signal dropped_on(source: Card, target: Card)

var value: float
var display: String
var suit: int

var input_enabled: bool = true
var _dragging: bool = false
var _drag_offset: Vector2
var _original_position: Vector2

func setup(v: float, d: String, s: int) -> void:
	value = v
	display = d
	suit = s
	$Panel/Label.text = d
	modulate = _color_for_value(v)

func _color_for_value(v: float) -> Color:
	match int(v) if absf(v - roundf(v)) < 1e-9 else -1:
		1:  return Color(1.0, 0.85, 0.3)   # A  — gold
		2:  return Color(0.5, 0.85, 0.5)   # 2  — green
		3:  return Color(1.0, 0.5,  0.4)   # 3  — coral
		4:  return Color(0.4, 0.7,  1.0)   # 4  — sky blue
		5:  return Color(0.75, 0.5, 1.0)   # 5  — purple
		6:  return Color(0.3, 0.8,  0.8)   # 6  — teal
		7:  return Color(1.0, 0.6,  0.8)   # 7  — pink
		8:  return Color(0.15, 0.2,0.53)   # 8  — dark blue
		9:  return Color(1.0, 0.65, 0.3)   # 9  — orange
		10: return Color(0.6, 0.9,  0.4)   # 10 — lime
		11: return Color(1.0, 0.4,  0.8)   # J  — magenta
		12: return Color(0.125,0.55,0.55)   # Q  — dark teal
		13: return Color(0.9, 0.3,  0.3)   # K  — red
		24: return Color(1.0, 0.9,  0.0)   # 24 — bright gold
		_:  return Color(0.85, 0.85, 0.85) # merged result — light grey

func _is_mouse_over() -> bool:
	var rect = $Panel.get_global_rect()
	return rect.has_point(get_viewport().get_mouse_position())

func _input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_mouse_over():
				_original_position = global_position
				_dragging = true
				_drag_offset = global_position - event.global_position
				z_index = 10
			else:
				if _dragging:
					_dragging = false
					z_index = 0
					_check_drop()

	if event is InputEventMouseMotion and _dragging:
		global_position = event.global_position + _drag_offset

func _check_drop() -> void:
	for area in $Area2D.get_overlapping_areas():
		var target = area.get_parent()
		if target != self and target is Card:
			emit_signal("dropped_on", self, target)
			return
	global_position = _original_position
