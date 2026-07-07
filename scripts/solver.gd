class_name Solver
extends RefCounted

static func can_reach_24(values: Array) -> bool:
	for perm in _permutations(values):
		for ops in _op_combos():
			if _try_all_parens(perm, ops):
				return true
	return false

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
