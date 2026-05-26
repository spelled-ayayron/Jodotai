class_name Atom
extends RefCounted

signal changed(old_value, new_value)

var _value
var _initial_value
## Optional runtime type guard. null = untyped. Otherwise a Variant.Type int
## (TYPE_BOOL…), a native class (Node), or a Script (ReactiveArray, …).
var _type = null


func _init(initial_value = null, type = null) -> void:
	_type = type
	_check(initial_value)
	_initial_value = initial_value
	_value = initial_value
	_connect_reactive(initial_value)


func get_value():
	# Register as dependency if inside a DerivedAtom computation
	if Jodotai._tracking != null:
		Jodotai._tracking._track(self)
	return _value


func set_value(new_value) -> void:
	_check(new_value)
	_disconnect_reactive(_value)
	if new_value == _value:
		_connect_reactive(new_value)
		return
	var old_value = _value
	_value = new_value
	_connect_reactive(new_value)
	changed.emit(old_value, new_value)


func reset() -> void:
	set_value(_initial_value)


## Returns a Callable that unsubscribes when called.
func subscribe(callback: Callable) -> Callable:
	changed.connect(callback)
	return func(): changed.disconnect(callback)


func _connect_reactive(value) -> void:
	if value is Object and value.has_signal("mutated"):
		if not value.mutated.is_connected(_on_value_mutated):
			value.mutated.connect(_on_value_mutated)


func _disconnect_reactive(value) -> void:
	if value is Object and value.has_signal("mutated"):
		if value.mutated.is_connected(_on_value_mutated):
			value.mutated.disconnect(_on_value_mutated)


func _on_value_mutated() -> void:
	# Value mutated in-place — emit changed with same ref so subscribers and derived atoms update
	changed.emit(_value, _value)


# --- Runtime type guard ---

## No-op when untyped. Asserts on mismatch — assert is stripped from release
## exports, so typed atoms cost nothing in shipped builds (debug-only safety).
## TYPE_FLOAT also accepts ints, matching GDScript's implicit int→float coercion.
func _check(value) -> void:
	if _type == null:
		return
	# `_type is int` guards the comparison — a Script/native-class _type is an
	# Object, and `Object == int` throws "Invalid operands" rather than returning false.
	if _type is int and _type == TYPE_FLOAT and value is int:
		return
	assert(is_instance_of(value, _type),
		"Atom type mismatch: expected %s, got value %s (type %d)" % [_type, value, typeof(value)])


# --- Typed factories ---
# Called as Atom.bool(true), Atom.float(10.0), etc. The typed `initial` param
# gives editor checking at construction; get_value() still returns Variant
# (GDScript has no generics, so reads stay untyped — cast at the read site).

static func bool(initial: bool) -> Atom:
	return Atom.new(initial, TYPE_BOOL)


static func int(initial: int) -> Atom:
	return Atom.new(initial, TYPE_INT)


static func float(initial: float) -> Atom:
	return Atom.new(initial, TYPE_FLOAT)


static func string(initial: String) -> Atom:
	return Atom.new(initial, TYPE_STRING)


## Typed atom for any Variant.Type, native class, or Script.
##   Atom.typed(Vector2.ZERO, TYPE_VECTOR2)
##   Atom.typed(ReactiveArray.new(), ReactiveArray)
static func typed(initial, type) -> Atom:
	return Atom.new(initial, type)
