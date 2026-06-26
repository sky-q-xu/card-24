# HUD

## Goal

Create a `HUD` scene (`scenes/hud.tscn`) that displays the round counter, score, and a "New Deal" button. It reads state from GameManager signals and never holds its own copy of game state.

## Design

Scene tree:
```
HUD (CanvasLayer)  ←  scripts/hud.gd
└── HBoxContainer
    ├── Label   — "Round: %d" % round
    ├── Label   — "Score: %d" % score
    └── Button  — "New Deal"
```

`hud.gd`:
```gdscript
extends CanvasLayer

@onready var round_label: Label = $HBoxContainer/RoundLabel
@onready var score_label: Label = $HBoxContainer/ScoreLabel

func _ready() -> void
  GameManager.round_started.connect(_on_round_started)
  GameManager.game_won.connect(_on_game_won)

func _on_round_started(_cards) -> void
  round_label.text = "Round: %d" % GameManager.round
  score_label.text = "Score: %d" % GameManager.score

func _on_game_won() -> void
  score_label.text = "Score: %d" % GameManager.score

func _on_new_deal_pressed() -> void
  GameManager.deal_new_round()
```

"New Deal" button's `pressed` signal connects to `_on_new_deal_pressed` in the editor or in `_ready`.

## How to Verify

1. Add HUD to a scene alongside GameManager; call `GameManager.deal_new_round()`.
2. Round label reads "Round: 1", score label reads "Score: 0".
3. Simulate a win (trigger `game_won` signal) — score label updates.
4. Press "New Deal" — `deal_new_round()` is called and labels update.

## Dependencies

- [GameManager autoload](game-manager.md)
