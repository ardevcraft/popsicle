import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

sealed class CounterEffect {
  const CounterEffect();
}

final class CounterReachedLimit extends CounterEffect {
  const CounterReachedLimit(this.count);

  final int count;
}

class CounterStore extends Store<int> {
  CounterStore() : super(0);

  void increment() {
    final next = state + 1;
    emit(next);

    if (next == 5) {
      effect(CounterReachedLimit(next));
    }
  }

  void decrement() => emit(state - 1);
  void reset() => emit(0);
}

final counterStore = StoreProvider<CounterStore, int>(
  (_) => CounterStore(),
);

class CounterConsumerExample extends StatelessWidget {
  const CounterConsumerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PopsicleConsumer')),
      body: Center(
        child: PopsicleConsumer<CounterStore, int>(
          provider: counterStore,
          effect: (context, effect) {
            if (effect is CounterReachedLimit) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Counter reached ${effect.count}'),
                ),
              );
            }
          },
          build: (context, count, store) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: store.decrement,
                      icon: const Icon(Icons.remove),
                      label: const Text('Decrease'),
                    ),
                    FilledButton.icon(
                      onPressed: store.increment,
                      icon: const Icon(Icons.add),
                      label: const Text('Increase'),
                    ),
                    OutlinedButton(
                      onPressed: store.reset,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
