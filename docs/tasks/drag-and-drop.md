# Card Drag-and-Drop

## Goal

Add mouse drag-and-drop behaviour to `card.gd` so a card can be picked up, dragged freely, and detected as dropped onto another card.

## Design

Extend `card.gd` with drag input handling:

```gdscript
signal dropped_on(source: Card, target: Card)   # emitted on the card that was dragged

var _dragging: bool = false
var _drag_offset: Vector2
var _original_position: Vector2

func _is_mouse_over() -> bool:
  var rect = $Panel.get_global_rect()
  return rect.has_point(get_viewport().get_mouse_position())

func _input(event: InputEvent) -> void
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_LEFT:
      if event.pressed and _is_mouse_over():
        _original_position = global_position
        _dragging = true
        _drag_offset = global_position - event.global_position
        z_index = 10        # float above other cards
      else:
        if _dragging:
          _dragging = false
          z_index = 0
          _check_drop()

  if event is InputEventMouseMotion and _dragging:
    global_position = event.global_position + _drag_offset

func _check_drop() -> void
  # Area2D must have monitoring = true (the Godot 4 editor default)
  for area in $Area2D.get_overlapping_areas():
    var target = area.get_parent()
    if target != self and target is Card:
      emit_signal("dropped_on", self, target)
      return
  # no target: snap back
  global_position = _original_position
```

Store `_original_position` when drag starts; restore it if no valid target is found on drop.

## How to Verify

1. Spawn two cards in a test scene.
2. Drag card A over card B and release — `dropped_on(A, B)` fires.
3. Drag card A to empty space and release — card snaps back to its original position.
4. During drag, card renders above other cards (z_index raised).

## Dependencies

- [Card scene](card-scene.md)
