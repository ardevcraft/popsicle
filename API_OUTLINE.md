# Popsicle 3.0 Public API Outline

## Core philosophy

```text
UI = f(state)

method / Intent -> Store -> State -> .view()
                         `-> Effect -> one-shot UI work
```

## Recommended declaration namespace

### `Popsicle.inject`

```dart
final api = Popsicle.inject(
  (_) => ApiClient(),
);

final repository = Popsicle.inject(
  (scope) => Repository(scope.get(api)),
);
```

### `Popsicle.value`

```dart
final counter = Popsicle.value(0);
```

### `Popsicle.create`

```dart
final counter = Popsicle.create(
  (_) => CounterStore(),
);
```

### `Popsicle.params`

```dart
final user = Popsicle.params(
  (scope, int id) => UserStore(
    id: id,
    repository: scope.get(repository),
  ),
);
```

## Scope

```dart
scope.get(source); // non-reactive access
scope.use(source); // reactive dependency
```

Additional extensions:

```dart
scope.store(storeSource);
scope.select(storeSource, selector);
scope.set(reactiveValue, next);
scope.update(reactiveValue, update);
```

## State

### `ReactiveValue<T>`

```dart
counter.view(
  (value) => Text('$value'),
);
```

### `Store<State>`

```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => emit(state + 1);
}
```

### `IntentStore<State, Intent>`

```dart
class CheckoutStore extends IntentStore<CheckoutState, CheckoutIntent> {
  CheckoutStore() : super(const CheckoutState());

  @override
  Future<void> onIntent(CheckoutIntent intent) async {}
}
```

## Output channels

```dart
emit(nextState); // persistent/replayable state
effect(value);   // one-shot/non-replayed effect
```

## UI

Preferred:

```dart
reactiveValue.view((state) => UI);

storeSource.view(
  (context, state, store) => UI,
  effect: (context, effect) {},
);
```

Explicit lower-level widgets:

```text
ReactiveBuilder
PopsicleConsumer
PopsicleWidget
PopsicleBuilder
```

## Async

```dart
AsyncState<T>
Async.combine2(a, b)
Async.combine3(a, b, c)
Async.combine4(a, b, c, d)
a.zip(b)
```

## Dart/testing

```dart
final container = PopsicleContainer();

container.get(source);
container.store(storeSource);
container.set(value, next);
container.update(value, update);
container.subscribe(source, listener);
container.dispose();
```

## Advanced compatibility types

These remain available but are not the primary application API:

```text
Dependency<T>
Dependency.params
StoreHandle<Store, State>
StoreParams<Store, State, Arg>
PopsicleOverride
PopsicleSubscription
PopsicleSource
```
