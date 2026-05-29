class_name ReactiveDict
extends RefCounted

signal mutated

var _data: Dictionary = {}

## Read-only view of the underlying dictionary. Use mutation methods to trigger signals.
var data: Dictionary:
	get: return _data


func _init(initial: Dictionary = {}) -> void:
	_data = initial.duplicate()


# --- Mutation methods (each emits mutated) ---

func put(key, value) -> void:
	_data[key] = value
	mutated.emit()


func erase(key) -> void:
	_data.erase(key)
	mutated.emit()


func clear() -> void:
	_data.clear()
	mutated.emit()


func merge(dict: Dictionary, overwrite: bool = false) -> void:
	_data.merge(dict, overwrite)
	mutated.emit()


# --- Read methods (no signal) ---

func get_at(key, default = null) -> Variant:
	return _data.get(key, default)


func has(key) -> bool:
	return _data.has(key)


func has_all(keys: Array) -> bool:
	return _data.has_all(keys)


func keys() -> Array:
	return _data.keys()


func values() -> Array:
	return _data.values()


func size() -> int:
	return _data.size()


func is_empty() -> bool:
	return _data.is_empty()


func find_key(value) -> Variant:
	return _data.find_key(value)


func duplicate(deep: bool = false) -> ReactiveDict:
	return ReactiveDict.new(_data.duplicate(deep))


# --- Iteration support: `for key in reactive_dict` (iterates keys, matching GDScript dict behavior) ---

var _iter_keys_cache: Array = []


func _iter_init(iter) -> bool:
	_iter_keys_cache = _data.keys()
	iter[0] = 0
	return _iter_keys_cache.size() > 0


func _iter_next(iter) -> bool:
	iter[0] += 1
	return iter[0] < _iter_keys_cache.size()


func _iter_get(iter) -> Variant:
	return _iter_keys_cache[iter]


func _to_string() -> String:
	return str(_data)
