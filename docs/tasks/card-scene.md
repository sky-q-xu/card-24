# Card Scene

## Goal

Create a reusable `Card` PackedScene (`scenes/card.tscn`) with a visual card body, a value label, and an Area2D for collision. The scene is self-contained and can be instanced multiple times per round.

## Design

Scene tree:
```
Card (Node2D)  ←  scripts/card.gd
├── Panel           — coloured rectangle (the card body)
│   └── Label       — displays value ("A", "7", "Q", etc.) and suit tint via modulate
└── Area2D          — overlap detection for drop targeting
    └── CollisionShape2D  — rectangle matching Panel size
```

`card.gd` exposes:
```gdscript
class_name Card   # required — other scripts use Card as a type literal

var value: float        # computed card value
var display: String     # shown on label ("A", "7", "J", "Q", "K")
var suit: int           # 0=♠ 1=♥ 2=♦ 3=♣  (cosmetic only)

func setup(v: float, d: String, s: int) -> void
```

`setup()` sets `value`, `display`, `suit`, updates the Label text, and applies a subtle `modulate` tint per suit (e.g. red for hearts/diamonds, default for spades/clubs). Card art is a plain coloured `Panel` — no texture needed.

## How to Verify

1. Instance `card.tscn` in a test scene; call `setup(7, "7", 1)`.
2. The card renders as a coloured rectangle with "7" centred on it.
3. A heart/diamond card has a reddish tint; spades/clubs are default.
4. Area2D CollisionShape2D covers the full card body.

## Dependencies

- [Project setup](project-setup.md)
