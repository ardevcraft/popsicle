# Async State

Popsicle keeps async state as a normal immutable value:

```dart
Store<AsyncState<User>>
```

No separate async Store hierarchy is required.

For multiple independent sources:

```dart
final combined = Async.combine2(user, posts);
```

or:

```dart
final combined = user.zip(posts);
```

`AsyncState` can preserve stale values during refresh and refresh errors, allowing the UI to keep rendering useful content.
