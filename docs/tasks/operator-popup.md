# Operator Popup

## Goal

Create the `OperatorPopup` scene (`scenes/operator_popup.tscn`) — a modal overlay that presents four operator buttons (+, −, ×, ÷) and emits the chosen operator back to the caller.

## Design

Scene tree:
```
OperatorPopup (Control)  ←  scripts/operator_popup.gd
└── PanelContainer       — semi-transparent background panel
    └── VBoxContainer
        ├── Label        — "Choose operator"
        └── HBoxContainer
            ├── Button   — "+"
            ├── Button   — "−"
            ├── Button   — "×"
            └── Button   — "÷"
```

`operator_popup.gd`:
```gdscript
extends Control

signal operator_selected(op: String)   # emits "+", "-", "*", "/"
signal cancelled

func show_at(pos: Vector2) -> void
  # positions the popup near pos, calls show()

func _on_button_pressed(op: String) -> void
  emit_signal("operator_selected", op)
  hide()

func _input(event: InputEvent) -> void
  if visible and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
    emit_signal("cancelled")
    hide()
```

The popup is hidden by default (`visible = false`). The caller shows it via `show_at()`, connects to `operator_selected`, and disconnects after receiving it. No division-validity check here — the merge step handles that and can re-show the popup if needed.

**Important:** `card-merge.md` awaits `operator_selected` — if the popup closes without emitting it (e.g. Escape key), the merge coroutine would hang with cards locked non-interactive. The `cancelled` signal and `_input` handler above prevent this; `card-merge.md` must also handle the `cancelled` branch (re-enable cards, snap source back).

## How to Verify

1. Add `OperatorPopup` to a test scene; call `show_at(Vector2(200, 200))` — panel appears near that position.
2. Click "+" — `operator_selected` fires with `"+"` and popup hides.
3. The popup is not visible on scene load.

## Dependencies

- [Project setup](project-setup.md)
