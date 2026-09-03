# Migrating to Popsicle 3.0

Popsicle 3.0 simplifies the public vocabulary around one declaration namespace and one scoped dependency context.

## Declaration migration

| Previous API | Popsicle 3.0 recommended API |
| --- | --- |
| `Dependency((ref) => ...)` | `Popsicle.inject((scope) => ...)` |
| `ReactiveValue(value)` | `Popsicle.value(value)` |
| `StoreProvider((ref) => ...)` | `Popsicle.create((scope) => ...)` |
| `StoreProvider.params(...)` | `Popsicle.params(...)` |

The underlying declaration classes remain available for advanced compatibility, but new code should prefer `Popsicle.*`.

## Reference migration

```dart
// Before
ref.read(apiClient)
ref.watch(themeMode)
```

```dart
// 3.0
scope.get(apiClient)
scope.use(themeMode)
```

Meaning:

```text
get = access without a reactive relationship
use = access and depend on future changes
```

## Store access

```dart
// Before
final state = ref.watch(counter);
final store = ref.store(counter);
```

```dart
// 3.0 low-level widget
final state = scope.use(counter);
final store = scope.store(counter);
```

Most UI can remove both lookups entirely by using `.view()`:

```dart
counter.view(
  (context, state, store) {
    return Text('$state');
  },
);
```

## ReactiveValue UI

```dart
// Before
class CounterView extends PopsicleWidget {
  Widget build(BuildContext context, PopRef ref) {
    final count = ref.watch(counter);
    return Text('$count');
  }
}
```

```dart
// 3.0
class CounterView extends StatelessWidget {
  Widget build(BuildContext context) {
    return counter.view(
      (count) => Text('$count'),
    );
  }
}
```

Mutation:

```dart
scope.set(counter, 0);
scope.update(counter, (value) => value + 1);
```

## PopsicleWidget

```dart
class Header extends PopsicleWidget {
  @override
  Widget build(BuildContext context, Scope scope) {
    final theme = scope.use(themeMode);
    return Text('$theme');
  }
}
```


## IntentStore

`IntentStore` is the current name for the optional structured intent workflow.

```text
Intent -> IntentStore -> State -> UI
```

Simple Stores should continue using normal Dart methods.

## Versioning

The public reference/declaration syntax is a breaking API change, so the publishable package is versioned as **3.0.0**.
