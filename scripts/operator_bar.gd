extends Node

signal operator_selected(op: String)
signal cancelled

const PLACARD_SCENE   = preload("res://scenes/operator_placard.tscn")
const HUD_CLEARANCE   := 240.0  # must match OperatorPlacard.HUD_CLEARANCE

const _OPS := [
	{"op": "+",      "label": "+", "color": Color(0.30, 0.85, 0.45)},
	{"op": "-",      "label": "−", "color": Color(0.40, 0.65, 1.00)},
	{"op": "*",      "label": "×", "color": Color(1.00, 0.75, 0.20)},
	{"op": "/",      "label": "÷", "color": Color(0.90, 0.40, 0.35)},
	{"op": "cancel", "label": "✕", "color": Color(0.72, 0.72, 0.72)},
]

var _placards: Array = []
var _parent: Node2D = null

func activate(near_pos: Vector2, parent: Node2D, live_cards: Array) -> void:
	_parent = parent
	_spawn_placards(near_pos, live_cards)

func deactivate() -> void:
	for p in _placards:
		if is_instance_valid(p):
			p.queue_free()
	_placards.clear()
	_parent = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if _placards.size() > 0:
			deactivate()
			emit_signal("cancelled")

func _spawn_placards(near_pos: Vector2, live_cards: Array) -> void:
	var vp         := get_viewport().get_visible_rect().size
	var base_angle := randf_range(0.0, TAU)

	for i in _OPS.size():
		var info: Dictionary = _OPS[i]
		var p: OperatorPlacard = PLACARD_SCENE.instantiate()
		p.setup(info["op"], info["label"], info["color"])
		p.z_index = 5

		# Target: evenly-spaced ring around the merge point with jitter
		var angle      := base_angle + i * (TAU / _OPS.size()) + randf_range(-0.25, 0.25)
		var dist       := randf_range(160.0, 240.0)
		var target_pos := near_pos + Vector2(cos(angle), sin(angle)) * dist
		# Push target out of any card's personal space before the placard starts steering
		for card in live_cards:
			if not is_instance_valid(card):
				continue
			var away := target_pos - (card as Card).get_center()
			var d    := away.length()
			if d < 95.0:
				target_pos += away.normalized() * (95.0 - d)
		target_pos = target_pos.clamp(Vector2(45.0, HUD_CLEARANCE), vp - Vector2(45.0, 45.0))

		# Start off-screen at a random edge, with a random rotation
		p.global_position = _random_edge_pos(vp)
		p.rotation        = randf_range(-PI, PI)
		# Don't start physics yet — start_seeking enables kinematic when it fires
		p.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		p.freeze      = true

		_parent.add_child(p)
		p.selected.connect(_on_placard_selected)
		_placards.append(p)

		# Stagger launch so they don't all rush in at once
		var tw := create_tween()
		tw.tween_interval(i * 0.12)
		tw.tween_callback(func() -> void:
			if is_instance_valid(p):
				p.start_seeking(target_pos, live_cards)
		)


func _random_edge_pos(vp: Vector2) -> Vector2:
	match randi() % 4:
		0: return Vector2(randf_range(0.0, vp.x), -80.0)
		1: return Vector2(randf_range(0.0, vp.x), vp.y + 80.0)
		2: return Vector2(-80.0, randf_range(0.0, vp.y))
		_: return Vector2(vp.x + 80.0, randf_range(0.0, vp.y))

func _on_placard_selected(op: String) -> void:
	deactivate()
	if op == "cancel":
		emit_signal("cancelled")
	else:
		emit_signal("operator_selected", op)
