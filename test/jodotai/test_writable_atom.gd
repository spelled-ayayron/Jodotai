extends GutTest

# --- read ---

func test_writable_reads_via_read_callable():
	var celsius = Jodotai.atom(0.0)
	var fahrenheit = Jodotai.writable(
		func(): return celsius.get_value() * 9.0 / 5.0 + 32.0,
		func(v): celsius.set_value((v - 32.0) * 5.0 / 9.0)
	)
	assert_eq(fahrenheit.get_value(), 32.0)


func test_writable_recomputes_when_base_changes():
	var celsius = Jodotai.atom(0.0)
	var fahrenheit = Jodotai.writable(
		func(): return celsius.get_value() * 9.0 / 5.0 + 32.0,
		func(v): celsius.set_value((v - 32.0) * 5.0 / 9.0)
	)
	celsius.set_value(100.0)
	assert_eq(fahrenheit.get_value(), 212.0)


func test_writable_emits_changed_when_base_changes():
	var celsius = Jodotai.atom(0.0)
	var fahrenheit = Jodotai.writable(
		func(): return celsius.get_value() * 9.0 / 5.0 + 32.0,
		func(v): celsius.set_value((v - 32.0) * 5.0 / 9.0)
	)
	watch_signals(fahrenheit)
	celsius.set_value(100.0)
	assert_signal_emitted(fahrenheit, "changed")


# --- write ---

func test_writable_set_value_updates_base_atom():
	var celsius = Jodotai.atom(0.0)
	var fahrenheit = Jodotai.writable(
		func(): return celsius.get_value() * 9.0 / 5.0 + 32.0,
		func(v): celsius.set_value((v - 32.0) * 5.0 / 9.0)
	)
	fahrenheit.set_value(212.0)
	assert_eq(celsius.get_value(), 100.0)


func test_writable_read_reflects_after_write():
	var celsius = Jodotai.atom(0.0)
	var fahrenheit = Jodotai.writable(
		func(): return celsius.get_value() * 9.0 / 5.0 + 32.0,
		func(v): celsius.set_value((v - 32.0) * 5.0 / 9.0)
	)
	fahrenheit.set_value(32.0)
	assert_eq(celsius.get_value(), 0.0)
	assert_eq(fahrenheit.get_value(), 32.0)


func test_writable_write_triggers_downstream_derived():
	var base = Jodotai.atom(0)
	var doubled = Jodotai.writable(
		func(): return base.get_value() * 2,
		func(v): base.set_value(v / 2)
	)
	var quadrupled = Jodotai.derived(func(): return doubled.get_value() * 2)
	doubled.set_value(10)
	assert_eq(base.get_value(), 5)
	assert_eq(quadrupled.get_value(), 20)
