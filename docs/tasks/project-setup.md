# Project Setup

## Goal

Initialize the Godot 4.x project with the planned directory layout, a working `project.godot`, and the `GameManager` autoload registered. After this task, the project opens in Godot without errors and the directory skeleton is in place.

## Design

Create `project.godot` at the repo root (or confirm it already exists) and populate the planned directories:

```
card-24/
├── project.godot
├── scenes/
│   ├── screens/
├── scripts/
└── assets/
    ├── cards/
    └── ui/
```

Register `GameManager` as an autoload singleton in `project.godot`:
```
[autoload]
GameManager="*res://scripts/game_manager.gd"
```

Add placeholder stub files so Godot doesn't report missing script errors:
- `scripts/game_manager.gd` — empty `extends Node` class
- `scripts/card.gd` — empty `extends Node2D`
- `scripts/operator_popup.gd` — empty `extends Control`
- `scripts/solver.gd` — empty `extends RefCounted`

## How to Verify

1. Open the project in Godot 4 — no errors in the Output panel.
2. `GameManager` appears in Project → Autoload settings.
3. All stub scripts exist and parse without errors (Scene → Reload All Scripts).

## Dependencies

None — first task, no upstream dependencies.
