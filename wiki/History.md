# History

`History<State>` adds opt-in undo/redo to a Store.

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

API:

```dart
store.canUndo;
store.canRedo;
store.undoCount;
store.redoCount;
store.undo();
store.redo();
store.clearHistory();
```

`undo()` and `redo()` return `bool` indicating whether a snapshot was restored.

A normal `commit(...)` records the previous State and clears redo history. Undo/redo restore snapshots without recording themselves as new transitions.

Effects are never recorded or replayed.

Use immutable State with History so older snapshots cannot be changed through shared mutable references.
