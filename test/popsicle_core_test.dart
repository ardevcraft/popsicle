import 'package:flutter_test/flutter_test.dart';
import 'package:popsicle/popsicle.dart';

void main() {
  group('Dependency', () {
    test('resolves a dependency', () {
      final value = Dependency<int>((_) => 42);
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      expect(container.read(value), 42);
    });

    test('params resolves values per argument', () {
      final label = Dependency.params<String, int>(
        (_, id) => 'item-$id',
      );
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      expect(container.read(label(1)), 'item-1');
      expect(container.read(label(2)), 'item-2');
    });
  });

  group('ReactiveValue', () {
    test('stores simple mutable state inside a container', () {
      final counter = ReactiveValue(0);
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      expect(container.read(counter), 0);

      container.update(counter, (value) => value + 1);
      expect(container.read(counter), 1);

      container.set(counter, 10);
      expect(container.read(counter), 10);
    });

    test('same declaration has independent state per container', () {
      final counter = ReactiveValue(0);
      final first = PopsicleContainer();
      final second = PopsicleContainer();
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      first.set(counter, 7);

      expect(first.read(counter), 7);
      expect(second.read(counter), 0);
    });
  });

  group('Store', () {
    test('emits state through StoreProvider', () {
      final counter = StoreProvider<CounterStore, int>(
        (_) => CounterStore(0),
      );
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      expect(container.read(counter), 0);
      container.read(counter.store).increment();
      expect(container.read(counter), 1);
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

    test('ActionStore dispatches explicit actions', () async {
      final provider = StoreProvider<ActionCounterStore, int>(
        (_) => ActionCounterStore(),
      );
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      final store = container.read(provider.store);
      await store.dispatch(const IncrementAction());

      expect(container.read(provider), 1);
    });

    test('params creates argument-aware Store handles', () {
      final counters = StoreProvider.params<CounterStore, int, int>(
        (_, initial) => CounterStore(initial),
      );
      final container = PopsicleContainer();
      addTearDown(container.dispose);

      final ten = counters(10);
      final twenty = counters(20);

      expect(container.read(ten), 10);
      expect(container.read(twenty), 20);

      container.read(ten.notifier).increment();
      expect(container.read(ten), 11);
      expect(container.read(twenty), 20);
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

  void increment() => emit(state + 1);
}

sealed class CounterAction {
  const CounterAction();
}

final class IncrementAction extends CounterAction {
  const IncrementAction();
}

class ActionCounterStore extends IntentStore<int, CounterAction> {
  ActionCounterStore() : super(0);

  @override
  void onIntent(CounterAction action) {
    switch (action) {
      case IncrementAction():
        emit(state + 1);
    }
  }
}

class EffectStore extends Store<int> {
  EffectStore() : super(0);

  void increment() => emit(state + 1);

  void notify() => effect('notice');
}
