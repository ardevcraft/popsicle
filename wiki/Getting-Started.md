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

Render small state:

```dart
count.view((value) => Text('$value'));
```

Render Store state:

```dart
counter.view(
  (context, state, store) => Text('$state'),
);
```
