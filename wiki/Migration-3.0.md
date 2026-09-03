# Migration to 3.0

## Declarations

```text
Dependency(...)           -> Popsicle.inject(...)
ReactiveValue(...)        -> Popsicle.value(...)
StoreProvider(...)        -> Popsicle.create(...)
StoreProvider.params(...) -> Popsicle.params(...)
```

## Scoped access

```text
ref.read(source)  -> scope.get(source)
ref.watch(source) -> scope.use(source)
```

## UI

Prefer `.view()`:

```dart
value.view((state) => UI);

store.view(
  (context, state, controller) => UI,
  effect: (context, effect) {},
);
```

See the root `MIGRATION_NOTES.md` for the full migration guide.
