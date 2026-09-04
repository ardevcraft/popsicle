# Async State

Popsicle keeps async state as a normal immutable value:

```dart
Store<AsyncState<User>>
```

No separate async Store hierarchy is required.

```dart
class UserStore extends Store<AsyncState<User>> {
  UserStore() : super(const AsyncState.idle());

  Future<void> load() async {
    final previous = state;
    commit(AsyncState.loading(previous: previous));

    try {
      final user = await fetchUser();
      commit(AsyncState.data(user));
    } catch (error, stackTrace) {
      commit(
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

For multiple independent sources:

```dart
final combined = Async.combine2(user, posts);
```

or:

```dart
final combined = user.zip(posts);
```

`AsyncState` can preserve stale values during refresh and refresh errors, allowing UI to keep rendering useful content.
