# Migrating to Popsicle 2.1

Popsicle 2.1 keeps the 2.0 declaration and `Scope` model, while tightening the state-transition vocabulary and adding opt-in Store capabilities.

## State transition rename

Use `commit(...)` for persistent Store state:

```dart
// Before
emit(nextState);

// 2.1
commit(nextState);
```

`effect(...)` is unchanged and remains the one-shot output channel.

## UI projection rename

Use `.ui()`:

```dart
// Before
counter.view(
  (context, state, store) => Text('$state'),
);

// 2.1
counter.ui(
  (context, state, store) => Text('$state'),
);
```

The corresponding public extension names are now `PopsicleStoreUi` and `ReactiveValueUi`.

## Undo / redo

Add `History<State>` only to Stores that need it:

```dart
class EditorStore extends Store<EditorState> with History<EditorState> {
  EditorStore() : super(const EditorState());
}
```

Then use:

```dart
store.undo();
store.redo();
store.canUndo;
store.canRedo;
```

Normal Stores have no history behavior or history storage.

## Streams

A Store can now own stream subscriptions through `listenTo(...)`:

```dart
class LiveStore extends Store<LiveState> {
  LiveStore(Stream<Event> events) : super(const LiveState()) {
    listenTo(
      events,
      onData: (event) {
        commit(state.apply(event));
      },
    );
  }
}
```

Subscriptions registered with `listenTo` are cancelled automatically when the Store is disposed.

## What did not change

The recommended declarations remain:

```dart
Popsicle.inject(...)
Popsicle.value(...)
Popsicle.create(...)
Popsicle.params(...)
```

`Scope` remains:

```dart
scope.get(...)
scope.use(...)
scope.store(...)
scope.select(...)
```

And the core types remain `Store`, `IntentStore`, `ReactiveValue`, and `AsyncState`.
