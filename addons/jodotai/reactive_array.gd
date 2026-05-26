class_name ReactiveArray
extends RefCounted

signal mutated

var _data: Array = []

## Read-only view of the underlying array. Use mutation methods to trigger signals.
var data: Array:
	get: return _data


func _init(initial: Array = []) -> void:
	_data = initial.duplicate()


# --- Mutation methods (each emits mutated) ---

func push(value) -> void:
	_data.push_back(value)
	mutated.emit()


func push_front(value) -> void:
	_data.push_front(value)
	mutated.emit()


func pop() -> Variant:
	var v = _data.pop_back()
	mutated.emit()
	return v


func pop_front() -> Variant:
	var v = _data.pop_front()
	mutated.emit()
	return v


func insert(idx: int, value) -> void:
	_data.insert(idx, value)
	mutated.emit()


func remove_at(idx: int) -> void:
	_data.remove_at(idx)
	mutated.emit()


func erase(value) -> void:
	_data.erase(value)
	mutated.emit()


func set_at(idx: int, value) -> void:
	_data[idx] = value
	mutated.emit()


func clear() -> void:
	_data.clear()
	mutated.emit()


func sort() -> void:
	_data.sort()
	mutated.emit()


func sort_custom(fn: Callable) -> void:
	_data.sort_custom(fn)
	mutated.emit()


func reverse() -> void:
	_data.reverse()
	mutated.emit()


func resize(new_size: int) -> void:
	_data.resize(new_size)
	mutated.emit()


func append_array(arr: Array) -> void:
	_data.append_array(arr)
	mutated.emit()


func fill(value) -> void:
	_data.fill(value)
	mutated.emit()


func assign(arr: Array) -> void:
	_data.assign(arr)
	mutated.emit()


# --- Read methods (no signal) ---

func get_at(idx: int) -> Variant:
	return _data[idx]


func size() -> int:
	return _data.size()


func is_empty() -> bool:
	return _data.is_empty()


func has(value) -> bool:
	return _data.has(value)


func find(value, from: int = 0) -> int:
	return _data.find(value, from)


func rfind(value, from: int = -1) -> int:
	return _data.rfind(value, from)


func slice(begin: int, end: int = 2147483647, step: int = 1) -> Array:
	return _data.slice(begin, end, step)


func duplicate(deep: bool = false) -> ReactiveArray:
	return ReactiveArray.new(_data.duplicate(deep))


# --- Iteration support: `for item in reactive_array` ---

func _iter_init(iter: Array) -> bool:
	iter[0] = 0
	return _data.size() > 0


func _iter_next(iter: Array) -> bool:
	iter[0] += 1
	return iter[0] < _data.size()


func _iter_get(iter) -> Variant:
	return _data[iter]
