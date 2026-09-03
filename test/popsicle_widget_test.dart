import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popsicle/popsicle.dart';

final _counter = Popsicle.create(
  (_) => _CounterStore(),
);

final _effectCounter = Popsicle.create(
  (_) => _EffectCounterStore(),
);

final _reactiveCounter = Popsicle.value(0);

void main() {
  testWidgets('PopsicleWidget uses scope.use and scope.store', (tester) async {
    await tester.pumpWidget(
      const Popsicle(
        child: MaterialApp(
          home: _CounterPage(),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('ReactiveValue.view works in a normal StatelessWidget', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Popsicle(
        child: MaterialApp(
          home: _ReactiveValuePage(),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Store.view builds Store state', (tester) async {
    await tester.pumpWidget(
      const Popsicle(
        child: MaterialApp(
          home: _EffectConsumerHarness(),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Store.view receives only explicitly emitted effects', (
    tester,
  ) async {
    final effects = <int>[];

    await tester.pumpWidget(
      Popsicle(
        child: MaterialApp(
          home: _EffectConsumerHarness(
            onEffect: effects.add,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(effects, isEmpty);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(effects, [2]);

    await tester.pump();
    expect(effects, [2]);
  });

  testWidgets('effect-only emission does not rebuild Store.view', (
    tester,
  ) async {
    final effects = <int>[];
    var builds = 0;

    await tester.pumpWidget(
      Popsicle(
        child: MaterialApp(
          home: _EffectConsumerHarness(
            onEffect: effects.add,
            onBuild: () => builds++,
          ),
        ),
      ),
    );

    final initialBuilds = builds;

    await tester.tap(find.byIcon(Icons.notifications));
    await tester.pump();

    expect(effects, [0]);
    expect(find.text('0'), findsOneWidget);
    expect(builds, initialBuilds);
  });

  testWidgets('PopsicleBuilder exposes scope.get/use', (tester) async {
    final name = Popsicle.value('Popsicle');
    final message = Popsicle.inject(
      (scope) => 'Hello ${scope.use(name)}',
    );

    await tester.pumpWidget(
      Popsicle(
        child: MaterialApp(
          home: PopsicleBuilder(
            builder: (context, scope, child) {
              return Text(scope.use(message));
            },
          ),
        ),
      ),
    );

    expect(find.text('Hello Popsicle'), findsOneWidget);
  });
}

class _CounterStore extends Store<int> {
  _CounterStore() : super(0);

  void increment() => emit(state + 1);
}

class _CounterPage extends PopsicleWidget {
  const _CounterPage();

  @override
  Widget build(BuildContext context, Scope scope) {
    final count = scope.use(_counter);
    final actions = scope.store(_counter);

    return Scaffold(
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        onPressed: actions.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}

final class _EvenCountEffect {
  const _EvenCountEffect(this.count);

  final int count;
}

class _EffectCounterStore extends Store<int> {
  _EffectCounterStore() : super(0);

  void increment() {
    final next = state + 1;
    emit(next);

    if (next.isEven) {
      effect(_EvenCountEffect(next));
    }
  }

  void notifyOnly() => effect(_EvenCountEffect(state));
}

class _EffectConsumerHarness extends StatelessWidget {
  const _EffectConsumerHarness({
    this.onEffect,
    this.onBuild,
  });

  final void Function(int count)? onEffect;
  final VoidCallback? onBuild;

  @override
  Widget build(BuildContext context) {
    return _effectCounter.view(
      (context, state, store) {
        onBuild?.call();
        return Scaffold(
          body: Text('$state'),
          floatingActionButton: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'effect-only',
                onPressed: store.notifyOnly,
                child: const Icon(Icons.notifications),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                heroTag: 'increment',
                onPressed: store.increment,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        );
      },
      effect: (context, effect) {
        if (effect is _EvenCountEffect) {
          onEffect?.call(effect.count);
        }
      },
    );
  }
}

class _ReactiveValuePage extends StatelessWidget {
  const _ReactiveValuePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _reactiveCounter.view(
        (count) => Text('$count'),
      ),
      floatingActionButton: PopsicleBuilder(
        builder: (context, scope, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'reset-reactive',
                onPressed: () => scope.set(_reactiveCounter, 0),
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                heroTag: 'increment-reactive',
                onPressed: () {
                  scope.update(_reactiveCounter, (value) => value + 1);
                },
                child: const Icon(Icons.add),
              ),
            ],
          );
        },
      ),
    );
  }
}
