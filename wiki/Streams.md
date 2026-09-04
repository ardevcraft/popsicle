# Streams

A normal Store can own external stream subscriptions with `listenTo(...)`.

```dart
class LiveMessagesStore extends Store<List<Message>> {
  LiveMessagesStore(Stream<List<Message>> messages) : super(const []) {
    listenTo(
      messages,
      onData: commit,
      onError: (error, stackTrace) {
        effect(StreamFailed(error));
      },
    );
  }
}
```

Popsicle does not require a separate Stream Store hierarchy:

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

`listenTo(...)` supports:

```text
onData
onError
onDone
cancelOnError
```

It returns the underlying `StreamSubscription<T>` so a Store can pause, resume, or cancel early when needed.

Subscriptions registered through `listenTo(...)` are cancelled automatically when the Store is disposed. Their lifetime therefore follows the Store, not an individual widget build.
