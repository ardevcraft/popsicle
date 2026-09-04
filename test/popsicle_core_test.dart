import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:popsicle/popsicle.dart';

void main() {
  group('Dependency', () {
    test('Popsicle.inject resolves a dependency', () {
      final value = Popsicle.inject((_) => 42);
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      expect(container.get(value), 42);
    });

    test('scope.get composes dependencies', () {
      final api = Popsicle.inject((_) => 'api');
      final service = Popsicle.inject(
        (scope) => '${scope.get(api)}-service',
      );
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      expect(container.get(service), 'api-service');
    });

    test('scope.use creates a reactive dependency', () {
      final selected = Popsicle.value(1);
      final doubled = Popsicle.inject(
        (scope) => scope.use(selected) * 2,
      );
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      expect(container.get(doubled), 2);

      container.set(selected, 4);
      expect(container.get(doubled), 8);
    });

    test('PopsicleOverride replaces a dependency without engine types', () {
      final api = Popsicle.inject((_) => 'prod');
      final container = PopsicleContainer(
        overrides: [
          api.overrideWith((_) => 'test'),
        ],
      );
      addTearDown(container.dispose);

      expect(container.get(api), 'test');
    });

    test('Dependency.params resolves values per argument', () {
      final label = Dependency.params<String, int>(
        (_, id) => 'item-$id',
      );
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      expect(container.get(label(1)), 'item-1');
      expect(container.get(label(2)), 'item-2');
    });
  });

  group('ReactiveValue', () {
    test('Popsicle.value stores mutable state inside a container', () {
      final counter = Popsicle.value(0);
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      expect(container.get(counter), 0);

      container.update(counter, (value) => value + 1);
      expect(container.get(counter), 1);

      container.set(counter, 10);
      expect(container.get(counter), 10);
    });

    test('same declaration has independent state per container', () {
      final counter = Popsicle.value(0);
      final first = PopsicleContainer();
      final second = PopsicleContainer();
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      first.set(counter, 7);

      expect(first.get(counter), 7);
      expect(second.get(counter), 0);
    });
  });

  group('Store', () {
    test('Popsicle.create emits Store state', () {
      final counter = Popsicle.create(
        (_) => CounterStore(0),
      );
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      expect(container.get(counter), 0);
      container.store(counter).increment();
      expect(container.get(counter), 1);
    });

    test('StoreHandle override keeps the public API Popsicle-owned', () {
      final counter = Popsicle.create((_) => CounterStore(0));
      final container = PopsicleContainer(
        overrides: [
          counter.overrideWith((_) => CounterStore(10)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.get(counter), 10);
    });

    test('Store effects are one-shot and independent from state', () {
      final store = EffectStore();
      addTearDown(store.dispose);
      final effects = <Object>[];
      final subscription = store.listenEffects(effects.add);
      addTearDown(subscription.cancel);

      store.increment();
      store.notify();
      store.notify();

      expect(store.state, 1);
      expect(effects, ['notice', 'notice']);
    });

    test('IntentStore dispatches explicit intents', () async {
      final source = Popsicle.create(
        (_) => IntentCounterStore(),
      );
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      final store = container.store(source);
      await store.dispatch(const IncrementIntent());

      expect(container.get(source), 1);
    });

    test('Popsicle.params creates argument-aware Store handles', () {
      final counters = Popsicle.params(
        (_, int initial) => CounterStore(initial),
      );
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      final ten = counters(10);
      final twenty = counters(20);

      expect(container.get(ten), 10);
      expect(container.get(twenty), 20);

      container.store(ten).increment();
      expect(container.get(ten), 11);
      expect(container.get(twenty), 20);
    });
  });

  group('History', () {
    test('tracks committed snapshots and supports undo/redo', () {
      final store = HistoryCounterStore();
      addTearDown(store.dispose);

      expect(store.state, 0);
      expect(store.canUndo, isFalse);
      expect(store.canRedo, isFalse);

      store.increment();
      store.increment();
      store.increment();

      expect(store.state, 3);
      expect(store.undoCount, 3);
      expect(store.redoCount, 0);

      expect(store.undo(), isTrue);
      expect(store.state, 2);
      expect(store.undoCount, 2);
      expect(store.redoCount, 1);

      expect(store.undo(), isTrue);
      expect(store.state, 1);

      expect(store.redo(), isTrue);
      expect(store.state, 2);
    });

    test('new commit after undo clears redo history', () {
      final store = HistoryCounterStore();
      addTearDown(store.dispose);

      store.increment();
      store.increment();
      expect(store.undo(), isTrue);
      expect(store.canRedo, isTrue);

      store.add(10);

      expect(store.state, 11);
      expect(store.canRedo, isFalse);
    });

    test('history limit bounds retained snapshots', () {
      final store = LimitedHistoryCounterStore();
      addTearDown(store.dispose);

      for (var i = 0; i < 5; i++) {
        store.increment();
      }

      expect(store.state, 5);
      expect(store.undoCount, 2);

      expect(store.undo(), isTrue);
      expect(store.state, 4);
      expect(store.undo(), isTrue);
      expect(store.state, 3);
      expect(store.undo(), isFalse);
    });

    test('effects are not replayed by undo/redo', () {
      final store = HistoryEffectStore();
      addTearDown(store.dispose);
      final effects = <Object>[];
      final subscription = store.listenEffects(effects.add);
      addTearDown(subscription.cancel);

      store.incrementAndNotify();
      expect(effects, ['changed']);

      store.undo();
      store.redo();

      expect(effects, ['changed']);
    });
  });

  group('Store streams', () {
    test('listenTo commits stream values', () async {
      final controller = StreamController<int>(sync: true);
      addTearDown(controller.close);
      final store = StreamCounterStore(controller.stream);
      addTearDown(store.dispose);

      controller.add(4);
      controller.add(9);

      expect(store.state, 9);
      expect(store.received, [4, 9]);
    });

    test('listenTo subscription is cancelled with Store disposal', () async {
      final controller = StreamController<int>(sync: true);
      addTearDown(controller.close);
      final store = StreamCounterStore(controller.stream);

      controller.add(1);
      expect(store.received, [1]);

      store.dispose();
      controller.add(2);
      await Future<void>.delayed(Duration.zero);

      expect(store.received, [1]);
    });
  });

  group('AsyncState', () {
    test('combine2 returns a record when both sources have values', () {
      const first = AsyncState.data(1);
      const second = AsyncState.data('two');

      final result = Async.combine2(first, second);

      expect(result.hasValue, isTrue);
      expect(result.requireValue, (1, 'two'));
      expect(result.isLoading, isFalse);
    });

    test('combine2 preserves values while a source refreshes', () {
      const first = AsyncState.data(1);
      const second = AsyncState.data('two');

      final refreshingFirst = AsyncState<int>.loading(previous: first);
      final result = Async.combine2(refreshingFirst, second);

      expect(result.requireValue, (1, 'two'));
      expect(result.isRefreshing, isTrue);
    });

    test('combine2 preserves stale values after refresh error', () {
      const first = AsyncState.data(1);
      const second = AsyncState.data('two');
      final stackTrace = StackTrace.current;

      final failedFirst = AsyncState<int>.error(
        StateError('failed'),
        stackTrace,
        previous: first,
      );
      final result = Async.combine2(failedFirst, second);

      expect(result.requireValue, (1, 'two'));
      expect(result.hasError, isTrue);
    });

    test('combine3 waits for all required values', () {
      const first = AsyncState.data(1);
      const second = AsyncState<String>.idle();
      final third = AsyncState<bool>.loading();

      final result = Async.combine3(first, second, third);

      expect(result.hasValue, isFalse);
      expect(result.isLoading, isTrue);
    });
  });
}

class CounterStore extends Store<int> {
  CounterStore(super.initial);

  void increment() => commit(state + 1);
}

sealed class CounterIntent {
  const CounterIntent();
}

final class IncrementIntent extends CounterIntent {
  const IncrementIntent();
}

class IntentCounterStore extends IntentStore<int, CounterIntent> {
  IntentCounterStore() : super(0);

  @override
  void onIntent(CounterIntent intent) {
    switch (intent) {
      case IncrementIntent():
        commit(state + 1);
        break;
    }
  }
}

class EffectStore extends Store<int> {
  EffectStore() : super(0);

  void increment() => commit(state + 1);

  void notify() => effect('notice');
}

class HistoryCounterStore extends Store<int> with History<int> {
  HistoryCounterStore() : super(0);

  void increment() => commit(state + 1);

  void add(int value) => commit(state + value);
}

class LimitedHistoryCounterStore extends HistoryCounterStore {
  @override
  int get historyLimit => 2;
}

class HistoryEffectStore extends Store<int> with History<int> {
  HistoryEffectStore() : super(0);

  void incrementAndNotify() {
    commit(state + 1);
    effect('changed');
  }
}

class StreamCounterStore extends Store<int> {
  StreamCounterStore(Stream<int> stream) : super(0) {
    listenTo(
      stream,
      onData: (value) {
        received.add(value);
        commit(value);
      },
    );
  }

  final List<int> received = <int>[];
}
