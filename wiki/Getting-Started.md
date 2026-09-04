# Getting Started

```dart
import 'package:popsicle/popsicle.dart';
```

Wrap the app:

```dart
runApp(
  const Popsicle(
    child: MyApp(),
  ),
);
```

The four recommended declarations are:

```dart
Popsicle.inject(...)
Popsicle.value(...)
Popsicle.create(...)
Popsicle.params(...)
```

Example:

```dart
final api = Popsicle.inject((_) => ApiClient());
final count = Popsicle.value(0);
final counter = Popsicle.create((_) => CounterStore());
```

Store:

```dart
class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() => commit(state + 1);
}
```

Render small state:

```dart
count.ui((value) => Text('$value'));
```

Render Store state:

```dart
counter.ui(
  (context, state, store) => Text('$state'),
);
```
