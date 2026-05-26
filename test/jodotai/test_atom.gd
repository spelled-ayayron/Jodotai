extends GutTest

# --- get_value / set_value ---


func test_atom_holds_initial_value():
	var a = Jodotai.atom(5)
	assert_eq(a.get_value(), 5)


func test_atom_null_initial_value():
	var a = Jodotai.atom()
	assert_null(a.get_value())


func test_atom_set_value_updates():
	var a = Jodotai.atom(0)
	a.set_value(10)
	assert_eq(a.get_value(), 10)


func test_atom_set_value_emits_changed():
	var a = Jodotai.atom(0)
	watch_signals(a)
	a.set_value(1)
	assert_signal_emitted(a, "changed")


func test_atom_set_value_passes_old_and_new_to_signal():
	var a = Jodotai.atom(0)
	watch_signals(a)
	a.set_value(99)
	assert_signal_emitted_with_parameters(a, "changed", [0, 99])


func test_atom_set_same_value_no_signal():
	var a = Jodotai.atom(5)
	watch_signals(a)
	a.set_value(5)
	assert_signal_not_emitted(a, "changed")


# --- reset ---


func test_atom_reset_restores_initial_value():
	var a = Jodotai.atom(10)
	a.set_value(99)
	a.reset()
	assert_eq(a.get_value(), 10)


func test_atom_reset_emits_changed():
	var a = Jodotai.atom(10)
	a.set_value(99)
	watch_signals(a)
	a.reset()
	assert_signal_emitted(a, "changed")


func test_atom_reset_no_signal_when_already_at_initial():
	var a = Jodotai.atom(5)
	watch_signals(a)
	a.reset()
	assert_signal_not_emitted(a, "changed")


# --- subscribe ---


func test_subscribe_callback_receives_old_and_new():
	var a = Jodotai.atom(0)
	var received = []
	a.subscribe(func(old, new_v): received.append([old, new_v]))
	a.set_value(7)
	assert_eq(received.size(), 1)
	assert_eq(received[0], [0, 7])


func test_subscribe_callback_only_called_on_value_change():
	var a = Jodotai.atom(5)
	var count = [0]
	a.subscribe(func(_o, _n): count[0] += 1)
	a.set_value(5)
	assert_eq(count[0], 0)
	a.set_value(6)
	assert_eq(count[0], 1)


func test_subscribe_returns_unsubscribe_callable():
	var a = Jodotai.atom(0)
	var count = [0]
	var unsub = a.subscribe(func(_o, _n): count[0] += 1)
	a.set_value(1)
	unsub.call()
	a.set_value(2)
	assert_eq(count[0], 1)


func test_multiple_subscribers_all_notified():
	var a = Jodotai.atom(0)
	var log = []
	a.subscribe(func(_o, _n): log.append("a"))
	a.subscribe(func(_o, _n): log.append("b"))
	a.set_value(1)
	assert_eq(log.size(), 2)


# --- typed factories ---


func test_bool_factory_holds_value():
	var a = Atom.bool(true)
	assert_eq(a.get_value(), true)
	a.set_value(false)
	assert_eq(a.get_value(), false)


func test_int_factory_holds_value():
	var a = Atom.int(42)
	assert_eq(a.get_value(), 42)


func test_float_factory_holds_value():
	var a = Atom.float(10.0)
	assert_eq(a.get_value(), 10.0)


func test_string_factory_holds_value():
	var a = Atom.string("hello")
	assert_eq(a.get_value(), "hello")


func test_float_atom_accepts_int():
	# TYPE_FLOAT coerces ints, matching GDScript assignment semantics.
	var a = Atom.float(1.0)
	a.set_value(3)
	assert_eq(a.get_value(), 3)


func test_typed_factory_accepts_variant_type():
	var a = Atom.typed(Vector2.ZERO, TYPE_VECTOR2)
	assert_eq(a.get_value(), Vector2.ZERO)
	a.set_value(Vector2(1, 2))
	assert_eq(a.get_value(), Vector2(1, 2))


func test_typed_factory_accepts_script_class():
	var ra = ReactiveArray.new([1, 2])
	var a = Atom.typed(ra, ReactiveArray)
	assert_eq(a.get_value(), ra)


func test_untyped_atom_accepts_anything():
	# Untyped atom does no type check. Start from null so set_value's `==`
	# short-circuit doesn't compare incomparable types (a pre-existing gotcha).
	var a = Jodotai.atom(null)
	a.set_value("now a string")
	assert_eq(a.get_value(), "now a string")
