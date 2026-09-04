# Migration to 2.1

Popsicle 2.1 keeps the 2.0 declaration and Scope APIs.

## Persistent State

```text
emit(nextState) -> commit(nextState)
```

## UI Projection

```text
.view(...) -> .ui(...)
```

## New opt-in History

```dart
class EditorStore extends Store<EditorState> with History<EditorState> {
  // ...
}
```

## New Store stream ownership

```dart
listenTo(
  stream,
  onData: (value) => commit(...),
);
```

See the root `MIGRATION_NOTES.md` for the complete migration guide.
