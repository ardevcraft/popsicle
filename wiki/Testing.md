# Testing

Use an isolated `PopsicleContainer`:

```dart
final container = PopsicleContainer();
addTearDown(container.dispose);
```

```dart
final count = container.get(counterValue);
container.update(counterValue, (value) => value + 1);
```

Store testing:

```dart
final store = container.store(counterStore);
store.increment();
expect(container.get(counterStore), 1);
```

Separate containers isolate scoped reactive values and Store instances.

## Overrides

```dart
final api = Popsicle.inject((_) => RealApi());

final container = PopsicleContainer(
  overrides: [
    api.overrideWith((_) => FakeApi()),
  ],
);
```

Store handles support the same pattern:

```dart
final counter = Popsicle.create((_) => CounterStore(0));

final container = PopsicleContainer(
  overrides: [
    counter.overrideWith((_) => CounterStore(10)),
  ],
);
```
