# GameManager Autoload

## Goal

Implement the `GameManager` autoload singleton (`scripts/game_manager.gd`) with the full game state, deal logic, and win/lose detection. Other systems read state and connect to signals from this node.

## Design

```gdscript
extends Node

signal round_started(card_data: Array)   # emitted after deal; payload: [{value, display, suit}, ...]
signal game_won
signal game_lost                          # no valid 24 — player may re-deal

var cards: Array        # Array of {value: float, display: String, suit: int}
var round: int = 0
var score: int = 0

func deal_new_round() -> void
  # pick 4 random values from a standard deck pool (A=1..K=13)
  # populate `cards`, increment `round`, emit round_started

func on_merge(idx_a: int, idx_b: int, result: float) -> void
  # called by card-merge after each combine; removes the two source entries
  # by index (higher index first to avoid offset shift) and appends the result.
  # Passing indices avoids ambiguity when duplicate card values exist (e.g. [6,6,4,4]).
  # display is formatted via _format_value so intermediate results show "10" not "10.0".
  # then checks win/lose:
  #   len(cards)==1 && cards[0].value==24 → score++, emit game_won
  #   len(cards)==1 && cards[0].value!=24 → emit game_lost

func _value_to_display(v: int) -> String
  # maps 1→"A", 11→"J", 12→"Q", 13→"K", else str(v)
```

`deal_new_round()` draws 4 values independently and uniformly from 1–13 (with replacement — no real deck tracking needed for this game).

## How to Verify

In a GDScript test or the Godot REPL:
1. `GameManager.deal_new_round()` — `GameManager.cards` has 4 entries, `round == 1`.
2. Simulate two merges manually via `on_merge(0, 1, result)` reducing to one card with value 24 — `game_won` signal fires and `score == 1`.
3. Same with a non-24 final value — `game_lost` fires, score unchanged.
4. `_value_to_display(1)` → `"A"`, `_value_to_display(12)` → `"Q"`, `_value_to_display(7)` → `"7"`.

## Dependencies

- [Project setup](project-setup.md)
