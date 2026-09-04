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

The core model stays intentionally small:

```text
Intent / method / Stream
          ↓
        Store
       ↙     ↘
    State    Effect
      ↓        ↓
    .ui()   one-shot UI work

UI = f(state)
```

Popsicle 2.1 also adds opt-in undo/redo history without changing the normal Store model.

No code generation is required.

## Highlights

- `Popsicle.inject(...)` for scoped dependencies
- `Popsicle.value(...)` for lightweight reactive values
- `Popsicle.create(...)` for structured state
- `Popsicle.params(...)` for parameterized Store state
- `scope.get(...)` for non-reactive access
- `scope.use(...)` for reactive dependency access
- `Store<State>` for feature state and behavior
- `IntentStore<State, Intent>` for explicit intent-driven workflows
- `commit(...)` for persistent state transitions
- `effect(...)` for one-shot UI work
- `.ui()` for `UI = f(state)` projection
- `History<State>` for opt-in undo/redo
- `listenTo(...)` for Store-owned stream subscriptions
- `AsyncState<T>` and `Async.combine2/3/4` for async composition
- `PopsicleContainer` for Dart-only state, testing, and overrides

---

## Installation

```bash
flutter pub add popsicle
```

```dart
import 'package:popsicle/popsicle.dart';
```

Wrap the application once:

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

Use dependencies for API clients, repositories, storage, analytics, services, and configuration.

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
    do not create a reactive dependency

scope.use(source)
    access the current value
    react when that dependency changes
```

Example:

```dart
final selectedUser = Popsicle.value(1);

final selectedUserLabel = Popsicle.inject(
  (scope) => 'Selected user: ${scope.use(selectedUser)}',
);
```

---

# 2. Small state — `Popsicle.value`

Use `ReactiveValue<T>` when a full Store would be unnecessary.

```dart
final counter = Popsicle.value(0);
final themeMode = Popsicle.value(ThemeMode.system);
final selectedTab = Popsicle.value(0);
```

Render it from an ordinary `StatelessWidget`:

```dart
class CounterText extends StatelessWidget {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context) {
    return counter.ui(
      (count) => Text('$count'),
    );
  }
}
```

Mutate through `Scope`:

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

`ReactiveValue` is container-scoped, so the same declaration can hold independent values in separate `PopsicleContainer`s.

---

# 3. Structured state — `Store`

Use a Store when state has behavior, multiple fields, async orchestration, stream input, history, or effects.

```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => commit(state + 1);
  void decrement() => commit(state - 1);
  void reset() => commit(0);
}
```

Declare it:

```dart
final counter = Popsicle.create(
  (_) => CounterStore(),
);
```

Render it:

```dart
counter.ui(
  (context, state, store) {
    return FilledButton(
      onPressed: store.increment,
      child: Text('$state'),
    );
  },
);
```

## Access inside `PopsicleWidget`

```dart
class CounterActions extends PopsicleWidget {
  const CounterActions({super.key});

  @override
  Widget build(BuildContext context, Scope scope) {
    final count = scope.use(counter);     // reactive state
    final store = scope.store(counter);   // Store instance

    return Row(
      children: [
        Text('$count'),
        IconButton(
          onPressed: store.increment,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
```

The distinction is deliberate:

```text
scope.get(storeSource)   -> Store state, non-reactive
scope.use(storeSource)   -> Store state, reactive
scope.store(storeSource) -> Store instance / behavior
```

---

# 4. `commit` and `effect`

Persistent state belongs in `commit(...)`:

```dart
commit(nextState);
```

One-shot work belongs in `effect(...)`:

```dart
effect(const ProfileSaved());
```

Consume effects through Store `.ui()`:

```dart
profile.ui(
  (context, state, store) {
    return ProfileBody(state: state);
  },
  effect: (context, effect) {
    if (effect is ProfileSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    }
  },
);
```

Effects:

- are delivered as occurrences
- are not stored as State
- are not replayed on rebuild
- do not rebuild Store UI by themselves
- are not part of undo/redo history

Use state for durable UI representation; use effects for snackbars, navigation, dialogs, analytics triggers, and similar one-shot work.

---

# 5. Explicit intents — `IntentStore`

Normal methods are the simplest choice for most Stores. Use `IntentStore<State, Intent>` when explicit intents improve the feature model.

```dart
sealed class CounterIntent {
  const CounterIntent();
}

final class IncrementIntent extends CounterIntent {
  const IncrementIntent();
}

final class ResetIntent extends CounterIntent {
  const ResetIntent();
}

class CounterStore extends IntentStore<int, CounterIntent> {
  CounterStore() : super(0);

  @override
  FutureOr<void> onIntent(CounterIntent intent) {
    switch (intent) {
      case IncrementIntent():
        commit(state + 1);
        break;
      case ResetIntent():
        commit(0);
        break;
    }
  }
}
```

Dispatch:

```dart
store.dispatch(const IncrementIntent());
```

The model is:

```text
Intent -> IntentStore -> commit(State) -> UI
                    `-> effect(...)   -> one-shot work
```

---

# 6. Undo / redo — `History<State>`

History is opt-in. A normal Store has no history overhead.

```dart
class EditorStore extends Store<EditorState> with History<EditorState> {
  EditorStore() : super(const EditorState());

  void rename(String value) {
    commit(
      state.copyWith(name: value),
    );
  }

  @override
  int get historyLimit => 100;
}
```

Available API:

```dart
store.canUndo;
store.canRedo;
store.undoCount;
store.redoCount;

store.undo();
store.redo();
store.clearHistory();
```

`undo()` and `redo()` return `bool` to indicate whether a snapshot was restored.

History behavior:

```text
commit(A -> B)
  A goes to undo history
  redo history is cleared

undo()
  current state goes to redo history
  previous snapshot becomes current state

redo()
  current state goes to undo history
  next snapshot becomes current state
```

Effects are never recorded or replayed.

Use immutable state with `History<State>`. Mutable objects can accidentally modify snapshots that are already in history.

---

# 7. Streams — `listenTo`

Popsicle does not require a separate Stream Store type. A normal Store can own an external stream subscription and convert stream events into normal state transitions.

```dart
class MessageStore extends Store<AsyncState<List<Message>>> {
  MessageStore(Stream<List<Message>> messages)
      : super(const AsyncState.idle()) {
    listenTo(
      messages,
      onData: (items) {
        commit(
          AsyncState.data(items),
        );
      },
      onError: (error, stackTrace) {
        commit(
          AsyncState.error(
            error,
            stackTrace,
            previous: state,
          ),
        );
      },
    );
  }
}
```

`listenTo(...)`:

- is protected Store API
- returns the `StreamSubscription<T>` for pause/resume/early cancellation
- is automatically cancelled when the Store is disposed
- supports `onError`, `onDone`, and `cancelOnError`
- can call `commit(...)`, `effect(...)`, or normal Store methods from stream callbacks

For example, Firebase, WebSocket, database watch queries, connectivity, and sensor streams can all feed a normal Store:

```text
External Stream
      ↓
   listenTo
      ↓
    Store
      ↓
   commit
      ↓
     .ui()
```

Subscription lifetime follows the Store lifetime, not an individual widget build.

---

# 8. Async state — `AsyncState<T>`

`AsyncState<T>` is a normal immutable value, so one Store can own multiple independent async operations.

```dart
class ProfileState {
  const ProfileState({
    this.user = const AsyncState.idle(),
    this.posts = const AsyncState.idle(),
  });

  final AsyncState<User> user;
  final AsyncState<List<Post>> posts;
}
```

Loading with stale-data preservation:

```dart
final previous = state.user;

commit(
  state.copyWith(
    user: AsyncState.loading(previous: previous),
  ),
);
```

On success:

```dart
commit(
  state.copyWith(
    user: AsyncState.data(user),
  ),
);
```

On error:

```dart
commit(
  state.copyWith(
    user: AsyncState.error(
      error,
      stackTrace,
      previous: previous,
    ),
  ),
);
```

Compose required sources:

```dart
final content = Async.combine2(
  state.user,
  state.posts,
);
```

Also available:

```dart
Async.combine3(a, b, c);
Async.combine4(a, b, c, d);
a.zip(b);
```

---

# 9. Parameterized Stores — `Popsicle.params`

Use parameterized Stores when one declaration needs independent state per argument.

```dart
class UserStore extends Store<UserState> {
  UserStore({
    required this.userId,
    required this.repository,
  }) : super(const UserState());

  final int userId;
  final UserRepository repository;
}

final user = Popsicle.params(
  (scope, int userId) => UserStore(
    userId: userId,
    repository: scope.get(userRepository),
  ),
);
```

Use it like a normal Store handle:

```dart
user(userId).ui(
  (context, state, store) {
    return UserProfile(
      state: state,
      onRefresh: store.refresh,
    );
  },
);
```

---

# 10. Selective rebuilds

Inside `PopsicleWidget`, observe only a projection of Store state:

```dart
final unreadCount = scope.select(
  inbox,
  (state) => state.unreadCount,
);
```

The widget reacts to that selected value instead of the complete state object.

---

# 11. Explicit `PopsicleConsumer`

`.ui()` is the recommended projection API. `PopsicleConsumer` remains available when an explicit widget is clearer.

```dart
PopsicleConsumer<CounterStore, int>(
  source: counter,
  build: (context, state, store) {
    return Text('$state');
  },
  effect: (context, effect) {
    // one-shot work
  },
)
```

---

# 12. Dart-only usage and testing

`PopsicleContainer` owns an isolated graph outside Flutter widgets.

```dart
final container = PopsicleContainer();

final count = container.get(counter);
final store = container.store(counter);

store.increment();

container.dispose();
```

Overrides:

```dart
final container = PopsicleContainer(
  overrides: [
    apiClient.overrideWith(
      (_) => FakeApiClient(),
    ),
  ],
);
```

Subscribe outside Flutter:

```dart
final subscription = container.subscribe(
  counter,
  (previous, next) {
    // react to state
  },
);
```

---

# Recommended feature structure

Popsicle does not force a folder convention. In feature-first projects, a presentation-specific folder works well:

```text
features/
└── profile/
    ├── data/
    ├── domain/
    └── presentation/
        ├── popsicle/
        │   ├── profile_state.dart
        │   ├── profile_intent.dart
        │   ├── profile_effect.dart
        │   └── profile_store.dart
        ├── pages/
        └── widgets/
```

For simple features, only create the files that are actually needed.

---

# Public vocabulary

```text
Declarations
  Popsicle.inject()
  Popsicle.value()
  Popsicle.create()
  Popsicle.params()

Scope
  get()
  use()
  store()
  select()
  set()
  update()

State
  ReactiveValue<T>
  Store<State>
  IntentStore<State, Intent>
  AsyncState<T>

Store transitions
  state
  commit()
  effect()
  listenTo()

Optional history
  History<State>
  undo()
  redo()
  canUndo
  canRedo

Flutter
  .ui()
  PopsicleConsumer
  PopsicleWidget
  PopsicleBuilder
  ReactiveBuilder
```

---

# Design principles

Popsicle intentionally keeps several concerns separate:

```text
State
  persistent representation
  reactive
  optionally historical

Effect
  occurrence
  one-shot
  not historical

Stream
  external input
  converted into normal Store transitions

UI
  projection of State
```

The central rule stays simple:

```text
UI = f(state)
```

See the `example/` project and `wiki/` directory for complete examples and focused guides.
