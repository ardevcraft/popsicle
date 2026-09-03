# IntentStore

`IntentStore` is optional structure for workflows where an explicit intent boundary improves readability.

```text
Intent -> IntentStore -> State -> UI
```

```dart
sealed class LoginIntent {
  const LoginIntent();
}

final class SubmitLogin extends LoginIntent {
  const SubmitLogin();
}

class LoginStore extends IntentStore<LoginState, LoginIntent> {
  LoginStore() : super(const LoginState());

  @override
  Future<void> onIntent(LoginIntent intent) async {
    switch (intent) {
      case SubmitLogin():
        break;
    }
  }
}
```

Dispatch with:

```dart
store.dispatch(const SubmitLogin());
```

Do not use intents for every button by default. Normal Store methods remain the simpler default.
