extends CanvasLayer

const _CONFETTI_COLORS: Array[Color] = [
	Color(1.0, 0.22, 0.22),  # red
	Color(1.0, 0.85, 0.10),  # yellow
	Color(0.18, 0.80, 0.22), # green
	Color(0.20, 0.60, 1.00), # blue
	Color(0.90, 0.20, 0.90), # magenta
	Color(0.10, 0.85, 0.85), # cyan
]

var _confetti: Array[CPUParticles2D] = []

func _ready() -> void:
	hide()
	GameManager.game_won.connect(_show_win)
	_build_confetti()

func _build_confetti() -> void:
	# 10×6 white rectangle → tinted per-emitter to look like confetti pieces
	var img := Image.create(10, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)

	# Positions are resolved in _show_win once the layer offset is guaranteed set.
	# Build emitters at placeholder position (0,0); _place_confetti moves them.
	for col: Color in _CONFETTI_COLORS:
		for _i in 2:
			var p := CPUParticles2D.new()
			p.emitting = false
			p.one_shot = true
			p.explosiveness = 0.85
			p.amount = 25
			p.lifetime = 5.5
			p.randomness = 0.6
			p.texture = tex
			p.color = col
			p.spread = 60.0
			p.initial_velocity_min = 250.0
			p.initial_velocity_max = 720.0
			p.gravity = Vector2(0.0, 280.0)
			p.angular_velocity_min = -720.0
			p.angular_velocity_max = 720.0
			p.scale_amount_min = 1.5
			p.scale_amount_max = 3.5
			add_child(p)
			_confetti.append(p)

func _place_confetti() -> void:
	# Called from _show_win so CanvasLayer.offset is guaranteed to reflect the
	# value set by main.tscn before we compute screen-space corner positions.
	var lo := offset
	var vp_w := 1152.0
	var vp_h := 648.0
	var corners := [
		{"pos": Vector2(0.0,  vp_h) - lo, "dir": Vector2( 1.0, -1.0).normalized()},
		{"pos": Vector2(vp_w, vp_h) - lo, "dir": Vector2(-1.0, -1.0).normalized()},
	]
	for i in _confetti.size():
		var p: CPUParticles2D = _confetti[i]
		var corner: Dictionary = corners[i % 2]
		p.position = corner["pos"]
		p.direction = corner["dir"]

func _show_win() -> void:
	$CenterContainer/VBoxContainer/ScoreLabel.text = "Score: %d" % GameManager.score
	show()
	_place_confetti()
	for p: CPUParticles2D in _confetti:
		p.restart()

func _on_next_round_pressed() -> void:
	hide()
	GameManager.deal_new_round()
