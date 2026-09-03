import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popsicle/popsicle.dart';

final _counter = StoreProvider<_CounterStore, int>(
  (_) => _CounterStore(),
);

final _effectCounter = StoreProvider<_EffectCounterStore, int>(
  (_) => _EffectCounterStore(),
);

final _reactiveCounter = ReactiveValue(0);

void main() {
  testWidgets('PopsicleWidget watches state and reads Store actions', (
    tester,
  ) async {
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

  testWidgets('ReactiveValue rebuilds and updates without a Store',
      (tester) async {
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

  testWidgets('PopsicleConsumer builds Store state', (tester) async {
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

  testWidgets('PopsicleConsumer receives only explicitly emitted effects', (
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

    // Normal rebuilds do not replay one-shot effects.
    await tester.pump();
    expect(effects, [2]);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(effects, [2]);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(effects, [2, 4]);
  });

  testWidgets('Store effect does not rebuild PopsicleConsumer', (tester) async {
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

  testWidgets('PopsicleConsumer effect callback is optional', (tester) async {
    await tester.pumpWidget(
      const Popsicle(
        child: MaterialApp(
          home: _EffectConsumerHarness(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('PopsicleBuilder watches a dependency', (tester) async {
    final message = Dependency<String>((_) => 'hello');

    await tester.pumpWidget(
      Popsicle(
        child: MaterialApp(
          home: PopsicleBuilder(
            builder: (context, ref, child) {
              return Text(ref.watch(message));
            },
          ),
        ),
      ),
    );

    expect(find.text('hello'), findsOneWidget);
  });
}

class _CounterStore extends Store<int> {
  _CounterStore() : super(0);

  void increment() => emit(state + 1);
}

class _CounterPage extends PopsicleWidget {
  const _CounterPage();

  @override
  Widget build(BuildContext context, PopRef ref) {
    final count = ref.watch(_counter);
    final actions = ref.store(_counter);

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
    return PopsicleConsumer<_EffectCounterStore, int>(
      provider: _effectCounter,
      effect: (context, effect) {
        if (effect is _EvenCountEffect) {
          onEffect?.call(effect.count);
        }
      },
      build: (context, state, store) {
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
    );
  }
}

class _ReactiveValuePage extends PopsicleWidget {
  const _ReactiveValuePage();

  @override
  Widget build(BuildContext context, PopRef ref) {
    final count = ref.watch(_reactiveCounter);

    return Scaffold(
      body: Text('$count'),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'reset-reactive',
            onPressed: () => ref.set(_reactiveCounter, 0),
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'increment-reactive',
            onPressed: () => ref.update(_reactiveCounter, (value) => value + 1),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
