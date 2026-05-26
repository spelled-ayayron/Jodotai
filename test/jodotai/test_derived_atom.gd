extends GutTest

# --- initial computation ---

func test_derived_seeds_value_on_init():
	var a = Jodotai.atom(5)
	var d = Jodotai.derived(func(): return a.get_value() * 2)
	assert_eq(d.get_value(), 10)


func test_derived_with_zero_initial():
	var a = Jodotai.atom(0)
	var d = Jodotai.derived(func(): return a.get_value() + 1)
	assert_eq(d.get_value(), 1)


# --- auto-tracking and recompute ---

func test_derived_recomputes_when_dep_changes():
	var a = Jodotai.atom(5)
	var d = Jodotai.derived(func(): return a.get_value() * 2)
	a.set_value(10)
	assert_eq(d.get_value(), 20)


func test_derived_emits_changed_on_recompute():
	var a = Jodotai.atom(0)
	var d = Jodotai.derived(func(): return a.get_value() + 1)
	watch_signals(d)
	a.set_value(5)
	assert_signal_emitted(d, "changed")


func test_derived_no_signal_when_computed_value_unchanged():
	# derived returns constant — dep changes but result stays same
	var a = Jodotai.atom(0)
	var d = Jodotai.derived(func(): return 42)
	watch_signals(d)
	a.set_value(99)
	assert_signal_not_emitted(d, "changed")


func test_derived_does_not_track_unread_atom():
	var a = Jodotai.atom(0)
	var b = Jodotai.atom(0)
	var d = Jodotai.derived(func(): return a.get_value())
	watch_signals(d)
	b.set_value(99)
	assert_signal_not_emitted(d, "changed")


# --- multiple and nested deps ---

func test_derived_tracks_multiple_deps():
	var x = Jodotai.atom(2)
	var y = Jodotai.atom(3)
	var sum = Jodotai.derived(func(): return x.get_value() + y.get_value())
	assert_eq(sum.get_value(), 5)
	x.set_value(10)
	assert_eq(sum.get_value(), 13)
	y.set_value(7)
	assert_eq(sum.get_value(), 17)


func test_derived_chain_propagates():
	var a = Jodotai.atom(2)
	var b = Jodotai.derived(func(): return a.get_value() * 3)
	var c = Jodotai.derived(func(): return b.get_value() + 1)
	assert_eq(c.get_value(), 7)
	a.set_value(4)
	assert_eq(b.get_value(), 12)
	assert_eq(c.get_value(), 13)


# --- read-only enforcement ---

func test_derived_set_value_does_not_change_value():
	var a = Jodotai.atom(5)
	var d = Jodotai.derived(func(): return a.get_value())
	d.set_value(999)
	assert_eq(d.get_value(), 5)
