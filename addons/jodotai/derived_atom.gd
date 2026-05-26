class_name DerivedAtom
extends Atom

var _compute: Callable
var _deps: Array = []


func _init(compute: Callable) -> void:
	super(null)
	_compute = compute
	_recompute()


## Called by Atom.get_value() when this derived atom is the active computation.
func _track(dep: Atom) -> void:
	if dep not in _deps:
		_deps.append(dep)
		dep.changed.connect(_on_dep_changed)


func _on_dep_changed(_old, _new) -> void:
	_recompute()


func _recompute() -> void:
	# Disconnect stale deps before re-tracking
	for dep in _deps:
		if dep.changed.is_connected(_on_dep_changed):
			dep.changed.disconnect(_on_dep_changed)
	_deps.clear()

	# Push this atom as the active computation so get_value() calls auto-register deps
	var prev_tracking = Jodotai._tracking
	Jodotai._tracking = self
	var new_value = _compute.call()
	Jodotai._tracking = prev_tracking

	if new_value != _value:
		var old_value = _value
		_value = new_value
		changed.emit(old_value, new_value)


func set_value(_new_value) -> void:
	push_warning("DerivedAtom is read-only. Use Jodotai.writable(read, write) for writable derived atoms.")
