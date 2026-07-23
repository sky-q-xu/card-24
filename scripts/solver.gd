class_name Solver
extends RefCounted

static func can_reach_24(values: Array) -> bool:
	for perm in _permutations(values):
		for ops in _op_combos():
			if _try_all_parens(perm, ops):
				return true
	return false

# Returns the human-readable solution string or "".
static func find_solution(values: Array) -> String:
	for perm in _permutations(values):
		for ops in _op_combos():
			var s := _try_all_parens_expr(perm, ops)
			if s != "":
				return s + " = 24"
	return ""

# Returns an Array of step dicts [{a_val, b_val, op, result_val}, ...] or [].
static func find_solution_steps(values: Array) -> Array:
	for perm in _permutations(values):
		for ops in _op_combos():
			var steps: Variant = _steps_all_parens(perm, ops)
			if steps != null:
				return steps
	return []

# ── internal ──────────────────────────────────────────────────────────────────

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

static func _try_all_parens_expr(v: Array, ops: Array) -> String:
	var a := {"v": float(v[0]), "s": _fmt(v[0])}
	var b := {"v": float(v[1]), "s": _fmt(v[1])}
	var c := {"v": float(v[2]), "s": _fmt(v[2])}
	var d := {"v": float(v[3]), "s": _fmt(v[3])}
	var o1: String = ops[0]; var o2: String = ops[1]; var o3: String = ops[2]
	var patterns: Array = [
		_ce(_ce(_ce(a, o1, b), o2, c), o3, d),
		_ce(_ce(a, o1, _ce(b, o2, c)), o3, d),
		_ce(_ce(a, o1, b), o2, _ce(c, o3, d)),
		_ce(a, o1, _ce(_ce(b, o2, c), o3, d)),
		_ce(a, o1, _ce(b, o2, _ce(c, o3, d))),
	]
	for p in patterns:
		if p != null and abs(p.v - 24.0) < 1e-9:
			var s: String = p.s
			if s.begins_with("(") and s.ends_with(")"):
				s = s.substr(1, s.length() - 2)
			return s
	return ""

# Returns Array of step dicts for the first pattern that reaches 24, else null.
static func _steps_all_parens(v: Array, ops: Array) -> Variant:
	var a := float(v[0]); var b := float(v[1])
	var c := float(v[2]); var d := float(v[3])
	var o1: String = ops[0]; var o2: String = ops[1]; var o3: String = ops[2]

	# Pattern 1: ((a op1 b) op2 c) op3 d
	var p1r1: Variant = _op(a, o1, b)
	if p1r1 != null:
		var p1r2: Variant = _op(float(p1r1), o2, c)
		if p1r2 != null:
			var p1r3: Variant = _op(float(p1r2), o3, d)
			if p1r3 != null and abs(float(p1r3) - 24.0) < 1e-9:
				return [
					{"a_val": a, "b_val": b, "op": o1, "result_val": float(p1r1)},
					{"a_val": float(p1r1), "b_val": c, "op": o2, "result_val": float(p1r2)},
					{"a_val": float(p1r2), "b_val": d, "op": o3, "result_val": float(p1r3)},
				]

	# Pattern 2: (a op1 (b op2 c)) op3 d
	var p2rb: Variant = _op(b, o2, c)
	if p2rb != null:
		var p2ra: Variant = _op(a, o1, float(p2rb))
		if p2ra != null:
			var p2r: Variant = _op(float(p2ra), o3, d)
			if p2r != null and abs(float(p2r) - 24.0) < 1e-9:
				return [
					{"a_val": b, "b_val": c, "op": o2, "result_val": float(p2rb)},
					{"a_val": a, "b_val": float(p2rb), "op": o1, "result_val": float(p2ra)},
					{"a_val": float(p2ra), "b_val": d, "op": o3, "result_val": float(p2r)},
				]

	# Pattern 3: (a op1 b) op2 (c op3 d)
	var p3rab: Variant = _op(a, o1, b)
	var p3rcd: Variant = _op(c, o3, d)
	if p3rab != null and p3rcd != null:
		var p3r: Variant = _op(float(p3rab), o2, float(p3rcd))
		if p3r != null and abs(float(p3r) - 24.0) < 1e-9:
			return [
				{"a_val": a, "b_val": b, "op": o1, "result_val": float(p3rab)},
				{"a_val": c, "b_val": d, "op": o3, "result_val": float(p3rcd)},
				{"a_val": float(p3rab), "b_val": float(p3rcd), "op": o2, "result_val": float(p3r)},
			]

	# Pattern 4: a op1 ((b op2 c) op3 d)
	var p4rbc: Variant = _op(b, o2, c)
	if p4rbc != null:
		var p4rbcd: Variant = _op(float(p4rbc), o3, d)
		if p4rbcd != null:
			var p4r: Variant = _op(a, o1, float(p4rbcd))
			if p4r != null and abs(float(p4r) - 24.0) < 1e-9:
				return [
					{"a_val": b, "b_val": c, "op": o2, "result_val": float(p4rbc)},
					{"a_val": float(p4rbc), "b_val": d, "op": o3, "result_val": float(p4rbcd)},
					{"a_val": a, "b_val": float(p4rbcd), "op": o1, "result_val": float(p4r)},
				]

	# Pattern 5: a op1 (b op2 (c op3 d))
	var p5rcd: Variant = _op(c, o3, d)
	if p5rcd != null:
		var p5rbcd: Variant = _op(b, o2, float(p5rcd))
		if p5rbcd != null:
			var p5r: Variant = _op(a, o1, float(p5rbcd))
			if p5r != null and abs(float(p5r) - 24.0) < 1e-9:
				return [
					{"a_val": c, "b_val": d, "op": o3, "result_val": float(p5rcd)},
					{"a_val": b, "b_val": float(p5rcd), "op": o2, "result_val": float(p5rbcd)},
					{"a_val": a, "b_val": float(p5rbcd), "op": o1, "result_val": float(p5r)},
				]

	return null

static func _ce(a: Variant, op: String, b: Variant) -> Variant:
	if a == null or b == null:
		return null
	var val: Variant = null
	match op:
		"+": val = a.v + b.v
		"-": val = a.v - b.v
		"*": val = a.v * b.v
		"/": val = null if b.v == 0.0 else a.v / b.v
	if val == null:
		return null
	return {"v": val, "s": "(%s %s %s)" % [a.s, _sym(op), b.s]}

static func _fmt(v: Variant) -> String:
	match int(roundf(float(v))):
		1:  return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		var i: return str(i)

static func _sym(op: String) -> String:
	match op:
		"+": return "+"
		"-": return "−"
		"*": return "×"
		"/": return "÷"
	return op

static func _op(a: Variant, op: String, b: Variant) -> Variant:
	if a == null or b == null:
		return null
	match op:
		"+": return a + b
		"-": return a - b
		"*": return a * b
		"/": return null if b == 0 else a / b
	return null

static func _op_combos() -> Array:
	var ops := ["+", "-", "*", "/"]
	var result := []
	for o1 in ops:
		for o2 in ops:
			for o3 in ops:
				result.append([o1, o2, o3])
	return result

static func _permutations(arr: Array) -> Array:
	if arr.size() <= 1:
		return [arr.duplicate()]
	var result := []
	for i in arr.size():
		var rest := arr.duplicate()
		var first = rest.pop_at(i)
		for perm in _permutations(rest):
			perm.push_front(first)
			result.append(perm)
	return result
