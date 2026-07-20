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
var _original_rotation: float
var _velocity: Vector2 = Vector2.ZERO
var _prev_mouse_pos: Vector2 = Vector2.ZERO
var _gliding: bool = false

const FRICTION := 0.88
const BOUNCE := 0.25
const CARD_W := 120.0
const CARD_H := 180.0

func _make_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_left = 16
	s.corner_radius_bottom_right = 16
	return s

func setup(v: float, d: String, s: int) -> void:
	value = v
	display = d
	suit = s
	$Panel/Label.text = d
	$Panel.add_theme_stylebox_override("panel", _make_style(_color_for_value(v)))

func set_face_down() -> void:
	$Panel.add_theme_stylebox_override("panel", _make_style(Color(1, 1, 1, 1)))
	$Panel/Label.visible = false

func reveal_face() -> void:
	$Panel.add_theme_stylebox_override("panel", _make_style(_color_for_value(value)))
	$Panel/Label.visible = true

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
				_original_rotation = rotation
				_dragging = true
				_gliding = false
				_velocity = Vector2.ZERO
				_prev_mouse_pos = event.global_position
				_drag_offset = global_position - event.global_position
				z_index = 10
			else:
				if _dragging:
					_dragging = false
					z_index = 0
					_check_drop()

	if event is InputEventMouseMotion and _dragging:
		_velocity = event.global_position - _prev_mouse_pos
		_prev_mouse_pos = event.global_position
		global_position = event.global_position + _drag_offset

func _process(_delta: float) -> void:
	if not _gliding:
		return
	global_position += _velocity
	_velocity *= FRICTION
	_clamp_to_walls()
	if _velocity.length_squared() < 0.25:
		_gliding = false
		_velocity = Vector2.ZERO

func _clamp_to_walls() -> void:
	var vp := get_viewport_rect().size
	var pos := global_position
	if pos.x < 0.0:
		pos.x = 0.0
		_velocity.x = absf(_velocity.x) * BOUNCE
	elif pos.x + CARD_W > vp.x:
		pos.x = vp.x - CARD_W
		_velocity.x = -absf(_velocity.x) * BOUNCE
	if pos.y < 0.0:
		pos.y = 0.0
		_velocity.y = absf(_velocity.y) * BOUNCE
	elif pos.y + CARD_H > vp.y:
		pos.y = vp.y - CARD_H
		_velocity.y = -absf(_velocity.y) * BOUNCE
	global_position = pos

func _check_drop() -> void:
	for area in $Area2D.get_overlapping_areas():
		var target = area.get_parent()
		if target != self and target is Card:
			emit_signal("dropped_on", self, target)
			return
	_gliding = true
