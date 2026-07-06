# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with 
code in this repository.

## Project

Card-24 is a single-player desktop puzzle game built with 
**Godot 4.x / GDScript**. The player drags four playing cards onto each other, 
picks arithmetic operators, and tries to reduce all cards to a single card with 
the value 24.

The Godot project files (`project.godot`, `scenes/`, `scripts/`, `assets/`) do 
not exist yet — this repo currently holds only the design spec and task plan. 
See `docs/design.md` for the full design and `docs/TASKS.md` for the 
implementation plan.

## No build/test commands yet

There are no scripts, Makefile, or CI pipeline. Once `project.godot` is created, 
the game is run and tested interactively through the Godot 4 editor.

## Architecture

### Core data flow

`GameManager` (autoload singleton, `scripts/game_manager.gd`) owns all game 
state: the `cards` array, `round`, and `score`. Everything else is driven by 
its signals:

- `round_started(card_data)` → Main scene spawns Card nodes into CardSlots
- `game_won` → WinScreen appears, score increments
- `game_lost` → LoseScreen appears

No scene holds its own copy of game state — they read from `GameManager` on 
signal.

### Merge flow

The merge is a coroutine sequence owned by the Main scene script acting as 
`MergeHandler`:

1. Card emits `dropped_on(source, target)` after a successful drag
2. MergeHandler shows `OperatorPopup` and `await`s either `operator_selected` 
   or `cancelled`
3. On selection: compute result, spawn result Card, `queue_free()` both sources, 
   call `GameManager.on_merge(idx_a, idx_b, result)`
4. GameManager removes the two entries by index and checks win/lose

### Key conventions

- `card.gd` must declare `class_name Card` — it is used as a type in 
  `if child is Card` and typed signal handlers
- `solver.gd` must declare `class_name Solver` — called as 
  `Solver.can_reach_24(vals)` from GameManager
- `GameManager.on_merge` takes **indices**, not values, to avoid ambiguity with 
  duplicate card values (e.g. `[6, 6, 4, 4]`)
- Display strings for card values use `_format_value(v)` which strips trailing 
  `.0`; do not use bare `str(float)` for display
- `OperatorPopup` emits both `operator_selected(op)` and `cancelled` — the merge 
  handler must handle both or cards get locked non-interactive permanently
- `Area2D` on Card nodes requires `monitoring = true` (Godot 4 editor default) 
  for `get_overlapping_areas()` to work

### Planned directory layout

```
scenes/
  main.tscn              — root scene; hosts GameBoard, OperatorPopup, HUD, 
						   overlays
  card.tscn              — reusable Card PackedScene (instanced per round)
  operator_popup.tscn
  hud.tscn
  screens/
	win_screen.tscn
	lose_screen.tscn
scripts/
  game_manager.gd        — autoload singleton
  card.gd                — class_name Card; drag-and-drop + merge signal
  operator_popup.gd
  solver.gd              — class_name Solver; optional solvability check
assets/
  cards/
  ui/
docs/
  design.md              — full game design spec
  TASKS.md               — task plan with dependency graph
  tasks/                 — one spec file per task
  progress.md            — execution log
```

## Task plan

Implementation is tracked in `docs/TASKS.md`. Read `docs/progress.md` before 
starting any task — it records decisions and gotchas from prior work. Run 
`/tasks:tasks-next` to see what's currently unblocked.
