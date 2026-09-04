# Stores and Effects

A Store owns persistent state and behavior:

```dart
class ProfileStore extends Store<ProfileState> {
  ProfileStore(this.repository) : super(const ProfileState());

  final ProfileRepository repository;

  Future<void> refresh() async {
    final nextState = await repository.load();
    commit(nextState);
  }
}
```

Declare:

```dart
final profile = Popsicle.create(
  (scope) => ProfileStore(
    scope.get(profileRepository),
  ),
);
```

Render:

```dart
profile.ui(
  (context, state, store) {
    return ProfileBody(
      state: state,
      onRefresh: store.refresh,
    );
  },
  effect: (context, effect) {
    // snackbar/navigation/dialog/etc.
  },
);
```

## `commit`

Use `commit(...)` for persistent state transitions:

```dart
commit(nextState);
```

## `effect`

Use `effect(...)` for one-shot occurrences:

```dart
effect(const ProfileSaved());
```

Effects are not state, are not replayed on rebuild, do not rebuild Store UI by themselves, and are not included in History.
