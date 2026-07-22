class_name Solver
extends RefCounted

static func can_reach_24(values: Array) -> bool:
	for perm in _permutations(values):
		for ops in _op_combos():
			if _try_all_parens(perm, ops):
				return true
	return false

# Returns a human-readable solution string like "(5 + 3) × (K − Q) = 24", or "" if none.
static func find_solution(values: Array) -> String:
	for perm in _permutations(values):
		for ops in _op_combos():
			var s := _try_all_parens_expr(perm, ops)
			if s != "":
				return s + " = 24"
	return ""

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

# Returns the expression string for the first pattern that equals 24, or "".
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
			# Strip outermost parens for readability
			if s.begins_with("(") and s.ends_with(")"):
				s = s.substr(1, s.length() - 2)
			return s
	return ""

# Builds an expression node {v: float, s: String}, or null on failure.
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
