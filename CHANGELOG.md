## 2.0.0

- Added the unified declaration namespace:
  - `Popsicle.inject(...)`
  - `Popsicle.value(...)`
  - `Popsicle.create(...)`
  - `Popsicle.params(...)`
- Added public `Scope` with `scope.get(...)` and `scope.use(...)` semantics.
- Replaced public `Ref`/`read`/`watch` usage in Popsicle APIs and examples with `Scope`.
- Added `scope.store(...)` and `scope.select(...)` Store helpers.
- Added `scope.set(...)` and `scope.update(...)` ReactiveValue helpers.
- Made `.view()` the recommended Flutter projection API for both `ReactiveValue` and Store handles.
- Extended Store `.view()` to work with parameterized Store handles returned by `Popsicle.params`.
- Updated `PopsicleWidget` and `PopsicleBuilder` to expose `Scope` instead of a reference object.
- Wrapped the Dart-only graph in `PopsicleContainer` with `get`, `subscribe`, and scoped Store/value helpers.
- Kept `Store<State>` and `IntentStore<State, Intent>` as the primary structured state types.
- Updated all examples, tests, README, API outline, migration guide, and wiki documentation.
- Renamed the internal engine barrel from `riverpod.dart` to `engine.dart`; upstream attribution remains in `NOTICE` and `LICENSE`.

## 2.0.0-dev

- Consolidated the public Popsicle API around `Dependency`, `ReactiveValue`, `Store`, `IntentStore`, effects, `.params`, and async composition.
- Added Store and ReactiveValue `.view()` implementation work that is finalized as public API in 3.0.0.

## 0.1.4

- Added `ReactiveValue<T>` for small standalone mutable reactive state.
- Added scoped `set` and `update` helpers.

## 0.1.3

- Simplified `PopsicleConsumer` to Store state + dedicated one-shot effects.
- Added the Store effect channel.

## 0.1.2

- Added the Store-focused consumer and expanded examples.

## 0.1.1

- Fixed Flutter consumer integration after vendoring the engine.

## 0.1.0

- Initial Popsicle API iteration on the vendored 2.6.1 engine baseline.
