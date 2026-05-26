extends GutTest

# --- memoization ---

func test_family_creates_atom_on_first_get():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(100))
	assert_not_null(family.get("goblin_1"))


func test_family_returns_initial_value_from_factory():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(100))
	assert_eq(family.get("goblin_1").get_value(), 100)


func test_family_same_param_returns_same_atom():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(0))
	var a1 = family.get("x")
	var a2 = family.get("x")
	assert_true(a1 == a2)


func test_family_different_params_return_different_atoms():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(0))
	var a1 = family.get("x")
	var a2 = family.get("y")
	assert_false(a1 == a2)


func test_family_atom_value_persists_across_gets():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(100))
	family.get("goblin_1").set_value(80)
	assert_eq(family.get("goblin_1").get_value(), 80)


func test_family_factory_receives_param():
	var received = []
	var family = Jodotai.atom_family(func(id):
		received.append(id)
		return Jodotai.atom(0)
	)
	family.get("hero")
	assert_eq(received, ["hero"])


func test_family_factory_called_only_once_per_param():
	var call_count = [0]
	var family = Jodotai.atom_family(func(_id):
		call_count[0] += 1
		return Jodotai.atom(0)
	)
	family.get("x")
	family.get("x")
	family.get("x")
	assert_eq(call_count[0], 1)


# --- has / params / remove / clear ---

func test_family_has_returns_false_before_get():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(0))
	assert_false(family.has("x"))


func test_family_has_returns_true_after_get():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(0))
	family.get("x")
	assert_true(family.has("x"))


func test_family_params_lists_cached_keys():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(0))
	family.get("a")
	family.get("b")
	var p = family.params()
	assert_true(p.has("a"))
	assert_true(p.has("b"))
	assert_eq(p.size(), 2)


func test_family_remove_evicts_cache():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(100))
	family.get("goblin_1").set_value(80)
	family.remove("goblin_1")
	assert_false(family.has("goblin_1"))


func test_family_remove_causes_fresh_atom_on_next_get():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(100))
	family.get("goblin_1").set_value(80)
	family.remove("goblin_1")
	assert_eq(family.get("goblin_1").get_value(), 100)


func test_family_remove_does_not_invalidate_held_reference():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(100))
	var held = family.get("goblin_1")
	held.set_value(80)
	family.remove("goblin_1")
	assert_eq(held.get_value(), 80)


func test_family_clear_removes_all_entries():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(0))
	family.get("a")
	family.get("b")
	family.clear()
	assert_eq(family.params().size(), 0)


# --- set_should_remove ---

func test_family_should_remove_evicts_and_recreates():
	var evict = [false]
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(0))
	family.set_should_remove(func(_p, _a): return evict[0])
	family.get("x").set_value(42)
	evict[0] = true
	assert_eq(family.get("x").get_value(), 0)


func test_family_should_remove_false_keeps_atom():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(0))
	family.set_should_remove(func(_p, _a): return false)
	family.get("x").set_value(42)
	assert_eq(family.get("x").get_value(), 42)


# --- interplay with derived and reactive collections ---

func test_family_atom_works_with_derived():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(100))
	var alive = Jodotai.derived(func(): return family.get("goblin_1").get_value() > 0)
	assert_true(alive.get_value())
	family.get("goblin_1").set_value(0)
	assert_false(alive.get_value())


func test_family_atom_with_reactive_array_value():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(ReactiveArray.new()))
	family.get("player").get_value().push("sword")
	assert_eq(family.get("player").get_value().size(), 1)


func test_family_reactive_array_mutation_triggers_derived():
	var family = Jodotai.atom_family(func(_id): return Jodotai.atom(ReactiveArray.new()))
	var count = Jodotai.derived(func(): return family.get("player").get_value().size())
	assert_eq(count.get_value(), 0)
	family.get("player").get_value().push("sword")
	assert_eq(count.get_value(), 1)
