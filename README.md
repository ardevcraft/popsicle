<p align="center">
  <img src="https://raw.githubusercontent.com/ardevcraft/popsicle/master/images/icon.png" alt="Popsicle" width="150" />
</p>

# Popsicle

**Small API. Explicit state. `UI = f(state)`.**

Popsicle is a compact Flutter state-management and dependency-injection package built around four declaration APIs:

```dart
Popsicle.inject(...); // dependencies
Popsicle.value(...);  // small reactive values
Popsicle.create(...); // structured Store state
Popsicle.params(...); // parameterized Store state
```

The runtime model stays equally small:

```text
Intent / method
      ↓
    Store
   ↙     ↘
State    Effect
  ↓        ↓
.view()   one-shot UI work

UI = f(state)
```

No code generation is required.

## Why Popsicle

- One declaration namespace: `Popsicle.*`
- `scope.get(...)` for non-reactive access
- `scope.use(...)` for reactive dependencies
- `ReactiveValue<T>` for tiny mutable state
- `Store<State>` for structured feature state and behavior
- `IntentStore<State, Intent>` when explicit intents improve a workflow
- Dedicated one-shot effect channel separate from persistent state
- `.view()` as the primary Flutter projection API
- `AsyncState<T>` for loading/data/error without a special async Store type
- `Async.combine2/3/4` for multiple independent async sources
- `.params` semantics without exposing provider-family terminology
- Container-scoped state for testing and isolation

---

## Installation

```bash
flutter pub add popsicle
```

```dart
import 'package:popsicle/popsicle.dart';
```

Requirements:

```text
Dart    >= 3.3.0 < 4.0.0
Flutter >= 3.19.0
```

Wrap the Flutter application once:

```dart
void main() {
  runApp(
    const Popsicle(
      child: MyApp(),
    ),
  );
}
```

---

# 1. Dependency injection — `Popsicle.inject`

Use dependencies for API clients, repositories, storage, analytics, services, and application configuration.

```dart
class ApiClient {
  const ApiClient(this.baseUrl);

  final String baseUrl;
}

final apiClient = Popsicle.inject(
  (_) => const ApiClient('https://api.example.com'),
);
```

Dependencies compose through `Scope`:

```dart
class UserRepository {
  const UserRepository(this.client);

  final ApiClient client;
}

final userRepository = Popsicle.inject(
  (scope) => UserRepository(
    scope.get(apiClient),
  ),
);
```

## `scope.get` vs `scope.use`

```text
scope.get(source)
    access the current value
    do not react to future changes

scope.use(source)
    access the current value
    make this computation depend on future changes
```

Example of a reactive dependency:

```dart
final selectedUser = Popsicle.value(1);

final selectedUserLabel = Popsicle.inject(
  (scope) => 'Selected user: ${scope.use(selectedUser)}',
);
```

When `selectedUser` changes, `selectedUserLabel` is recomputed.

---

# 2. Small state — `Popsicle.value`

Use a `ReactiveValue<T>` when creating a full Store would be unnecessary.

```dart
final counter = Popsicle.value(0);
final themeMode = Popsicle.value(ThemeMode.system);
final selectedTab = Popsicle.value(0);
```

## Render with `.view()`

`ReactiveValue.view` works inside an ordinary `StatelessWidget`:

```dart
class CounterText extends StatelessWidget {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context) {
    return counter.view(
      (count) => Text('$count'),
    );
  }
}
```

This is the simplest expression of Popsicle's UI philosophy:

```text
value.view(state => UI)
```

## Mutate with Scope

```dart
PopsicleBuilder(
  builder: (context, scope, child) {
    return FilledButton(
      onPressed: () {
        scope.update(counter, (value) => value + 1);
      },
      child: const Text('Increment'),
    );
  },
)
```

Replace directly:

```dart
scope.set(counter, 0);
```

`ReactiveValue` is scoped. The same declaration can hold independent values in separate `PopsicleContainer`s.

---

# 3. Structured state — `Store`

Use a Store when state has behavior, multiple fields, async orchestration, or one-shot effects.

```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset() => emit(0);
}
```

Declare it with `Popsicle.create`:

```dart
final counter = Popsicle.create(
  (_) => CounterStore(),
);
```

Render it directly:

```dart
counter.view(
  (context, state, store) {
    return FilledButton(
      onPressed: store.increment,
      child: Text('$state'),
    );
  },
);
```

The Store instance is supplied to the view, so UI calls normal Dart methods. There is no separate notifier lookup.

---

# 4. Persistent state vs one-shot effects

Persistent state belongs in `emit(...)`:

```dart
emit(nextState);
```

One-time work belongs in `effect(...)`:

```dart
effect(ProfileSaved());
```

Effects are:

- not stored
- not replayed
- not used to rebuild UI
- delivered only to active effect listeners

Example:

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
```

UI:

```dart
counter.view(
  (context, state, store) {
    return Text('$state');
  },
  effect: (context, effect) {
    if (effect case CounterReachedLimit(:final count)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reached $count')),
      );
    }
  },
);
```

---

# 5. Parameterized state — `Popsicle.params`

Use `Popsicle.params` when a Store instance is identified by a runtime argument.

```dart
class UserStore extends Store<UserState> {
  UserStore({
    required this.userId,
    required this.repository,
  }) : super(const UserState());

  final int userId;
  final UserRepository repository;
}
```

```dart
final user = Popsicle.params(
  (scope, int userId) => UserStore(
    userId: userId,
    repository: scope.get(userRepository),
  ),
);
```

Usage:

```dart
user(42).view(
  (context, state, store) {
    return UserProfile(state: state);
  },
);
```

Different arguments own independent graph identities/state:

```text
user(42)  !=  user(99)
```

For the uncommon case of parameterized non-state DI, `Dependency.params(...)` remains available as an advanced API.

---

# 6. Intent-driven workflows — `IntentStore`

Normal Stores should expose normal methods. Use `IntentStore` only when an explicit intent boundary improves the feature.

```dart
sealed class CheckoutIntent {
  const CheckoutIntent();
}

final class SubmitOrder extends CheckoutIntent {
  const SubmitOrder();
}

class CheckoutStore extends IntentStore<CheckoutState, CheckoutIntent> {
  CheckoutStore(this.repository) : super(const CheckoutState());

  final CheckoutRepository repository;

  @override
  Future<void> onIntent(CheckoutIntent intent) async {
    switch (intent) {
      case SubmitOrder():
        // perform workflow
        break;
    }
  }
}
```

Declaration remains identical:

```dart
final checkout = Popsicle.create(
  (scope) => CheckoutStore(
    scope.get(checkoutRepository),
  ),
);
```

Dispatch:

```dart
checkout.view(
  (context, state, store) {
    return FilledButton(
      onPressed: () => store.dispatch(const SubmitOrder()),
      child: const Text('Submit'),
    );
  },
);
```

---

# 7. Async state without async Store types

Async is an operation characteristic, not a different Store architecture.

```dart
class MessageStore extends Store<AsyncState<String>> {
  MessageStore() : super(const AsyncState.idle());

  Future<void> load() async {
    final previous = state;
    emit(AsyncState.loading(previous: previous));

    try {
      final message = await repository.loadMessage();
      emit(AsyncState.data(message));
    } catch (error, stackTrace) {
      emit(
        AsyncState.error(
          error,
          stackTrace,
          previous: previous,
        ),
      );
    }
  }
}
```

`AsyncState<T>` distinguishes:

```text
idle
initial loading
value
refreshing with stale value
error
refresh error with stale value
```

Useful members include:

```dart
state.hasValue;
state.hasError;
state.isLoading;
state.isInitialLoading;
state.isRefreshing;
state.valueOrNull;
state.requireValue;
state.when(...);
state.map(...);
```

---

# 8. Combine independent async sources

A Store can own multiple independent async resources:

```dart
class DashboardState {
  const DashboardState({
    this.profile = const AsyncState.idle(),
    this.metrics = const AsyncState.idle(),
  });

  final AsyncState<Profile> profile;
  final AsyncState<Metrics> metrics;

  AsyncState<(Profile, Metrics)> get content {
    return Async.combine2(profile, metrics);
  }
}
```

Composition helpers:

```dart
Async.combine2(a, b);
Async.combine3(a, b, c);
Async.combine4(a, b, c, d);
```

Or:

```dart
final combined = profile.zip(metrics);
```

Combined state is derived rather than stored, so there is no third mutable value to synchronize.

---

# 9. `PopsicleWidget` and `PopsicleBuilder`

`.view()` should cover most UI. When a widget needs several reactive sources together, use `PopsicleWidget` or `PopsicleBuilder`.

```dart
class AppHeader extends PopsicleWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, Scope scope) {
    final mode = scope.use(themeMode);
    final user = scope.use(currentUser);

    return Text('${user.name} • $mode');
  }
}
```

`scope.get(...)` does not create a rebuild dependency:

```dart
final analytics = scope.get(analyticsService);
```

`scope.use(...)` does:

```dart
final theme = scope.use(themeMode);
```

For a local rebuild boundary:

```dart
PopsicleBuilder(
  builder: (context, scope, child) {
    final count = scope.use(counterValue);
    return Text('$count');
  },
)
```

---

# 10. Testing and Dart-only usage

Create an isolated container:

```dart
final container = PopsicleContainer();
addTearDown(container.dispose);
```

Resolve dependencies/state:

```dart
final repository = container.get(userRepository);
final count = container.get(counterValue);
```

Mutate a reactive value:

```dart
container.set(counterValue, 10);
container.update(counterValue, (value) => value + 1);
```

Access a Store instance:

```dart
final store = container.store(counter);
store.increment();

expect(container.get(counter), 1);
```

Subscribe outside Flutter:

```dart
final subscription = container.subscribe(
  counterValue,
  (previous, next) {
    print('$previous -> $next');
  },
);

subscription.close();
```

---

# 11. Feature-first clean architecture

Popsicle works naturally as the presentation/application state layer of a feature-first project:

```text
features/
└── user_profile/
    ├── domain/
    │   ├── entities/
    │   ├── repositories/
    │   └── usecases/
    ├── data/
    │   ├── datasources/
    │   ├── models/
    │   └── repositories/
    └── presentation/
        ├── state/
        ├── stores/
        ├── pages/
        └── widgets/
```

A typical feature composition:

```dart
final remoteSource = Popsicle.inject(
  (scope) => UserRemoteSource(scope.get(apiClient)),
);

final repository = Popsicle.inject<UserRepository>(
  (scope) => UserRepositoryImpl(scope.get(remoteSource)),
);

final profile = Popsicle.params(
  (scope, int userId) => UserProfileStore(
    userId: userId,
    repository: scope.get(repository),
  ),
);
```

Domain code stays plain Dart and does not depend on Popsicle.

---

# Public API at a glance

## Recommended declarations

```dart
Popsicle.inject(...)
Popsicle.value(...)
Popsicle.create(...)
Popsicle.params(...)
```

## Dependency context

```dart
scope.get(source)
scope.use(source)
```

## Reactive state

```dart
ReactiveValue<T>
Store<State>
IntentStore<State, Intent>
AsyncState<T>
```

## State transitions

```dart
emit(state)
effect(value)
dispatch(intent)
```

## UI

```dart
reactiveValue.view(...)
store.view(...)
PopsicleWidget
PopsicleBuilder
PopsicleConsumer      // explicit lower-level Store widget
ReactiveBuilder       // explicit lower-level ReactiveValue widget
```

## Dart/testing

```dart
PopsicleContainer
container.get(...)
container.store(...)
container.set(...)
container.update(...)
container.subscribe(...)
```

## Advanced compatibility/declaration types

The package still exposes advanced declaration/handle types such as `Dependency`, `Dependency.params`, `StoreHandle`, `StoreParams`, and `PopsicleOverride` for testing, overrides, and migration. New application code should normally start with the `Popsicle.*` declarations above.

---

# Design principles

1. **UI is a function of state.**
2. **Persistent state and one-shot effects are different channels.**
3. **Dependencies are not state.**
4. **Small state should stay small.**
5. **Async work should not require another controller hierarchy.**
6. **Derived state should be derived, not duplicated.**
7. **Normal Dart methods are the default action API.**
8. **IntentStore is optional structure, not mandatory ceremony.**
9. **Framework vocabulary should describe intent, not implementation mechanics.**

---

## License

Popsicle is distributed under the MIT license. See [LICENSE](LICENSE) and [NOTICE](NOTICE) for attribution and retained upstream notices.
