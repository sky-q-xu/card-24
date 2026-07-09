class_name OperatorPopup
extends Control

signal operator_selected(op: String)
signal cancelled

func show_at(pos: Vector2) -> void:
	position = pos
	show()

func _on_button_pressed(op: String) -> void:
	emit_signal("operator_selected", op)
	hide()

func _on_cancel_pressed() -> void:
	emit_signal("cancelled")
	hide()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		emit_signal("cancelled")
		hide()
