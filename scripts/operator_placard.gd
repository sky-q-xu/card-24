class_name OperatorPlacard
extends RigidBody2D

signal selected(op: String)

var op: String = ""
var input_enabled: bool = false

var _target_pos: Vector2  = Vector2.ZERO
var _live_cards: Array    = []
var _seeking: bool        = false
var _elapsed: float       = 0.0
var _path: Array          = []   # Array[Vector2] — current planned route
var _path_idx: int        = 0
var _recalc_timer: float  = 0.0

const MAX_SPEED           := 400.0  # px/s
const ARRIVE_DIST         := 80.0   # slow-down radius near final target
const SETTLE_DIST         := 55.0   # close enough to target → activate
const WAYPOINT_REACH      := 30.0   # close enough to intermediate waypoint → advance
const TIMEOUT             := 8.0
const RECALC_INTERVAL     := 0.05   # seconds between full-path recalculations
const CARD_EDGE_CLEARANCE := 20.0   # px clearance from card edge ← easy to tune
const MAX_SUBDIVIDE_ITERS := 4      # how many times to recursively split blocked segs
const HUD_CLEARANCE       := 240.0  # px from top to clear the HUD bar ← easy to tune

func setup(operator_key: String, label_text: String, bg_color: Color) -> void:
	op = operator_key
	$Panel/Label.text = label_text
	var s := StyleBoxFlat.new()
	s.bg_color = bg_color
	s.corner_radius_top_left    = 12
	s.corner_radius_top_right   = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	s.border_color = Color(0.0, 0.0, 0.0, 0.55)
	$Panel.add_theme_stylebox_override("panel", s)

func start_seeking(target: Vector2, cards: Array) -> void:
	_target_pos   = target
	_live_cards   = cards
	_seeking      = true
	_elapsed      = 0.0
	_recalc_timer = RECALC_INTERVAL  # trigger immediate calculation
	_path         = [global_position, target]
	_path_idx     = 1
	freeze        = false
	mass          = 0.05
	linear_damp   = 0.0
	angular_damp  = 8.0

func _physics_process(delta: float) -> void:
	if not _seeking:
		return

	_elapsed      += delta
	_recalc_timer += delta

	if _elapsed >= TIMEOUT:
		_slide_to_target()
		return

	# Replan the full route from current position
	if _recalc_timer >= RECALC_INTERVAL:
		_recalc_timer = 0.0
		_rebuild_path()

	# Advance path index when close to the current intermediate waypoint
	while _path_idx < _path.size() - 1 \
			and global_position.distance_to(_path[_path_idx]) < WAYPOINT_REACH:
		_path_idx += 1

	var current_wp: Vector2 = _path[_path_idx] if _path_idx < _path.size() else _target_pos
	var to_wp := current_wp - global_position
	var dist_final := global_position.distance_to(_target_pos)
	var speed := MAX_SPEED * minf(dist_final / ARRIVE_DIST, 1.0)

	if to_wp.length() > 0.5:
		linear_velocity = to_wp.normalized() * speed

	if dist_final < SETTLE_DIST:
		_arrive()

# ---------------------------------------------------------------------------
# Path planning
# ---------------------------------------------------------------------------

func _rebuild_path() -> void:
	# Start fresh from current position each recalculation
	var raw := [global_position, _target_pos]

	# Iteratively subdivide blocked segments and insert bypass points
	for _iter in MAX_SUBDIVIDE_ITERS:
		var next: Array = [raw[0]]
		var any_blocked := false
		for i in range(raw.size() - 1):
			var bp: Variant = _segment_bypass(raw[i], raw[i + 1])
			if bp != null:
				next.append(bp)
				any_blocked = true
			next.append(raw[i + 1])
		raw = next
		if not any_blocked:
			break

	_path    = raw
	_path_idx = 1  # [0] is current position; aim for [1] first

func _segment_bypass(from: Vector2, to: Vector2) -> Variant:
	# Returns a bypass Vector2 if segment [from→to] is blocked by a card, else null.
	var path_vec := to - from
	var path_len := path_vec.length()
	if path_len < 1.0:
		return null
	var path_dir := path_vec / path_len
	var perp     := Vector2(-path_dir.y, path_dir.x)

	# Find the first (nearest along path) card whose clearance zone intersects the segment
	var best_along  := INF
	var best_center := Vector2.ZERO
	var best_radius := 0.0

	for card in _live_cards:
		if not is_instance_valid(card):
			continue
		var cc     := (card as Card).get_center()
		var card_r := Vector2(Card.CARD_W * 0.5, Card.CARD_H * 0.5).length()
		var block_r := card_r + CARD_EDGE_CLEARANCE

		var along   := clampf((cc - from).dot(path_dir), 0.0, path_len)
		var closest := from + path_dir * along

		if cc.distance_to(closest) < block_r and along < best_along:
			best_along  = along
			best_center = cc
			best_radius = card_r

	if best_along == INF:
		return null  # clear

	var pivot       := from + path_dir * best_along
	var bypass_dist := best_radius + CARD_EDGE_CLEARANCE

	var wp_a := pivot + perp * bypass_dist
	var wp_b := pivot - perp * bypass_dist

	var vp := get_viewport_rect().size
	wp_a = wp_a.clamp(Vector2(45.0, HUD_CLEARANCE), vp - Vector2(45.0, 45.0))
	wp_b = wp_b.clamp(Vector2(45.0, HUD_CLEARANCE), vp - Vector2(45.0, 45.0))

	# Choose the side requiring the shorter lateral detour
	return wp_a if from.distance_to(wp_a) <= from.distance_to(wp_b) else wp_b

# ---------------------------------------------------------------------------

func _arrive() -> void:
	_seeking        = false
	linear_velocity = Vector2.ZERO
	mass            = 0.3
	linear_damp     = 6.0
	angular_damp    = 6.0
	input_enabled   = true

func _slide_to_target() -> void:
	_seeking        = false
	linear_velocity = Vector2.ZERO
	var tw          := create_tween()
	tw.tween_property(self, "global_position", _target_pos, 0.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		if is_instance_valid(self):
			mass         = 0.3
			linear_damp  = 6.0
			angular_damp = 6.0
			input_enabled = true
	)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		emit_signal("selected", op)
