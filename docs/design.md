# Card-24: Project Design Document

## Project Goal

Build a single-player puzzle card game where the player combines four playing cards using arithmetic operations (+, -, *, /) to reach the target value of **24**.

The game tests mental arithmetic and strategic thinking. Each round deals four cards; the player must find an order of operations and card pairings that produces exactly 24.

---

## Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Engine | Godot 4.x | GDScript for game logic |
| Language | GDScript | Native Godot scripting |
| Platform | Desktop (Windows / macOS / Linux) | Initial target; mobile stretch goal |
| Version Control | Git | Project root tracked in repo |

---

## High-Level Game Design

### Card Values

- Standard poker deck (A=1, 2–10 face value, J=11, Q=12, K=13)
- Suits are cosmetic only; only the numeric value matters for computation

### Win Condition

Reduce four cards to a single card whose value equals **24**.

### Lose Condition

If no valid combination of operations can produce 24, the player may request a new deal (no penalty) or quit.

---

## Gameplay Flow

```
Start Round
    │
    ▼
Deal 4 cards (random from deck)
    │
    ▼
┌─────────────────────────────────────────────────┐
│  Player drags Card A onto Card B                │
│  Operator popup appears (+, -, *, /)            │
│  Player selects an operator                     │
│  Card A and Card B merge into one Result Card   │
│  (value = A op B)                               │
└─────────────────────────────────────────────────┘
    │   (repeat while cards > 1)
    ▼
Single card remains
    │
    ├─ value == 24 → Win screen, deal next round
    └─ value != 24 → Fail screen, option to retry or new deal
```

---

## Scene Structure

```
Main (Node2D)
├── GameBoard          — canvas area holding card slots
│   ├── CardSlot x4   — anchored positions for initial card layout
│   └── ResultSlot    — centre area where merged cards land
├── Card (PackedScene) — reusable card scene (instanced 4 times per round)
│   ├── Sprite2D       — card face texture
│   ├── Label          — card value text
│   └── Area2D         — drag-and-drop collision detection
├── OperatorPopup      — modal with four buttons (+, -, *, /)
│   └── ButtonGroup x4
├── HUD                — round counter, score, "New Deal" button
└── WinScreen / LoseScreen (CanvasLayer overlays)
```

---

## Core Systems

### 1. Card Drag-and-Drop

- Each `Card` node uses `InputEventMouseButton` / `InputEventMouseMotion` to handle drag.
- On drop, an `Area2D` overlap check determines whether the card was released on another card.
- If a valid target card is detected, trigger the **Operator Selection** flow.

### 2. Operator Selection

- `OperatorPopup` is shown as a modal overlay.
- Player taps one of four buttons: `+`, `-`, `*`, `/`.
- Division is allowed only when the result is a whole number (integer check before confirming).
- If the operation is invalid (e.g. division with non-integer result), show an error hint and keep the popup open for re-selection, or let the player cancel.

### 3. Card Merge

- Compute `result = value_a op value_b`.
- Destroy both source cards.
- Spawn a new `Card` instance at the drop position with `value = result`.
- Remaining cards re-centre on the board.

### 4. Round Management (`GameManager` autoload)

- Tracks current card values in an array.
- Detects win/lose state after each merge.
- Provides `deal_new_round()` which picks 4 random values and resets the board.
- Optionally validates upfront whether a solution exists (using brute-force search over all operator/order permutations) to avoid unwinnable deals if desired.

### 5. Solvability Check (optional / configurable)

A recursive solver can enumerate all:
- Permutations of 4 card values (4! = 24)
- Combinations of 3 operators (4^3 = 64)
- Parenthesisation patterns (Catalan number C(3) = 5)

Total search space: ≤ 7680 cases — trivially fast at deal time.

---

## Data Model

```
Card:
  value: float       # current computed value
  display: String    # shown on card face (e.g. "A", "7", "Q")
  suit: int          # cosmetic (0=♠ 1=♥ 2=♦ 3=♣)

GameState:
  cards: Array[Card]      # 3 → 2 → 1 cards as merges happen
  round: int
  score: int              # optional: track solved rounds
```

---

## Directory Layout (planned)

```
card-24/
├── docs/
│   └── design.md          ← this file
├── project.godot
├── scenes/
│   ├── main.tscn
│   ├── card.tscn
│   ├── operator_popup.tscn
│   ├── hud.tscn
│   └── screens/
│       ├── win_screen.tscn
│       └── lose_screen.tscn
├── scripts/
│   ├── game_manager.gd    (autoload singleton)
│   ├── card.gd
│   ├── operator_popup.gd
│   └── solver.gd          (optional solvability check)
└── assets/
    ├── cards/             ← card face textures
    └── ui/                ← buttons, backgrounds
```

---

## Decisions

| # | Topic | Decision |
|---|---|---|
| 1 | Intermediate values | Negative and fractional intermediates are allowed (standard 24-game rules) |
| 2 | Card art | Plain coloured rectangles with value labels — no sprite sheet needed |
| 3 | Solvability | Unsolvable deals are allowed; player can request a re-deal at any time |
| 4 | Division | Fractions are allowed throughout; no integer-only restriction |
