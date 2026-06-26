# Card-24 — Progress Log

How each task is actually being carried out — what was done and how, key
decisions, what works, what doesn't, and notes for dependent tasks. TASKS.md holds
the authoritative status (the checkboxes); this file is the narrative beside it.

One `##` section per task, named by the kebab task name. Read this before starting
a task; update your own section as you work. Append entries — don't rewrite them.

## project-setup
**Status:** not started
**Updated:** —

- Goal: Initialize Godot 4.x project, directory skeleton, and GameManager autoload stub.

## card-scene
**Status:** not started
**Updated:** —

- Goal: Create reusable Card PackedScene with coloured rect, value label, and Area2D.

## game-manager
**Status:** not started
**Updated:** —

- Goal: Autoload singleton with card state, deal logic, and win/lose signals.

## operator-popup
**Status:** not started
**Updated:** —

- Goal: Modal overlay with four operator buttons that emits the chosen operator.

## drag-and-drop
**Status:** not started
**Updated:** —

- Goal: Mouse drag input on Card with overlap detection and snap-back on miss.

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
