# Jodotai

**Reactive atomic state for Godot 4.** Jotai-style atoms with automatic dependency
tracking — derived values recompute when their dependencies change, with no manual
signal wiring.

```gdscript
var count   := Jodotai.atom(0)
var doubled := Jodotai.derived(func(): return count.get_value() * 2)

count.set_value(5)
print(doubled.get_value())   # 10 — recomputed automatically
```

## Features

- **Atoms** — observable values with a `changed` signal and `subscribe()` helper.
- **Automatic dependency tracking** — `derived()` captures every atom you read and
  re-runs when any of them change. No subscription bookkeeping.
- **Writable derived atoms** — two-way computed values with explicit read/write logic.
- **Optional runtime typing** — `Atom.bool(true)`, `Atom.float(10.0)`, … assert their
  type in debug builds, stripped from release exports.
- **Persisted atoms** — `atom_with_storage()` mirrors a value to `user://`.
- **Atom families** — memoized per-key atom factories for per-entity state.
- **Reactive collections** — `ReactiveArray` / `ReactiveDict` emit on mutation so
  atoms holding them propagate changes in place.
- Pure GDScript, no dependencies. Tested on Godot 4.6.

## Installation

**Asset Library / manual:** copy the `addons/jodotai/` folder into your project's
`addons/` directory, then enable **Jodotai** in **Project → Project Settings → Plugins**.

Enabling the plugin registers the `Jodotai` autoload singleton automatically. That
singleton is the entry point for everything below.

## Quick start

```gdscript
# Create a writable atom
var hp := Jodotai.atom(100)

# Subscribe (returns an unsubscribe Callable — call it to disconnect)
var unsub := hp.subscribe(func(old, new_v): print("hp: %d -> %d" % [old, new_v]))

hp.set_value(80)        # prints "hp: 100 -> 80"
hp.set_value(80)        # no-op — equal value, no signal
unsub.call()            # stop listening
```

## Core concepts

### Atoms

```gdscript
var a := Jodotai.atom(0)
a.get_value()              # read
a.set_value(10)            # write + emit `changed(old, new)`
a.reset()                  # restore the initial value
```

`set_value` short-circuits when the new value `==` the old one, so equal writes emit
nothing.

### Derived atoms (auto-tracked)

`derived()` runs your closure once, records every `get_value()` call as a dependency,
and re-runs whenever any dependency changes. Read-only.

```gdscript
var first := Jodotai.atom("Rémy")
var last  := Jodotai.atom("Ratatouille")
var full  := Jodotai.derived(func(): return "%s %s" % [first.get_value(), last.get_value()])

first.set_value("Linguini")
full.get_value()           # "Linguini Ratatouille"
```

### Writable derived atoms

Two-way computed values — `read` is tracked like `derived()`, `write` runs your logic
(typically delegating to base atoms).

```gdscript
var celsius := Jodotai.atom(0.0)
var fahrenheit := Jodotai.writable(
    func(): return celsius.get_value() * 9.0 / 5.0 + 32.0,
    func(v): celsius.set_value((v - 32.0) * 5.0 / 9.0),
)
fahrenheit.set_value(100.0)
celsius.get_value()        # ≈ 37.78
```

### Persisted atoms

Writes through to `user://jodotai_store.cfg` on every change (no debouncing — fine for
settings, costly for high-frequency values).

```gdscript
var volume := Jodotai.atom_with_storage("audio/volume", 1.0)
volume.set_value(0.5)      # persisted
```

### Atom families

Memoized atom factory keyed by an arbitrary param — same key returns the same atom.

```gdscript
var enemy_hp := Jodotai.atom_family(func(_id): return Jodotai.atom(100))

enemy_hp.get("goblin_1").set_value(80)
enemy_hp.get("goblin_1").get_value()   # 80 — same atom
enemy_hp.get("goblin_2").get_value()   # 100 — new atom
enemy_hp.remove("goblin_1")            # evict (e.g. on death)
```

Optionally auto-evict with `set_should_remove(func(param, atom) -> bool)`, run before
each `get()`.

### Optional runtime typing

Typed atoms enforce a type via `is_instance_of` on construction and every `set_value`.
The check uses `assert`, so it catches mismatches in debug builds and is **stripped from
release exports** — zero cost in shipped games.

```gdscript
var alive := Atom.bool(true)
alive.set_value(false)         # ok
# alive.set_value(3)           # assert fails in debug: "Atom type mismatch"

var speed := Atom.float(10.0)  # TYPE_FLOAT also accepts ints

var pos := Atom.typed(Vector2.ZERO, TYPE_VECTOR2)      # any Variant.Type
var inv := Atom.typed(ReactiveArray.new(), ReactiveArray)  # native class or Script
```

GDScript has no generics, so this validates **writes** only — `get_value()` still returns
`Variant`. Cast at the read site for editor checking:

```gdscript
var is_dead := not bool(alive.get_value())     # primitive: constructor cast
var items   := inv.get_value() as ReactiveArray # object: `as`
```

### Reactive collections

Plain `Array`/`Dictionary` mutations can't be observed, so an atom holding one won't
re-emit when you push or erase. `ReactiveArray` / `ReactiveDict` wrap them and emit a
`mutated` signal on every change; an atom holding one bridges `mutated → changed`
automatically, so derived atoms refresh.

```gdscript
var items := ReactiveArray.new(["bread", "tomato"])
var inv   := Jodotai.atom(items)
var count := Jodotai.derived(func(): return inv.get_value().size())

items.push("cheese")
count.get_value()          # 3 — recomputed via mutated → changed
```

Use the mutation methods (`push`, `erase`, `set_at`, `put`, `merge`, …) — `arr[i] = x`
can't be intercepted on custom classes in Godot 4. `.data` exposes the backing
collection by reference for reads only; mutating it directly bypasses `mutated`.

## API reference

### `Jodotai` (autoload)

| Method | Description |
| --- | --- |
| `atom(initial = null) -> Atom` | Writable atom. |
| `derived(compute: Callable) -> DerivedAtom` | Read-only auto-tracked computed atom. |
| `writable(read, write: Callable) -> WritableAtom` | Two-way computed atom. |
| `atom_with_storage(key: String, initial = null) -> Atom` | Atom persisted to `user://`. |
| `atom_family(factory: Callable) -> AtomFamily` | Memoized atom factory keyed by param. |

### `Atom`

| Member | Description |
| --- | --- |
| `signal changed(old_value, new_value)` | Emitted on value change. |
| `get_value()` | Read; registers as a dependency inside a `derived` frame. |
| `set_value(new_value)` | Write + emit; no-op on equal value; asserts type on typed atoms. |
| `reset()` | Restore the initial value. |
| `subscribe(cb: Callable) -> Callable` | Connect `cb`; returns an unsubscribe Callable. |
| `static bool/int/float/string(initial)` | Typed atoms locked to that type. |
| `static typed(initial, type)` | Typed atom for any `Variant.Type`, native class, or Script. |

### `AtomFamily`

| Method | Description |
| --- | --- |
| `get(param) -> Atom` | Cached atom for `param`, created on first call. |
| `remove(param)` / `clear()` | Evict one / all. Held references stay valid. |
| `has(param) -> bool` | Whether `param` is cached (does not run eviction predicate). |
| `params() -> Array` | Currently cached keys. |
| `set_should_remove(pred: Callable)` | Eviction predicate `func(param, atom) -> bool`. |

### `ReactiveArray` / `ReactiveDict`

`signal mutated`, read-only `data` view, and mutation methods that emit on change.

- **Array:** `push`, `push_front`, `pop`, `pop_front`, `insert`, `remove_at`, `erase`,
  `set_at`, `clear`, `sort`, `sort_custom`, `reverse`, `resize`, `append_array`, `fill`,
  `assign` — plus reads `get_at`, `size`, `is_empty`, `has`, `find`, `rfind`, `slice`,
  `duplicate`. Supports `for item in reactive_array`.
- **Dict:** `put`, `erase`, `clear`, `merge` — plus reads `get_at`, `has`, `has_all`,
  `keys`, `values`, `size`, `is_empty`, `find_key`, `duplicate`. Supports
  `for key in reactive_dict`.

## Caveats

- **Equality short-circuit uses `==`.** `set_value` skips emitting when
  `new_value == _value`. For objects this is identity, so in-place mutations don't fire
  unless the value is a `ReactiveArray`/`ReactiveDict`. Also: changing an untyped atom
  across `==`-incomparable types (e.g. `int` → `String`) **throws** at the comparison;
  bridge through `null` or stay within a comparable type family.
- **Typed checks are debug-only.** `assert`-based, stripped from release exports. Don't
  rely on them to validate untrusted/external data — use an explicit guard for that.
- **Typed atoms reject `null`.** `is_instance_of(null, type)` is `false`; leave an atom
  untyped if it needs to be nullable.
- **`Atom.bool/int/float` shadow the built-in casts inside the `Atom` hierarchy.** Code
  *inside* `Atom`/`DerivedAtom`/`WritableAtom` writing `int(x)` calls the factory, not the
  conversion. (`string` is safe — the cast is `String`.) Outside the hierarchy they behave
  normally.
- **Clean up subscriptions.** Capture the Callable from `subscribe()` and call it in
  `_exit_tree()` (or `NOTIFICATION_PREDELETE`). Don't capture an atom inside its own
  subscription lambda — that's a refcount cycle GDScript won't collect; use the
  `(old, new)` callback args or a `weakref`.
- **`atom_with_storage` keys share one `[atoms]` section** in the store; duplicate keys
  overwrite each other, and every write round-trips through `ConfigFile.save`.
- **`atom_family` holds strong refs.** Cached atoms aren't freed until `remove()`/`clear()`
  and all external refs drop. Family-membership changes don't re-run derived atoms that
  only read `get()` results — track active IDs separately if you need that.

## Testing

A [GUT](https://github.com/bitwes/Gut) suite lives under `test/jodotai/`. Run headless:

```sh
godot --headless -d -s addons/gut/gut_cmdln.gd -gdir=res://test/jodotai -gexit
```

## License
Jodotai is provided under the MIT license. License is in addons/jodotai/LICENSE.md.
