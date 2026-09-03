# Popsicle 0.1.4 migration notes

This is an API-first migration from Riverpod 2.6.1, not a full engine rewrite.

## Initial mapping

| Riverpod 2.6.1 | Popsicle 0.1.4 |
| --- | --- |
| `Provider<T>` | `Dependency<T>` |
| `Provider.family<T, Arg>` | `Dependency.params<T, Arg>` |
| `StateProvider<T>` | `ReactiveValue<T>` |
| `StateNotifier<T>` | `Store<T>` |
| `StateNotifierProvider<S, T>` | `StoreProvider<S, T>` |
| `StateNotifierProvider.family` | `StoreProvider.params` |
| `ProviderScope` | `PopsicleScope` |
| `ProviderContainer` | `PopsicleContainer` |
| `ConsumerWidget` | `PopsicleWidget` |
| `Consumer` | `PopsicleBuilder` |
| `WidgetRef` | `PopsicleWidgetRef` |
| `provider.notifier` | `ref.store(provider)` |
| `provider.select(...)` | `ref.selectStore(provider, ...)` |
| `ref.listen(store, ...)` for UI effects | `Store.effect(...)` + `PopsicleConsumer(effect: ...)` |

## Not migrated into the public API yet

- FutureProvider
- StreamProvider
- Notifier/NotifierProvider
- AsyncNotifier/AsyncNotifierProvider
- ChangeNotifierProvider
- autoDispose variants
- public family terminology
- code-generation APIs

The source remains vendored where necessary so behavior can be migrated
incrementally without destabilizing the first API iteration.


## PopsicleConsumer in 0.1.3

`PopsicleConsumer` no longer derives UI side effects by comparing Store state.
Stores emit one-shot effects explicitly:

```dart
class SaveStore extends Store<SaveState> {
  SaveStore() : super(const SaveState());

  Future<void> save() async {
    // update persistent state with emit(...)
    effect(const SaveSucceeded());
  }
}
```

UI consumes state and effects separately:

```dart
PopsicleConsumer(
  provider: saveStore,
  effect: (context, effect) { /* navigate/snackbar/dialog */ },
  build: (context, state, store) { /* render state */ },
);
```

This replaces the 0.1.2 `listener`, `listenWhen`, and `buildWhen` consumer API.

## ReactiveValue in 0.1.4

0.1.4 intentionally keeps the 0.1.3 architecture unchanged and adds only a
small-value primitive:

```dart
final selectedTab = ReactiveValue(0);

final tab = ref.watch(selectedTab);
ref.set(selectedTab, 2);
ref.update(selectedTab, (value) => value + 1);
```

Use `ReactiveValue` for isolated scalar/simple values. Keep using `Store` for
structured state, actions, async workflows, and one-shot effects.

