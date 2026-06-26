# Main Scene Assembly

## Goal

Wire all sub-scenes into `scenes/main.tscn` to produce a fully playable end-to-end game: deal four cards, merge them down to one, handle win/lose, and loop.

## Design

Scene tree:
```
Main (Node2D)  ←  scripts/main.gd
├── GameBoard (Node2D)
│   └── CardSlots (Node2D)   — four anchored positions for initial card layout
├── OperatorPopup (instanced from scenes/operator_popup.tscn)
├── HUD (instanced from scenes/hud.tscn)
├── WinScreen (instanced from scenes/screens/win_screen.tscn)
└── LoseScreen (instanced from scenes/screens/lose_screen.tscn)
```

`main.gd` is the MergeHandler described in `card-merge.md`. It also:
- Connects to `GameManager.round_started` to spawn Card instances into CardSlots.
- Positions the four cards at the four CardSlot positions on deal.
- Calls `GameManager.deal_new_round()` on `_ready()` to start the first round.

```gdscript
extends Node2D

const CARD_SCENE = preload("res://scenes/card.tscn")

@onready var card_slots = $GameBoard/CardSlots
@onready var operator_popup = $OperatorPopup

func _ready() -> void
  GameManager.round_started.connect(_on_round_started)
  GameManager.deal_new_round()

func _on_round_started(card_data: Array) -> void
  # clear any existing card nodes
  for child in get_children():
    if child is Card:
      child.queue_free()
  # spawn a card at each slot position
  var slots = card_slots.get_children()
  for i in range(card_data.size()):
    var c = CARD_SCENE.instantiate()
    c.setup(card_data[i].value, card_data[i].display, card_data[i].suit)
    c.global_position = slots[i].global_position
    c.dropped_on.connect(_on_card_dropped_on)
    add_child(c)
```

`_on_card_dropped_on` is the merge handler from `card-merge.md`.

## Implementation Suggestion

- `CardSlots` can be four `Marker2D` nodes positioned at the corners of the board — no scene needed, just nodes for their position.
- Test the full loop: deal → merge × 3 → win → next round → cards reset.

## How to Verify

1. Run `scenes/main.tscn` — four cards appear on the board.
2. Play through: merge all four cards to 24 — WinScreen appears; click "Next Round" — new cards dealt.
3. Merge to a non-24 result — LoseScreen appears; click "New Deal" — board resets.
4. "New Deal" in HUD also resets mid-round.
5. Round and score labels update correctly throughout.

## Dependencies

- [Card merge](card-merge.md)
- [HUD](hud.md)
- [Win / Lose screens](win-lose-screens.md)
