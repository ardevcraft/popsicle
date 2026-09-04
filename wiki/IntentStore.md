# IntentStore

`IntentStore` is optional structure for workflows where an explicit intent boundary improves readability.

```text
Intent -> IntentStore -> commit(State) -> UI
                    `-> effect(...)   -> one-shot work
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
        // commit(nextState);
        break;
    }
  }
}
```

Dispatch with:

```dart
store.dispatch(const SubmitLogin());
```

Do not introduce intents for every button by default. Normal Store methods remain the simpler default.
