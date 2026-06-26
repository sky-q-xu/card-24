# Solver (Optional)

## Goal

Implement a brute-force solvability checker in `scripts/solver.gd` that determines whether a given set of four card values can produce 24. GameManager calls it at deal time and optionally re-deals if no solution exists.

## Design

The search space is at most 7,680 cases (4! orderings × 4³ operator combos × 5 parenthesisation patterns) — trivially fast.

```gdscript
# scripts/solver.gd
class_name Solver   # required for GameManager to call Solver.can_reach_24() by name
extends RefCounted

static func can_reach_24(values: Array) -> bool:
  for perm in _permutations(values):
    for ops in _op_combos():
      if _try_all_parens(perm, ops):
        return true
  return false

# Five parenthesisation patterns for (a, b, c, d) with ops (o1, o2, o3):
#   ((a o1 b) o2 c) o3 d
#   (a o1 (b o2 c)) o3 d
#   (a o1 b) o2 (c o3 d)
#   a o1 ((b o2 c) o3 d)
#   a o1 (b o2 (c o3 d))
static func _try_all_parens(v: Array, ops: Array) -> bool:
  var a = v[0]; var b = v[1]; var c = v[2]; var d = v[3]
  var patterns = [
    _op(_op(_op(a, ops[0], b), ops[1], c), ops[2], d),
    _op(_op(a, ops[0], _op(b, ops[1], c)), ops[2], d),
    _op(_op(a, ops[0], b), ops[1], _op(c, ops[2], d)),
    _op(a, ops[0], _op(_op(b, ops[1], c), ops[2], d)),
    _op(a, ops[0], _op(b, ops[1], _op(c, ops[2], d))),
  ]
  for r in patterns:
    if r != null and abs(r - 24.0) < 1e-9:
      return true
  return false

static func _op(a, op: String, b) -> Variant:
  if a == null or b == null: return null
  match op:
    "+": return a + b
    "-": return a - b
    "*": return a * b
    "/": return null if b == 0 else a / b
  return null
```

`_permutations` and `_op_combos` are standard recursive helpers.

**GameManager integration** (configurable):
```gdscript
const ENSURE_SOLVABLE := true   # set false to allow any deal

func deal_new_round() -> void:
  var vals = _pick_four()
  if ENSURE_SOLVABLE:
    var tries := 0
    while not Solver.can_reach_24(vals) and tries < 100:
      vals = _pick_four()
      tries += 1
  # ... proceed with vals
```

## How to Verify

```gdscript
# In Godot's built-in terminal or a test scene:
assert(Solver.can_reach_24([1, 5, 5, 5]))   # (5-1/5)*5 ... actually 5*(5-1/5)=24 ✓
assert(Solver.can_reach_24([3, 3, 8, 8]))   # 8/(3-8/3) = 24 ✓
assert(not Solver.can_reach_24([1, 1, 1, 1]))
```

## Dependencies

- [GameManager autoload](game-manager.md)
