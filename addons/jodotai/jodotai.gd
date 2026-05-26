extends Node

## Active computation context for dependency auto-tracking.
## Set by DerivedAtom._recompute(); Atom.get_value() registers into it.
var _tracking: DerivedAtom = null

var _cfg: ConfigFile = null
const _STORAGE_PATH := "user://jodotai_store.cfg"


## Create a writable atom.
##   var count = Jodotai.atom(0)
##   count.set_value(count.get_value() + 1)
func atom(initial_value = null) -> Atom:
	return Atom.new(initial_value)


## Create a read-only derived atom. Dependencies auto-tracked via get_value() calls.
##   var doubled = Jodotai.derived(func(): return count.get_value() * 2)
func derived(compute: Callable) -> DerivedAtom:
	return DerivedAtom.new(compute)


## Create a writable derived atom with explicit read and write logic.
##   var celsius = Jodotai.atom(0.0)
##   var fahrenheit = Jodotai.writable(
##       func(): return celsius.get_value() * 9.0 / 5.0 + 32.0,
##       func(v): celsius.set_value((v - 32.0) * 5.0 / 9.0)
##   )
func writable(read: Callable, write: Callable) -> WritableAtom:
	return WritableAtom.new(read, write)


## Create a memoized atom factory keyed by param. Same param returns same atom instance.
##   var enemy_hp = Jodotai.atom_family(func(id): return Jodotai.atom(100))
##   enemy_hp.get("goblin_1").set_value(80)
##   enemy_hp.get("goblin_1")  # same atom
##   enemy_hp.remove("goblin_1")  # evict on death
func atom_family(factory: Callable) -> AtomFamily:
	return AtomFamily.new(factory)


## Create a writable atom that persists its value to user://jodotai_store.cfg.
##   var volume = Jodotai.atom_with_storage("audio/volume", 1.0)
func atom_with_storage(key: String, initial_value = null) -> Atom:
	var stored = _load_stored(key, initial_value)
	var a = Atom.new(stored)
	a.changed.connect(func(_old, new_val): _save_stored(key, new_val))
	return a


func _load_stored(key: String, default_value):
	if _cfg == null:
		_cfg = ConfigFile.new()
		_cfg.load(_STORAGE_PATH)
	return _cfg.get_value("atoms", key, default_value)


func _save_stored(key: String, value) -> void:
	if _cfg == null:
		_cfg = ConfigFile.new()
	_cfg.set_value("atoms", key, value)
	_cfg.save(_STORAGE_PATH)
