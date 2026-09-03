# Dependency Injection

```dart
final apiClient = Popsicle.inject(
  (_) => ApiClient(),
);

final repository = Popsicle.inject(
  (scope) => UserRepository(
    scope.get(apiClient),
  ),
);
```

Use `scope.get` for ordinary constructor dependencies.

Use `scope.use` when the dependency itself should recompute when another reactive declaration changes:

```dart
final environment = Popsicle.value(Environment.production);

final baseUrl = Popsicle.inject(
  (scope) => scope.use(environment).baseUrl,
);
```

Avoid service-locator lookups inside Store methods. Resolve dependencies when the Store is created and keep constructor injection explicit.
