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
	match s:
		1, 2:
			modulate = Color(1.0, 0.7, 0.7)
		_:
			modulate = Color.WHITE

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
