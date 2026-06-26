# Win / Lose Screens

## Goal

Create `WinScreen` and `LoseScreen` CanvasLayer overlays that appear when the game ends, showing the outcome and offering "Next Round" or "New Deal" options.

## Design

Two separate scenes (or one parameterised scene — two is simpler):

**`scenes/screens/win_screen.tscn`**
```
WinScreen (CanvasLayer)
└── CenterContainer
    └── VBoxContainer
        ├── Label    — "You got 24!"
        ├── Label    — "Score: %d" (updated on show)
        └── Button   — "Next Round"
```

**`scenes/screens/lose_screen.tscn`**
```
LoseScreen (CanvasLayer)
└── CenterContainer
    └── VBoxContainer
        ├── Label    — "Not 24."
        └── Button   — "Try Again / New Deal"
```

Both screens are hidden by default. A shared script pattern:

```gdscript
# win_screen.gd
extends CanvasLayer

func _ready() -> void
  hide()
  GameManager.game_won.connect(_show_win)

func _show_win() -> void
  $CenterContainer/VBoxContainer/ScoreLabel.text = "Score: %d" % GameManager.score
  show()

func _on_next_round_pressed() -> void
  hide()
  GameManager.deal_new_round()
```

```gdscript
# lose_screen.gd
extends CanvasLayer

func _ready() -> void
  hide()
  GameManager.game_lost.connect(_show_lose)

func _show_lose() -> void
  show()

func _on_new_deal_pressed() -> void
  hide()
  GameManager.deal_new_round()
```

Both overlays sit above the game board (higher `layer` value on CanvasLayer).

## How to Verify

1. Add both screens to a test scene; emit `GameManager.game_won` — WinScreen appears, LoseScreen stays hidden.
2. Emit `GameManager.game_lost` — LoseScreen appears.
3. Click the action button on either screen — it hides and triggers a new deal.
4. WinScreen score label shows the correct value from `GameManager.score`.

## Dependencies

- [GameManager autoload](game-manager.md)
