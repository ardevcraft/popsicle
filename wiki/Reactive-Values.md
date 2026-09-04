# Reactive Values

Use `Popsicle.value` for a small standalone mutable value:

```dart
final selectedTab = Popsicle.value(0);
```

Render:

```dart
selectedTab.ui(
  (index) => Text('$index'),
);
```

Mutate from a Scope:

```dart
scope.set(selectedTab, 2);
scope.update(selectedTab, (index) => index + 1);
```

Use a Store instead when the state grows behavior, multiple related fields, async orchestration, or effects.
