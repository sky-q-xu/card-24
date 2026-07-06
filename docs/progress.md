# Card-24 — Progress Log

How each task is actually being carried out — what was done and how, key
decisions, what works, what doesn't, and notes for dependent tasks. TASKS.md holds
the authoritative status (the checkboxes); this file is the narrative beside it.

One `##` section per task, named by the kebab task name. Read this before starting
a task; update your own section as you work. Append entries — don't rewrite them.

## project-setup
**Status:** done
**Updated:** 2026-06-26

- Created `project.godot` (config_version=5) with `config/name="Card-24"` and `GameManager` registered as autoload via `"*res://scripts/game_manager.gd"`.
- Created directory skeleton: `scenes/`, `scenes/screens/`, `scripts/`, `assets/cards/`, `assets/ui/`. Empty dirs tracked with `.gitkeep`.
- Created four stub scripts in `scripts/`: `game_manager.gd` (extends Node), `card.gd` (class_name Card, extends Node2D), `operator_popup.gd` (class_name OperatorPopup, extends Control), `solver.gd` (class_name Solver, extends RefCounted).
- No gotchas. Verify by opening the project in Godot 4 — Output panel should be clean and GameManager should appear under Project → Autoload.

## card-scene
**Status:** done
**Updated:** 2026-06-26

- Created `scenes/card.tscn`: Card (Node2D) → Panel (80×120) → Label + Area2D (monitoring=true) → CollisionShape2D (RectangleShape2D 80×120, centered at 40,60).
- Implemented `scripts/card.gd`: `setup(v, d, s)` sets value/display/suit, updates Label text, applies red modulate tint for hearts/diamonds (suits 1 and 2).
- `monitoring = true` set explicitly on Area2D per CLAUDE.md convention — required for `get_overlapping_areas()` in drag-and-drop.
- Label uses `anchors_preset=15` (full rect) inside Panel so the value is centred automatically.

## game-manager
**Status:** done
**Updated:** 2026-07-01

- Created `scripts/game_manager.gd`: signals (`round_started`, `game_won`, `game_lost`), state (`cards`, `round`, `score`), `deal_new_round()`, `_value_to_display()`, `_format_value()`.
- `on_merge(idx_a, idx_b, result)`: removes higher index first (via `maxi`/`mini`) to avoid index shift, appends result card, checks win with epsilon `abs(v - 24.0) < 0.0001` to handle float drift from chained division.
- Project moved from `/Users/skyxu/src/card-24` to `/Users/skyxu/Documents/github/card-24` during this task.

## operator-popup
**Status:** done
**Updated:** 2026-06-26

- Created `scenes/operator_popup.tscn`: OperatorPopup (Control, visible=false) → PanelContainer → VBoxContainer → Label + HBoxContainer → 4 Buttons (+, −, ×, ÷).
- Button `pressed` signals connected to `_on_button_pressed` with string binds in tscn.
- Implemented `scripts/operator_popup.gd`: `show_at(pos)`, `_on_button_pressed(op)`, `_input` for Escape key → emits `cancelled`.
- Both `operator_selected` and `cancelled` signals present — card-merge must handle both or merge coroutine will hang.

## drag-and-drop
**Status:** done
**Updated:** 2026-07-01

- Extended `scripts/card.gd`: added `dropped_on` signal, `_dragging`, `_drag_offset`, `_original_position` vars, `_is_mouse_over()`, `_input()`, and `_check_drop()`.
- `_drag_offset` stores `global_position - event.global_position` at pick-up so the card moves naturally under the cursor.
- `_check_drop()` iterates `$Area2D.get_overlapping_areas()`, gets each area's parent, emits `dropped_on(self, target)` if a Card is found, else snaps back to `_original_position`.
- `z_index = 10` on pick-up ensures dragged card renders above others.

## card-merge
**Status:** not started
**Updated:** —

- Goal: Full merge flow — popup → compute → destroy sources → spawn result → notify GameManager.

## hud
**Status:** not started
**Updated:** —

- Goal: CanvasLayer HUD showing round, score, and "New Deal" button wired to GameManager signals.

## win-lose-screens
**Status:** not started
**Updated:** —

- Goal: WinScreen and LoseScreen CanvasLayer overlays triggered by GameManager game_won / game_lost.

## main-scene
**Status:** not started
**Updated:** —

- Goal: Assemble all sub-scenes into Main; deal cards into CardSlots; full end-to-end game loop.

## solver
**Status:** not started
**Updated:** —

- Goal: Brute-force solvability checker (optional); GameManager calls it at deal time when ENSURE_SOLVABLE is true.
