extends CanvasLayer

signal operator_selected(op: String)
signal cancelled

func _ready() -> void:
	_set_active(false)

func activate() -> void:
	_set_active(true)

func deactivate() -> void:
	_set_active(false)

func _set_active(on: bool) -> void:
	$Bar/ButtonPlus.disabled = not on
	$Bar/ButtonMinus.disabled = not on
	$Bar/ButtonMul.disabled = not on
	$Bar/ButtonDiv.disabled = not on
	$Bar/ButtonCancel.disabled = not on

func _on_button_pressed(op: String) -> void:
	deactivate()
	emit_signal("operator_selected", op)

func _on_cancel_pressed() -> void:
	deactivate()
	emit_signal("cancelled")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if not $Bar/ButtonPlus.disabled:
			deactivate()
			emit_signal("cancelled")
