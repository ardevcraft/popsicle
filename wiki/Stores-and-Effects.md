# Stores and Effects

```dart
class ProfileStore extends Store<ProfileState> {
  ProfileStore(this.repository) : super(const ProfileState());

  final ProfileRepository repository;

  Future<void> refresh() async {
    // ...
    emit(nextState);
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
profile.view(
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

Use `emit` for persistent state and `effect` for one-shot work. Effects are not replayed and do not rebuild the view.
