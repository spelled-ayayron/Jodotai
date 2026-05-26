class_name WritableAtom
extends DerivedAtom

var _write: Callable


func _init(read: Callable, write: Callable) -> void:
	super(read)
	_write = write


func set_value(new_value) -> void:
	_write.call(new_value)
