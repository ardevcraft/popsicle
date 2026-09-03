# Popsicle 0.1.4 API outline

## Public concepts

### Dependency<T>
DI-only provider definition. Backed by Riverpod 2.6 `Provider` internally.

```dart
final repo = Dependency<Repository>((ref) => RepositoryImpl(...));
```

### Dependency.params<T, Arg>
Parameterized DI definition. Backed by Riverpod 2.6 family mechanics but does
not expose `family` in Popsicle syntax.

```dart
final client = Dependency.params<ApiClient, String>(
  (ref, tenantId) => ApiClient(tenantId),
);
```

### ReactiveValue<T>
Small container-scoped mutable reactive state. It reuses the existing graph and
does not require a Store class.

```dart
final selectedTab = ReactiveValue(0);

final tab = ref.watch(selectedTab);
ref.set(selectedTab, 1);
ref.update(selectedTab, (value) => value + 1);
```

### Store<State>
Reactive state object. First iteration uses StateNotifier's tested notification
and disposal behavior underneath.

```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);
  void increment() => emit(state + 1);
}
```

### ActionStore<State, Action>
Optional structured action input. Simple Stores continue using ordinary methods.

```dart
class CounterStore extends ActionStore<int, CounterAction> {
  CounterStore() : super(0);
  @override
  void onAction(CounterAction action) { /* emit state */ }
}
```

### StoreProvider<Store, State>
Stable graph identity for one Store.

```dart
final counter = StoreProvider<CounterStore, int>((_) => CounterStore());
```

### StoreProvider.params<Store, State, Arg>
Parameterized Store identity.

```dart
final student = StoreProvider.params<StudentStore, StudentState, String>(
  (ref, id) => StudentStore(id, ref.read(repository)),
);
```

### AsyncState<T>
Normal immutable state value for async resource/operation state. Multiple
AsyncState values can coexist in one Store.

### Async.combine2/3/4
Derived composition of independently-owned async sources.

### PopsicleScope
Flutter bridge to the existing ProviderScope/container engine.

### PopsicleWidget
Full reactive widget with a `PopsicleWidgetRef`.

### PopsicleBuilder
Small generic reactive boundary for dependency/mixed low-level reads.

### PopsicleConsumer<Store, State>
Store-focused state + effect boundary.

```dart
PopsicleConsumer<CounterStore, int>(
  provider: counter,
  effect: (context, effect) { /* one-shot side effect */ },
  build: (context, state, store) => Text('$state'),
);
```

The Store explicitly emits effects through `effect(value)`. Effects are not
derived from previous/next state, not retained, and not replayed by widget
rebuilds. The `effect` callback is optional.

`PopsicleConsumer` owns a state subscription for rendering and a dedicated
Store-effect subscription for one-shot UI work.

## Core UI interaction

```text
ref.watch(provider)          reactive value/state
ref.set(reactiveValue, value)    replace a ReactiveValue
ref.update(reactiveValue, fn)    update a ReactiveValue
ref.read(dependency)         non-reactive dependency value
ref.store(storeProvider)     Store instance/actions
ref.selectStore(...)         selective Store-state rebuild
ref.listenStore(...)         low-level Store state listener
PopsicleConsumer(...)        preferred Store state + effect API
```

## Deferred from the initial release

- DI engine rewrite
- type-based dependency lookup
- feature-scope abstraction
- autoDispose public API redesign
- FutureProvider/StreamProvider equivalents
- AsyncStore/AsyncNotifier equivalents
- strongly typed framework-level Effect generics
- hooks package
- code generation

## Internal engine retained

Riverpod 2.6.1 container, provider elements, subscriptions, selectors,
overrides, scheduling, family mechanics, and compatibility provider types are
vendored under `lib/src/engine` and are not exported by `package:popsicle`.
