extends GutTest

# --- init ---

func test_empty_on_default_init():
	var ra = ReactiveArray.new()
	assert_eq(ra.size(), 0)
	assert_true(ra.is_empty())


func test_seeds_from_initial_array():
	var ra = ReactiveArray.new([1, 2, 3])
	assert_eq(ra.size(), 3)
	assert_eq(ra.get_at(0), 1)


func test_init_duplicates_source_array():
	var src = [1, 2, 3]
	var ra = ReactiveArray.new(src)
	src.append(4)
	assert_eq(ra.size(), 3)


# --- push / pop ---

func test_push_appends_to_end():
	var ra = ReactiveArray.new()
	ra.push(42)
	assert_eq(ra.get_at(0), 42)


func test_push_emits_mutated():
	var ra = ReactiveArray.new()
	watch_signals(ra)
	ra.push(1)
	assert_signal_emitted(ra, "mutated")


func test_push_front_prepends():
	var ra = ReactiveArray.new([2, 3])
	ra.push_front(1)
	assert_eq(ra.get_at(0), 1)
	assert_eq(ra.size(), 3)


func test_pop_removes_and_returns_last():
	var ra = ReactiveArray.new([1, 2, 3])
	var v = ra.pop()
	assert_eq(v, 3)
	assert_eq(ra.size(), 2)


func test_pop_emits_mutated():
	var ra = ReactiveArray.new([1])
	watch_signals(ra)
	ra.pop()
	assert_signal_emitted(ra, "mutated")


func test_pop_front_removes_and_returns_first():
	var ra = ReactiveArray.new([10, 20])
	var v = ra.pop_front()
	assert_eq(v, 10)
	assert_eq(ra.get_at(0), 20)


# --- insert / remove_at / erase ---

func test_insert_at_index():
	var ra = ReactiveArray.new([1, 3])
	ra.insert(1, 2)
	assert_eq(ra.get_at(1), 2)
	assert_eq(ra.size(), 3)


func test_insert_emits_mutated():
	var ra = ReactiveArray.new([1, 2])
	watch_signals(ra)
	ra.insert(0, 0)
	assert_signal_emitted(ra, "mutated")


func test_remove_at_removes_element():
	var ra = ReactiveArray.new([10, 20, 30])
	ra.remove_at(1)
	assert_eq(ra.size(), 2)
	assert_eq(ra.get_at(1), 30)


func test_erase_removes_first_occurrence():
	var ra = ReactiveArray.new([1, 2, 2, 3])
	ra.erase(2)
	assert_eq(ra.size(), 3)
	assert_eq(ra.data, [1, 2, 3])


# --- set_at ---

func test_set_at_overwrites_element():
	var ra = ReactiveArray.new([0, 0, 0])
	ra.set_at(1, 99)
	assert_eq(ra.get_at(1), 99)


func test_set_at_emits_mutated():
	var ra = ReactiveArray.new([1, 2, 3])
	watch_signals(ra)
	ra.set_at(0, 10)
	assert_signal_emitted(ra, "mutated")


# --- clear / sort / reverse / resize ---

func test_clear_empties_array():
	var ra = ReactiveArray.new([1, 2, 3])
	ra.clear()
	assert_eq(ra.size(), 0)
	assert_true(ra.is_empty())


func test_clear_emits_mutated():
	var ra = ReactiveArray.new([1])
	watch_signals(ra)
	ra.clear()
	assert_signal_emitted(ra, "mutated")


func test_sort_orders_elements():
	var ra = ReactiveArray.new([3, 1, 2])
	ra.sort()
	assert_eq(ra.get_at(0), 1)
	assert_eq(ra.get_at(1), 2)
	assert_eq(ra.get_at(2), 3)


func test_sort_emits_mutated():
	var ra = ReactiveArray.new([3, 1])
	watch_signals(ra)
	ra.sort()
	assert_signal_emitted(ra, "mutated")


func test_reverse_inverts_order():
	var ra = ReactiveArray.new([1, 2, 3])
	ra.reverse()
	assert_eq(ra.get_at(0), 3)
	assert_eq(ra.get_at(2), 1)


func test_resize_grows_array():
	var ra = ReactiveArray.new([1, 2])
	ra.resize(4)
	assert_eq(ra.size(), 4)


func test_resize_shrinks_array():
	var ra = ReactiveArray.new([1, 2, 3, 4])
	ra.resize(2)
	assert_eq(ra.size(), 2)


# --- append_array / fill / assign ---

func test_append_array_adds_elements():
	var ra = ReactiveArray.new([1])
	ra.append_array([2, 3])
	assert_eq(ra.size(), 3)
	assert_eq(ra.get_at(2), 3)


func test_fill_sets_all_elements():
	var ra = ReactiveArray.new([0, 0, 0])
	ra.fill(7)
	assert_eq(ra.get_at(0), 7)
	assert_eq(ra.get_at(2), 7)


func test_assign_replaces_contents():
	var ra = ReactiveArray.new([1, 2, 3])
	ra.assign([10, 20])
	assert_eq(ra.size(), 2)
	assert_eq(ra.get_at(0), 10)


# --- read methods ---

func test_has_finds_existing_element():
	var ra = ReactiveArray.new([1, 2, 3])
	assert_true(ra.has(2))
	assert_false(ra.has(99))


func test_find_returns_index():
	var ra = ReactiveArray.new([10, 20, 30])
	assert_eq(ra.find(20), 1)
	assert_eq(ra.find(99), -1)


func test_rfind_returns_last_index():
	var ra = ReactiveArray.new([1, 2, 1])
	assert_eq(ra.rfind(1), 2)


func test_slice_returns_plain_array():
	var ra = ReactiveArray.new([0, 1, 2, 3, 4])
	var s = ra.slice(1, 4)
	assert_eq(s, [1, 2, 3])
	assert_false(s is ReactiveArray)


func test_duplicate_is_independent():
	var ra = ReactiveArray.new([1, 2, 3])
	var copy = ra.duplicate()
	copy.push(4)
	assert_eq(ra.size(), 3)
	assert_eq(copy.size(), 4)


func test_data_property_exposes_backing_array():
	var ra = ReactiveArray.new([1, 2])
	assert_eq(ra.data, [1, 2])


# --- iteration ---

func test_for_loop_iterates_elements():
	var ra = ReactiveArray.new([10, 20, 30])
	var collected = []
	for v in ra:
		collected.append(v)
	assert_eq(collected, [10, 20, 30])


func test_empty_array_iteration_does_nothing():
	var ra = ReactiveArray.new()
	var count = 0
	for _v in ra:
		count += 1
	assert_eq(count, 0)


# --- atom integration ---

func test_atom_bridges_mutated_to_changed():
	var ra = ReactiveArray.new()
	var a = Jodotai.atom(ra)
	watch_signals(a)
	ra.push(1)
	assert_signal_emitted(a, "changed")


func test_derived_reacts_to_mutation():
	var ra = ReactiveArray.new()
	var a = Jodotai.atom(ra)
	var size_atom = Jodotai.derived(func(): return a.get_value().size())
	assert_eq(size_atom.get_value(), 0)
	ra.push("item")
	assert_eq(size_atom.get_value(), 1)


func test_derived_reactive_array_driving_hud_label():
	var items = ReactiveArray.new(["bread", "tomato"])
	var inventory = Jodotai.atom(items)
	var label_text = Jodotai.derived(func(): return ", ".join(inventory.get_value().data))
	assert_eq(label_text.get_value(), "bread, tomato")
	items.push("cheese")
	assert_eq(label_text.get_value(), "bread, tomato, cheese")
