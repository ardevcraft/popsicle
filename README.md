<p align="center">
  <img src="https://raw.githubusercontent.com/ardevcraft/popsicle/master/images/icon.png" alt="Popsicle" width="150" />
</p>

# Popsicle

**Simple state. Explicit dependencies. Composable async work.**

Popsicle is a compact state-management and dependency-injection package for Flutter. Its public API is intentionally centered around a small set of concepts instead of a large provider taxonomy.

The core idea is simple:

```text
state -> UI

UI = f(state)
```

State stays persistent and renderable. One-shot work such as snackbars, navigation, dialogs, and external launches travels through a separate effect channel.

## Why Popsicle

- **Dependency** for dependency injection.
- **ReactiveValue** for one small mutable reactive value.
- **Store** for structured state and behavior.
- **IntentStore** when a workflow benefits from explicit intents.
- **StoreProvider** for Store identity and lifecycle in the graph.
- **`.params`** for parameterized dependencies and Stores.
- **AsyncState** for async resource state without requiring a special async Store type.
- **Async.combine2/3/4** for composing multiple independent async sources.
- **PopsicleConsumer** for Store state + one-shot UI effects.
- No code generation required.

## Mental model

```text
Dependency
    -> application services / repositories / infrastructure

ReactiveValue<T>
    -> small standalone reactive state

Store<State>
    -> structured state + ordinary methods

IntentStore<State, Intent>
    -> structured state + explicit intent dispatch

Store
    |-- emit(state)   -> persistent state -> rebuild UI
    `-- effect(value) -> one-shot effect  -> side effect
```

A practical rule:

| Need | Use |
| --- | --- |
| API client, repository, storage, service | `Dependency<T>` |
| Selected tab, toggle, tiny counter, simple filter | `ReactiveValue<T>` |
| Feature state with behavior or async orchestration | `Store<State>` |
| Explicit intent-driven workflow | `IntentStore<State, Intent>` |
| Async loading/data/error state | `AsyncState<T>` |
| Two or more async sources required together | `Async.combine2/3/4` |

---

## Installation

```bash
flutter pub add popsicle
```

Import the package:

```dart
import 'package:popsicle/popsicle.dart';
```

Popsicle currently requires:

```text
Dart    >= 3.3.0 < 4.0.0
Flutter >= 3.19.0
```

---

## App scope

Wrap the application with `Popsicle`:

```dart
void main() {
  runApp(
    const Popsicle(
      child: MyApp(),
    ),
  );
}
```

`Popsicle` owns the Flutter-side graph used by dependencies, reactive values, and Stores.

It also supports overrides and observers:

```dart
Popsicle(
  overrides: [
    // dependency/store overrides
  ],
  observers: [
    // PopsicleObserver instances
  ],
  child: const MyApp(),
);
```

---

# Dependency injection

Use `Dependency<T>` for non-state application dependencies.

```dart
class ApiClient {
  const ApiClient(this.baseUrl);

  final String baseUrl;
}

final apiClient = Dependency<ApiClient>(
  (_) => const ApiClient('https://api.example.com'),
);
```

Dependencies can depend on other dependencies:

```dart
class UserRepository {
  const UserRepository(this.client);

  final ApiClient client;
}

final userRepository = Dependency<UserRepository>(
  (ref) => UserRepository(
    ref.read(apiClient),
  ),
);
```

The important distinction is architectural:

```text
Dependency -> object/service graph
Store      -> reactive application state
```

## Parameterized dependencies

Use `.params` when creation depends on a runtime argument:

```dart
final tenantClient = Dependency.params<ApiClient, String>(
  (_, tenantId) => ApiClient(
    'https://$tenantId.api.example.com',
  ),
);
```

Usage inside a Popsicle widget/factory:

```dart
final client = ref.read(
  tenantClient('tenant-a'),
);
```

Each argument participates in the underlying graph identity and caching semantics.

---

# ReactiveValue

Use `ReactiveValue<T>` when a full Store would add unnecessary ceremony.

```dart
final selectedTab = ReactiveValue(0);
```

Observe it from a `PopsicleWidget`:

```dart
class NavigationView extends PopsicleWidget {
  const NavigationView({super.key});

  @override
  Widget build(BuildContext context, PopsicleRef ref) {
    final tab = ref.watch(selectedTab);

    return NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (index) {
        ref.set(selectedTab, index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
```

Update from the current value:

```dart
ref.update(
  selectedTab,
  (current) => current + 1,
);
```

Available mutation helpers:

```dart
ref.set(value, next);
ref.update(value, (current) => next);
```

`ReactiveValue` is container-scoped. The same declaration can therefore hold independent values in separate `PopsicleContainer` instances.

Use it for genuinely small state. When state grows behavior, related fields, async work, or effects, move it into a `Store`.

---

# Store

A `Store<State>` owns structured reactive state and exposes normal Dart methods for behavior.

```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() {
    emit(state + 1);
  }

  void decrement() {
    emit(state - 1);
  }

  void reset() {
    emit(0);
  }
}
```

Declare it with `StoreProvider`:

```dart
final counter = StoreProvider<CounterStore, int>(
  (_) => CounterStore(),
);
```

A Store provider exposes two useful views of the same feature:

```text
ref.watch(counter) -> current reactive state
ref.store(counter) -> Store instance, no state subscription
```

Example:

```dart
class CounterPage extends PopsicleWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, PopsicleRef ref) {
    final count = ref.watch(counter);
    final store = ref.store(counter);

    return Scaffold(
      body: Center(
        child: Text('$count'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: store.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Async methods use the same Store type. Popsicle does not require a separate async Store hierarchy.

---

# IntentStore

Simple state should continue using normal Store methods.

For workflows where explicit inputs make the state machine easier to reason about, use `IntentStore<State, Intent>`.

```dart
sealed class CounterIntent {
  const CounterIntent();
}

final class Increment extends CounterIntent {
  const Increment();
}

final class Reset extends CounterIntent {
  const Reset();
}

class CounterController extends IntentStore<int, CounterIntent> {
  CounterController() : super(0);

  @override
  void onIntent(CounterIntent intent) {
    switch (intent) {
      case Increment():
        emit(state + 1);

      case Reset():
        emit(0);
    }
  }
}
```

Declare it exactly like any other Store:

```dart
final intentCounter = StoreProvider<CounterController, int>(
  (_) => CounterController(),
);
```

Dispatch an intent:

```dart
ref.store(intentCounter).dispatch(
  const Increment(),
);
```

The flow is:

```text
Intent -> IntentStore -> State -> UI
```

`IntentStore` is optional. Do not introduce intent classes when ordinary methods are clearer.

---

# Parameterized Stores

Use `StoreProvider.params` when a Store instance depends on a runtime argument.

```dart
class StudentStore extends Store<StudentState> {
  StudentStore({
    required this.studentId,
    required this.repository,
  }) : super(const StudentState());

  final String studentId;
  final StudentRepository repository;
}
```

```dart
final student = StoreProvider.params<
  StudentStore,
  StudentState,
  String
>(
  (ref, studentId) => StudentStore(
    studentId: studentId,
    repository: ref.read(studentRepository),
  ),
);
```

Resolve a concrete Store handle with the argument:

```dart
final provider = student(studentId);

final state = ref.watch(provider);
final store = ref.store(provider);
```

Different parameters produce independent graph identities:

```dart
final student42 = student('42');
final student77 = student('77');
```

The public API deliberately uses `.params`; users do not need to learn a separate `family` vocabulary.

---

# Selective rebuilds

Use `selectStore` when a widget depends on only one projection of Store state.

```dart
final isLoading = ref.selectStore(
  student(studentId),
  (state) => state.isLoading,
);
```

The widget rebuilds when the selected value changes rather than for every Store state update.

---

# AsyncState

`AsyncState<T>` is a normal immutable value for async operation/resource state.

A Store can therefore own multiple independent async sources without wrapping the whole feature in one async provider.

Available states:

```dart
const AsyncState<T>.idle();
AsyncState<T>.loading();
const AsyncState<T>.data(value);
AsyncState<T>.error(error, stackTrace);
```

Common properties:

```dart
state.hasValue;
state.hasError;
state.isIdle;
state.isLoading;
state.isInitialLoading;
state.isRefreshing;
state.valueOrNull;
state.requireValue;
state.error;
state.stackTrace;
```

Transform a value while keeping async metadata:

```dart
final names = users.map(
  (items) => items.map((user) => user.name).toList(),
);
```

Render all states with `when`:

```dart
return profile.when(
  idle: () => const SizedBox.shrink(),
  loading: () => const CircularProgressIndicator(),
  data: (profile, refreshing) {
    return ProfileView(
      profile: profile,
      refreshing: refreshing,
    );
  },
  error: (error, stackTrace, previousValue) {
    return ErrorView(
      error: error,
      previousProfile: previousValue,
    );
  },
);
```

## Preserve stale data while refreshing

```dart
emit(
  state.copyWith(
    profile: AsyncState.loading(
      previous: state.profile,
    ),
  ),
);
```

After a failed refresh, previous data can also be preserved:

```dart
emit(
  state.copyWith(
    profile: AsyncState.error(
      error,
      stackTrace,
      previous: state.profile,
    ),
  ),
);
```

This allows the UI to keep useful content visible while reporting refresh/loading metadata separately.

---

# Combining async sources

A feature often owns multiple API sources that load independently but are sometimes required together.

Keep the sources independent in state:

```dart
class DashboardState {
  const DashboardState({
    this.profile = const AsyncState.idle(),
    this.metrics = const AsyncState.idle(),
  });

  final AsyncState<Profile> profile;
  final AsyncState<Metrics> metrics;

  AsyncState<(Profile, Metrics)> get content {
    return Async.combine2(
      profile,
      metrics,
    );
  }
}
```

The original sources remain independently renderable:

```text
profile -> profile section
metrics -> metrics section
```

while the derived state handles UI that requires both:

```text
profile + metrics -> combined content
```

Available composition helpers:

```dart
final pair = Async.combine2(a, b);
final triple = Async.combine3(a, b, c);
final four = Async.combine4(a, b, c, d);
```

For two states, `zip` is equivalent:

```dart
final pair = profile.zip(metrics);
```

Composition preserves stale values and refresh metadata when all required values are still available.

---

# Store effects

Persistent state and one-shot UI effects are separate concepts.

Use `emit(...)` for state:

```dart
emit(nextState);
```

Use `effect(...)` for transient events:

```dart
effect(
  const SaveSucceeded(),
);
```

Effects are:

- delivered only to active listeners;
- not stored as State;
- not replayed after rebuild;
- not used to rebuild UI.

Example:

```dart
sealed class ProfileEffect {
  const ProfileEffect();
}

final class ProfileRefreshFailed extends ProfileEffect {
  const ProfileRefreshFailed(this.message);

  final String message;
}

class ProfileStore extends Store<ProfileState> {
  ProfileStore(this.repository) : super(const ProfileState());

  final ProfileRepository repository;

  Future<void> refresh() async {
    try {
      // load + emit persistent state
    } catch (_) {
      effect(
        const ProfileRefreshFailed('Unable to refresh profile.'),
      );
    }
  }
}
```

## PopsicleConsumer

`PopsicleConsumer` is the Store-focused UI boundary for persistent state plus optional one-shot effects.

Its intended public model is deliberately small:

```text
provider
build
effect
```

```dart
PopsicleConsumer<ProfileStore, ProfileState>(
  provider: profileStore,
  effect: (context, effect) {
    switch (effect) {
      case ProfileRefreshFailed(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
    }
  },
  build: (context, state, store) {
    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ProfileBody(state: state),
    );
  },
);
```

Use `PopsicleConsumer` when a Store needs both rendering and one-shot UI reactions. For simple state rendering, `PopsicleWidget` + `ref.watch(...)` is sufficient.

For low-level non-widget scenarios, a Store also exposes:

```dart
final subscription = store.listenEffects(
  (effect) {
    // handle effect
  },
);
```

---

# PopsicleBuilder

`PopsicleBuilder` creates a small reactive boundary without defining a full `PopsicleWidget` class.

```dart
PopsicleBuilder(
  builder: (context, ref, child) {
    final value = ref.watch(someDependency);

    return Text('$value');
  },
);
```

Use it for dependency-only or mixed low-level reads where `PopsicleConsumer` would be unnecessary.

---

# Stateful widgets

For stateful Flutter widgets, use `PopsicleStatefulWidget` and `PopsicleState`:

```dart
class EditorPage extends PopsicleStatefulWidget {
  const EditorPage({super.key});

  @override
  PopsicleState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends PopsicleState<EditorPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorStore);

    return EditorView(state: state);
  }
}
```

---

# Dart-only container

`PopsicleContainer` can resolve and mutate Popsicle state without Flutter widgets.

```dart
final container = PopsicleContainer();

try {
  final repository = container.read(userRepository);
  final state = container.read(counter);
  final store = container.read(counter.store);

  store.increment();

  container.set(selectedTab, 2);
  container.update(selectedTab, (value) => value + 1);
} finally {
  container.dispose();
}
```

This is useful for unit tests, command-line programs, and non-widget orchestration.

---

# Overrides and testing

`Popsicle` and `PopsicleContainer` expose the existing override mechanism through `PopsicleOverride`.

Parameterized dependencies and Stores expose `overrideWith(...)` directly:

```dart
final users = Dependency.params<UserRepository, String>(
  (ref, tenantId) => RealUserRepository(tenantId),
);
```

```dart
final override = users.overrideWith(
  (ref, tenantId) => FakeUserRepository(tenantId),
);
```

Then:

```dart
final container = PopsicleContainer(
  overrides: [override],
);
```

Stores remain directly constructible, so unit tests can also bypass the graph entirely:

```dart
final store = ProfileStore(
  FakeProfileRepository(),
);
```

---

# Feature-first architecture

Popsicle does not require a project structure, but its primitives fit naturally into Feature-First Clean Architecture.

```text
features/
└── user_profile/
    ├── domain/
    │   ├── entities/
    │   ├── repositories/
    │   └── usecases/
    │
    ├── data/
    │   ├── datasources/
    │   ├── models/
    │   └── repositories/
    │
    └── presentation/
        ├── state/
        ├── stores/
        ├── pages/
        └── widgets/
```

Typical dependency direction:

```text
UI
 -> Store
 -> Use Case / Repository contract
 -> Repository implementation
 -> Remote / Local source
```

Popsicle should remain in presentation/composition code; domain entities and repository contracts can stay plain Dart.

---

# Public API — 2.0.0

Most applications primarily need:

```text
Dependency<T>
Dependency.params<T, Arg>

ReactiveValue<T>

Store<State>
IntentStore<State, Intent>
StoreProvider<Store, State>
StoreProvider.params<Store, State, Arg>

AsyncState<T>
Async.combine2(...)
Async.combine3(...)
Async.combine4(...)
AsyncState.zip(...)

Popsicle
PopsicleWidget
PopsicleStatefulWidget
PopsicleState
PopsicleBuilder
PopsicleConsumer
PopsicleContainer
```

The package barrel currently also exports these supporting/advanced types:

```text
PopRef<T>
PopsicleRef
PopsicleNode
PopsicleOverride
PopsicleObserver
PopsicleSubscription<T>

DependencyHandle<T>
DependencyParams<T, Arg>
DependencyParamsBuilder

StoreHandle<Store, State>
StoreAccessor<Store>
StoreParams<Store, State, Arg>
StoreParamsBuilder

PopsicleBuilderCallback
PopsicleStoreBuild<Store, State>
PopsicleStoreEffect

PopsicleStoreRefExtension
PopsicleWidgetRefStoreExtension
PopsicleRefReactiveValueExtension
PopsicleWidgetRefReactiveValueExtension
PopsicleContainerReactiveValueExtension
```

---

# Current implementation status

Popsicle 2.0.0 currently retains the proven Riverpod 2.6.1 container/provider engine internally while presenting a smaller Popsicle API publicly.

The vendored engine is an implementation detail and is not exported from `package:popsicle/popsicle.dart`.

This allows Popsicle to evolve its public model incrementally without rewriting graph resolution, lifecycle, subscriptions, selectors, overrides, and scheduling all at once.

---

# Design principles

Popsicle aims to keep these rules stable:

1. **Plain values stay plain Dart.** Do not make something reactive unless it needs to be reactive.
2. **Dependencies are not state.** Use `Dependency` for services and `Store`/`ReactiveValue` for state.
3. **UI is a function of state.** Persistent state should be sufficient to render the current UI.
4. **Effects are not state.** Snackbar/navigation/dialog events belong to the one-shot effect channel.
5. **Async is state, not a provider type.** Use `AsyncState` inside normal Stores.
6. **Derived async composition should remain derived.** Keep independent sources independent and combine them only where required.
7. **Intent-driven workflows are optional.** Prefer ordinary methods until explicit intents make the workflow clearer.
8. **Do not expose internal engine complexity unless the public API genuinely needs it.**

---

# License

Popsicle is distributed under the license included in this repository. See [LICENSE](LICENSE) and [NOTICE](NOTICE) for details.
