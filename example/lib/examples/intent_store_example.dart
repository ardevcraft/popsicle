import 'dart:async';

import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

sealed class CounterIntent {
  const CounterIntent();
}

final class IncrementIntent extends CounterIntent {
  const IncrementIntent();
}

final class ResetIntent extends CounterIntent {
  const ResetIntent();
}

class IntentCounterStore extends IntentStore<int, CounterIntent> {
  IntentCounterStore() : super(0);

  @override
  FutureOr<void> onIntent(CounterIntent intent) {
    switch (intent) {
      case IncrementIntent():
        emit(state + 1);
        break;
      case ResetIntent():
        emit(0);
        break;
    }
  }
}

final intentCounter = Popsicle.create(
  (_) => IntentCounterStore(),
);

class IntentStoreExample extends StatelessWidget {
  const IntentStoreExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IntentStore')),
      body: Center(
        child: intentCounter.view(
          (context, state, store) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$state',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () => store.dispatch(const IncrementIntent()),
                      child: const Text('Dispatch increment'),
                    ),
                    OutlinedButton(
                      onPressed: () => store.dispatch(const ResetIntent()),
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
