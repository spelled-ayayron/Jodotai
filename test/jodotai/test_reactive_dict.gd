extends GutTest

# --- init ---

func test_empty_on_default_init():
	var rd = ReactiveDict.new()
	assert_eq(rd.size(), 0)
	assert_true(rd.is_empty())


func test_seeds_from_initial_dict():
	var rd = ReactiveDict.new({"a": 1, "b": 2})
	assert_eq(rd.size(), 2)
	assert_eq(rd.get_at("a"), 1)


func test_init_duplicates_source_dict():
	var src = {"x": 1}
	var rd = ReactiveDict.new(src)
	src["y"] = 2
	assert_false(rd.has("y"))


# --- put ---

func test_put_inserts_new_key():
	var rd = ReactiveDict.new()
	rd.put("hp", 100)
	assert_eq(rd.get_at("hp"), 100)


func test_put_overwrites_existing_key():
	var rd = ReactiveDict.new({"hp": 100})
	rd.put("hp", 80)
	assert_eq(rd.get_at("hp"), 80)


func test_put_emits_mutated():
	var rd = ReactiveDict.new()
	watch_signals(rd)
	rd.put("x", 1)
	assert_signal_emitted(rd, "mutated")


# --- erase ---

func test_erase_removes_key():
	var rd = ReactiveDict.new({"a": 1, "b": 2})
	rd.erase("a")
	assert_false(rd.has("a"))
	assert_eq(rd.size(), 1)


func test_erase_emits_mutated():
	var rd = ReactiveDict.new({"a": 1})
	watch_signals(rd)
	rd.erase("a")
	assert_signal_emitted(rd, "mutated")


# --- clear ---

func test_clear_removes_all_entries():
	var rd = ReactiveDict.new({"a": 1, "b": 2})
	rd.clear()
	assert_eq(rd.size(), 0)
	assert_true(rd.is_empty())


func test_clear_emits_mutated():
	var rd = ReactiveDict.new({"a": 1})
	watch_signals(rd)
	rd.clear()
	assert_signal_emitted(rd, "mutated")


# --- merge ---

func test_merge_adds_new_keys():
	var rd = ReactiveDict.new({"a": 1})
	rd.merge({"b": 2})
	assert_true(rd.has("b"))
	assert_eq(rd.get_at("b"), 2)


func test_merge_no_overwrite_by_default():
	var rd = ReactiveDict.new({"a": 1})
	rd.merge({"a": 99})
	assert_eq(rd.get_at("a"), 1)


func test_merge_overwrites_when_flag_set():
	var rd = ReactiveDict.new({"a": 1})
	rd.merge({"a": 99}, true)
	assert_eq(rd.get_at("a"), 99)


func test_merge_emits_mutated():
	var rd = ReactiveDict.new()
	watch_signals(rd)
	rd.merge({"x": 1})
	assert_signal_emitted(rd, "mutated")


# --- read methods ---

func test_get_at_returns_value():
	var rd = ReactiveDict.new({"hp": 100})
	assert_eq(rd.get_at("hp"), 100)


func test_get_at_returns_default_when_absent():
	var rd = ReactiveDict.new()
	assert_eq(rd.get_at("missing", -1), -1)


func test_get_at_returns_null_default_when_absent():
	var rd = ReactiveDict.new()
	assert_null(rd.get_at("missing"))


func test_has_existing_key():
	var rd = ReactiveDict.new({"a": 1})
	assert_true(rd.has("a"))
	assert_false(rd.has("b"))


func test_has_all_returns_true_when_all_present():
	var rd = ReactiveDict.new({"a": 1, "b": 2, "c": 3})
	assert_true(rd.has_all(["a", "b"]))


func test_has_all_returns_false_when_any_missing():
	var rd = ReactiveDict.new({"a": 1})
	assert_false(rd.has_all(["a", "b"]))


func test_keys_returns_all_keys():
	var rd = ReactiveDict.new({"x": 1, "y": 2})
	var k = rd.keys()
	assert_true(k.has("x"))
	assert_true(k.has("y"))
	assert_eq(k.size(), 2)


func test_values_returns_all_values():
	var rd = ReactiveDict.new({"a": 10, "b": 20})
	var v = rd.values()
	assert_true(v.has(10))
	assert_true(v.has(20))


func test_find_key_returns_matching_key():
	var rd = ReactiveDict.new({"hp": 100, "mp": 50})
	assert_eq(rd.find_key(50), "mp")


func test_find_key_returns_null_when_not_found():
	var rd = ReactiveDict.new({"a": 1})
	assert_null(rd.find_key(999))


func test_duplicate_is_independent():
	var rd = ReactiveDict.new({"a": 1})
	var copy = rd.duplicate()
	copy.put("b", 2)
	assert_false(rd.has("b"))


func test_data_property_exposes_backing_dict():
	var rd = ReactiveDict.new({"x": 42})
	assert_eq(rd.data["x"], 42)


# --- iteration ---

func test_for_loop_iterates_keys():
	var rd = ReactiveDict.new({"a": 1, "b": 2})
	var keys = []
	for k in rd:
		keys.append(k)
	assert_true(keys.has("a"))
	assert_true(keys.has("b"))
	assert_eq(keys.size(), 2)


# --- atom integration ---

func test_atom_bridges_mutated_to_changed():
	var rd = ReactiveDict.new()
	var a = Jodotai.atom(rd)
	watch_signals(a)
	rd.put("x", 1)
	assert_signal_emitted(a, "changed")


func test_derived_reacts_to_put():
	var rd = ReactiveDict.new()
	var a = Jodotai.atom(rd)
	var size_atom = Jodotai.derived(func(): return a.get_value().size())
	assert_eq(size_atom.get_value(), 0)
	rd.put("key", "value")
	assert_eq(size_atom.get_value(), 1)


func test_derived_reacts_to_erase():
	var rd = ReactiveDict.new({"a": 1, "b": 2})
	var a = Jodotai.atom(rd)
	var size_atom = Jodotai.derived(func(): return a.get_value().size())
	assert_eq(size_atom.get_value(), 2)
	rd.erase("a")
	assert_eq(size_atom.get_value(), 1)
