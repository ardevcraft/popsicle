# Parameterized State

Use `Popsicle.params` when Store identity depends on a runtime argument.

```dart
final user = Popsicle.params(
  (scope, int id) => UserStore(
    id: id,
    repository: scope.get(userRepository),
  ),
);
```

Render one instance:

```dart
user(42).view(
  (context, state, store) => UserProfile(state: state),
);
```

Each argument has an independent graph identity and cached state.
