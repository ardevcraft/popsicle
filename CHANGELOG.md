## 0.1.4

- Added `ReactiveValue<T>` for small standalone mutable reactive state.
- Added `ref.set(...)` and `ref.update(...)` helpers for `ReactiveValue`.
- Added equivalent `PopsicleContainer.set(...)` and `.update(...)` helpers.
- Added a focused ReactiveValue Flutter example and regression tests.
- No other public API or DI/state-management semantics changed from 0.1.3.

## 0.1.3

- Simplified `PopsicleConsumer` to `provider`, optional `effect`, and `build`.
- Added a dedicated one-shot Store effect channel through protected `effect(value)`.
- Added `Store.listenEffects(...)` for low-level non-widget/test consumption.
- Removed `listener`, `listenWhen`, `buildWhen`, previous/next state comparisons, and consumer `child` from the Store-focused API.
- Effects are not retained or replayed and do not rebuild widgets.
- Updated async, combined-source, action, params, and counter examples to the simpler consumer API.

## 0.1.2

- Added Store-focused `PopsicleConsumer<Store, State>`.
- Added one managed subscription for Store rebuilds and UI side effects.
- Added `listenWhen` for filtering side effects.
- Added `buildWhen` for filtering rebuilds independently.
- Added Store instance access directly in consumer builder/listener callbacks.
- Renamed the previous generic `PopsicleConsumer` boundary to `PopsicleBuilder`.
- Kept `ref.listenStore` as an advanced low-level API.
- Expanded the example app with side-effect, async Store, combined async source, and `.params` examples.

## 0.1.1

- Fixed Flutter runtime compilation of `ConsumerStatefulElement` by restoring access to the vendored scope engine.
- Fixed generic inference for manual widget subscriptions on newer Dart SDKs.

## 0.1.0

- Initial Popsicle API iteration based on the Riverpod 2.6.1 engine.
- Added `Dependency<T>`.
- Added `Dependency.params<T, Arg>`.
- Added `Store<State>`.
- Added optional `ActionStore<State, Action>`.
- Added `StoreProvider<Store, State>`.
- Added `StoreProvider.params<Store, State, Arg>`.
- Added `ref.store`, `ref.selectStore`, and Flutter `ref.listenStore` helpers.
- Added `AsyncState<T>` with stale-data refresh/error support.
- Added `Async.combine2`, `combine3`, `combine4`, and `AsyncState.zip`.
- Added `PopsicleScope`, `PopsicleWidget`, `PopsicleStatefulWidget`, and
  `PopsicleConsumer`.
- Vendored Riverpod 2.6.1 core/Flutter consumer engine into one package.
