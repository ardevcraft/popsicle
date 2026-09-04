# Popsicle 2.1 Public API Outline

## Core model

```text
method / Intent / Stream -> Store -> commit(State) -> .ui()
                                  `-> effect(...)   -> one-shot UI work
```

## Declarations

```dart
Popsicle.inject(...)
Popsicle.value(...)
Popsicle.create(...)
Popsicle.params(...)
```

## Scope

```dart
scope.get(source);    // non-reactive access
scope.use(source);    // reactive dependency
scope.store(source);  // Store instance
scope.select(source, selector);
scope.set(value, next);
scope.update(value, update);
```

## State primitives

```text
ReactiveValue<T>
Store<State>
IntentStore<State, Intent>
AsyncState<T>
```

## Store output

```dart
commit(nextState); // persistent state transition
effect(value);     // one-shot occurrence
```

## Store streams

```dart
listenTo(
  stream,
  onData: (value) => commit(...),
  onError: (error, stackTrace) => effect(...),
);
```

Subscriptions registered through `listenTo` are owned by the Store and cancelled on Store disposal.

## History

```dart
class EditorStore extends Store<EditorState> with History<EditorState> {
  // ...
}
```

```dart
store.canUndo;
store.canRedo;
store.undoCount;
store.redoCount;
store.undo();
store.redo();
store.clearHistory();
```

History records committed State only. Effects are never recorded or replayed.

## Flutter UI

```dart
reactiveValue.ui((state) => UI);

storeSource.ui(
  (context, state, store) => UI,
  effect: (context, effect) {},
);
```

Explicit widgets:

```text
ReactiveBuilder
PopsicleConsumer
PopsicleWidget
PopsicleBuilder
```

## Async composition

```dart
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

## Advanced declaration types

These remain public for advanced use, while application code should normally prefer `Popsicle.*`:

```text
Dependency<T>
Dependency.params
StoreHandle<Store, State>
StoreParams<Store, State, Arg>
PopsicleOverride
PopsicleSubscription
PopsicleSource
```
