class_name AtomFamily
extends RefCounted

var _factory: Callable
var _cache: Dictionary = {}
var _should_remove: Callable


func _init(factory: Callable) -> void:
	_factory = factory


## Return cached atom for param, or create one via factory if not cached.
func get(param) -> Atom:
	if _should_remove.is_valid() and _cache.has(param):
		if _should_remove.call(param, _cache[param]):
			_cache.erase(param)

	if not _cache.has(param):
		_cache[param] = _factory.call(param)

	return _cache[param]


## Remove atom from cache. Does not free it — any held references remain valid.
func remove(param) -> void:
	_cache.erase(param)


func has(param) -> bool:
	return _cache.has(param)


func params() -> Array:
	return _cache.keys()


func clear() -> void:
	_cache.clear()


## Set eviction predicate: func(param, atom: Atom) -> bool.
## Called on each get() before returning. If true, atom is evicted and recreated fresh.
##   family.set_should_remove(func(param, _atom): return not EntityManager.has(param))
func set_should_remove(predicate: Callable) -> void:
	_should_remove = predicate
