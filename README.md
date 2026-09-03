

<p align="center">
  <img src="https://github.com/arrahmanbd/popsicle/raw/master/images/icon.png" alt="App Icon" width="150"/>
</p>

# 🍡 Popsicle — Simple. Reactive. Composable

> `Popsicle` is a lightweight, extensible state management and dependency injection (DI) framework for Flutter, built with simplicity and power in mind. Designed for developers who want full control without boilerplate, `Popsicle` unifies state, DI, and lifecycle management under one clean architecture.


## Principles

- **Dependency** is for dependency injection.
- **Store** owns structured reactive application state.
- **ReactiveValue** owns small standalone reactive values.
- **StoreProvider** connects a Store to the graph.
- **ActionStore** optionally adds an explicit `Action -> Store -> State` flow.
- **`.params`** is the public parameterized API. Riverpod's `family` terminology
  stays internal.
- Async work does not require a different Store type.
- **AsyncState** is a value type, so one Store can own multiple async sources.
- **Async.combine2/3/4** derives a single required view from multiple async
  sources.
- DI/container behavior is intentionally not redesigned in this release.

## Install

Use the package locally while the API is experimental:

```bash
flutter pub add popsicle
```

Import one library:

```dart
import 'package:popsicle/popsicle.dart';
```

## App scope

```dart
void main() {
  runApp(
    const PopsicleScope(
      child: MyApp(),
    ),
  );
}
```

`PopsicleScope` is backed by Riverpod 2.6.1's existing ProviderScope/container
implementation in this iteration.

## Dependency injection

```dart
final apiClient = Dependency<ApiClient>(
  (_) => ApiClient(),
);

final userRepository = Dependency<UserRepository>(
  (ref) => UserRepositoryImpl(
    ref.read(apiClient),
  ),
);
```

The important distinction is conceptual: dependencies are not Stores.

## Parameterized dependencies

```dart
final tenantClient = Dependency.params<ApiClient, String>(
  (ref, tenantId) => ApiClient.forTenant(tenantId),
);
```

Usage:

```dart
final client = ref.read(tenantClient('tenant-a'));
```

`.params` keeps the existing Riverpod 2.6 family identity/argument semantics
under the hood without exposing `family` as Popsicle vocabulary.

## Store

```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

final counter = StoreProvider<CounterStore, int>(
  (_) => CounterStore(),
);
```

UI:

```dart
class CounterPage extends PopsicleWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, PopsicleWidgetRef ref) {
    final count = ref.watch(counter);
    final actions = ref.store(counter);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count'),
        FilledButton(
          onPressed: actions.increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

The UI rule is simple:

```text
ref.watch(storeProvider)   -> reactive State
ref.store(storeProvider)   -> Store instance/actions, no rebuild
```

## ReactiveValue

Use `ReactiveValue<T>` when you need one small mutable reactive value and a
full Store would add unnecessary ceremony.

```dart
final counter = ReactiveValue(0);
```

Watch it like other Popsicle state:

```dart
final count = ref.watch(counter);
```

Update it without exposing a notifier/controller:

```dart
ref.set(counter, 10);
ref.update(counter, (value) => value + 1);
```

`ReactiveValue` is container-scoped. The same declaration can therefore hold
independent values in separate `PopsicleContainer`/`PopsicleScope` instances.
Use it for values such as a selected tab, a local filter, a toggle, or a small
counter. Use `Store` when state has behavior, async orchestration, effects, or
multiple related fields.


## Optional ActionStore

Simple Stores should use ordinary methods. For workflows that benefit from a
BLoC-like explicit input model, use `ActionStore` without changing provider
types:

```dart
sealed class CounterAction {
  const CounterAction();
}

final class Increment extends CounterAction {
  const Increment();
}

class CounterStore extends ActionStore<int, CounterAction> {
  CounterStore() : super(0);

  @override
  void onAction(CounterAction action) {
    switch (action) {
      case Increment():
        emit(state + 1);
    }
  }
}
```

Usage:

```dart
ref.store(counter).dispatch(const Increment());
```

Actions are optional; Popsicle does not force event classes onto simple state.

## StoreProvider.params

```dart
class StudentStore extends Store<StudentState> {
  StudentStore({
    required this.studentId,
    required this.repository,
  }) : super(const StudentState());

  final String studentId;
  final StudentRepository repository;
}

final student = StoreProvider.params<StudentStore, StudentState, String>(
  (ref, studentId) => StudentStore(
    studentId: studentId,
    repository: ref.read(studentRepository),
  ),
);
```

Usage:

```dart
final state = ref.watch(student(studentId));
final actions = ref.store(student(studentId));
```

No `family` API is exposed.

## Selective rebuilds

```dart
final isLoading = ref.selectStore(
  student(studentId),
  (state) => state.isLoading,
);
```

This is backed by Riverpod 2.6's selector machinery.

## Multiple async sources in one Store

A Store can keep async resources independent:

```dart
class DashboardState {
  const DashboardState({
    this.profile = const AsyncState.idle(),
    this.metrics = const AsyncState.idle(),
  });

  final AsyncState<Profile> profile;
  final AsyncState<Metrics> metrics;

  AsyncState<(Profile, Metrics)> get content =>
      Async.combine2(profile, metrics);
}
```

This gives both behaviors:

```text
profile -> independent UI section
metrics -> independent UI section

profile + metrics -> content when both are required together
```

### Async composition

```dart
final pair = Async.combine2(profile, metrics);
final triple = Async.combine3(profile, metrics, permissions);
final four = Async.combine4(a, b, c, d);
```

Or for two values:

```dart
final pair = profile.zip(metrics);
```

Composition semantics:

- all sources have values -> combined value
- any source refreshing while all values exist -> combined stale value + refreshing
- refresh error with all stale values available -> combined stale value + error
- missing required value + error -> combined error
- missing required value + loading -> combined loading
- all idle -> combined idle

This avoids creating a second Store/provider merely to coordinate two API
responses.

## AsyncState refresh flow

```dart
emit(state.copyWith(
  profile: AsyncState.loading(previous: state.profile),
));

try {
  final profile = await repository.getProfile();
  emit(state.copyWith(
    profile: AsyncState.data(profile),
  ));
} catch (error, stackTrace) {
  emit(state.copyWith(
    profile: AsyncState.error(
      error,
      stackTrace,
      previous: state.profile,
    ),
  ));
}
```

`AsyncState.loading(previous: ...)` preserves existing data and reports
`isRefreshing == true`.

## Store effects with PopsicleConsumer

`PopsicleConsumer` keeps persistent Store state and one-shot UI effects on
separate channels. The public API is intentionally only `provider`, `effect`,
and `build`.

```dart
sealed class CounterEffect {
  const CounterEffect();
}

final class CounterReachedLimit extends CounterEffect {
  const CounterReachedLimit(this.count);

  final int count;
}

class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() {
    final next = state + 1;
    emit(next);

    if (next == 5) {
      effect(CounterReachedLimit(next));
    }
  }
}

PopsicleConsumer<CounterStore, int>(
  provider: counter,
  effect: (context, effect) {
    if (effect is CounterReachedLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reached ${effect.count}')),
      );
    }
  },
  build: (context, count, store) {
    return FilledButton(
      onPressed: store.increment,
      child: Text('$count'),
    );
  },
);
```

`emit(state)` updates persistent state and rebuilds consumers. `effect(value)`
publishes a transient value only to listeners active at that moment. Effects
are not cached, reconstructed from state changes, or replayed on rebuild.

This avoids using `ref.listen` for ordinary UI side effects. Low-level
`ref.listenStore(...)` remains available for state-listening/orchestration, but
it is not the effect channel.

For a generic small reactive boundary that is not Store-specific, use
`PopsicleBuilder`.

## Public API in 0.1.4

```text
Dependency<T>
Dependency.params<T, Arg>

ReactiveValue<T>

Store<State>
ActionStore<State, Action>
StoreProvider<Store, State>
StoreProvider.params<Store, State, Arg>

AsyncState<T>
Async.combine2
Async.combine3
Async.combine4
AsyncState.zip

PopsicleScope
PopsicleContainer
PopsicleWidget
PopsicleStatefulWidget
PopsicleState
PopsicleConsumer
PopsicleBuilder

PopsicleRef
PopsicleWidgetRef
PopsicleOverride
PopsicleObserver
```

## Intentionally deferred

The first iteration does **not** introduce a new DI engine, type-based service
locator, bindings/modules, feature scopes, code generation, a separate
AsyncStore hierarchy, or a public EventBus.

The underlying fork still contains more Riverpod 2.6 engine code than the
public API needs. That is intentional. We should remove internals only after the
new API has tests and real integration feedback.


## Example app

The `example/` project includes focused examples for:

- plain `Dependency` resolution with `PopsicleBuilder`
- small mutable state with `ReactiveValue`
- `PopsicleConsumer` dedicated one-shot effect channel
- async loading/refresh using `AsyncState`
- two independent async sources combined with `Async.combine2`
- optional `ActionStore` dispatch
- `StoreProvider.params` with multiple independent Store instances
