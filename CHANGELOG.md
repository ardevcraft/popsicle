## 2.1.0

- Standardized the high-level Flutter projection API on `.ui()` for Stores and `ReactiveValue`.
- Added opt-in `History<State>` with:
  - `undo()` / `redo()`
  - `canUndo` / `canRedo`
  - `undoCount` / `redoCount`
  - `clearHistory()`
  - configurable `historyLimit`
- History records committed state snapshots only; one-shot effects are never recorded or replayed.
- Added Store `listenTo(...)` for Store-owned stream subscriptions.
- Stream subscriptions registered through `listenTo(...)` are cancelled automatically when the Store is disposed.
- `listenTo(...)` supports `onData`, `onError`, `onDone`, and `cancelOnError`, and returns the underlying subscription for explicit pause/resume/early cancellation.
- Renamed the public UI extension types to `PopsicleStoreUi` and `ReactiveValueUi`.
- Added History and Stream examples and tests.
- Updated README, API outline, migration notes, publishing guide, example documentation, and wiki for the 2.1 API.

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
- Added the compact Flutter projection API for both `ReactiveValue` and Store handles.
- Extended Store UI projection to parameterized Store handles returned by `Popsicle.params`.
- Updated `PopsicleWidget` and `PopsicleBuilder` to expose `Scope`.
- Wrapped the Dart-only graph in `PopsicleContainer` with `get`, `subscribe`, and scoped Store/value helpers.
- Kept `Store<State>` and `IntentStore<State, Intent>` as the primary structured state types.
- Renamed the internal engine barrel to `engine.dart`; upstream attribution remains in `NOTICE` and `LICENSE`.

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
