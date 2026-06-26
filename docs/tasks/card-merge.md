# Card Merge

## Goal

Wire drag-and-drop, operator selection, and GameManager together: when a card is dropped on another, show the OperatorPopup, compute the result, destroy both source cards, and spawn a merged result card in their place.

## Design

A `MergeHandler` node (or logic in the Main scene script) connects to each card's `dropped_on` signal:

```gdscript
func _on_card_dropped_on(source: Card, target: Card) -> void
  # 1. disable dragging on all cards while popup is open
  _set_cards_interactive(false)
  # 2. show popup near the midpoint of source and target
  var mid = (source.global_position + target.global_position) / 2
  operator_popup.show_at(mid)
  # 3. await operator selection (or cancellation via Escape)
  var op = ""
  var result_signal = await [operator_popup.operator_selected, operator_popup.cancelled]
  if result_signal[0] == "cancelled":   # cancelled — abort merge
    source.global_position = source._original_position
    _set_cards_interactive(true)
    return
  op = result_signal[1]
  # 4. compute result
  var result = _apply_op(source.value, target.value, op)
  if result == null:   # invalid (shouldn't happen with current rules — fractions allowed)
    _set_cards_interactive(true)
    return
  # 5. spawn result card at target position
  var merged = CARD_SCENE.instantiate()
  merged.setup(result, _format_value(result), 0)
  merged.global_position = target.global_position
  get_parent().add_child(merged)
  merged.dropped_on.connect(_on_card_dropped_on)
  # 6. destroy source cards
  source.queue_free()
  target.queue_free()
  # 7. notify GameManager — pass source/target indices so it can remove the right entries
  #    even when duplicate values exist (e.g. [6, 6, 4, 4])
  var idx_a = _card_index(source)
  var idx_b = _card_index(target)
  GameManager.on_merge(idx_a, idx_b, result)
  # 8. re-enable remaining cards
  _set_cards_interactive(true)

func _apply_op(a: float, b: float, op: String) -> Variant:
  match op:
    "+": return a + b
    "-": return a - b
    "*": return a * b
    "/": return a / b if b != 0 else null
  return null

func _format_value(v: float) -> String:
  # show whole numbers without trailing decimal ("10" not "10.0")
  if v == floor(v):
    return str(int(v))
  return str(v)

func _card_index(card: Card) -> int:
  # MergeHandler tracks a parallel Array[Card] of live card nodes in spawn order;
  # return the index of `card` in that array so GameManager.on_merge knows which to remove.
  return _live_cards.find(card)

## How to Verify

1. Place two cards (values 6 and 4) in a test scene with OperatorPopup and MergeHandler wired.
2. Drag card 6 onto card 4, pick "×" — a new card with value `24` appears; both originals are gone.
3. Drag card 6 onto card 4, pick "−" — result card shows `2` (6−4).
4. GameManager.cards length decreases by 1 after each merge.
5. When the final card has value 24, `GameManager.game_won` fires.

## Dependencies

- [Card drag-and-drop](drag-and-drop.md)
- [Operator popup](operator-popup.md)
- [GameManager autoload](game-manager.md)
