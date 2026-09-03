import 'dart:async';

import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

sealed class CounterAction {
  const CounterAction();
}

final class IncrementAction extends CounterAction {
  const IncrementAction();
}

final class ResetAction extends CounterAction {
  const ResetAction();
}

class ActionCounterStore extends IntentStore<int, CounterAction> {
  ActionCounterStore() : super(0);

  @override
  FutureOr<void> onIntent(CounterAction action) {
    switch (action) {
      case IncrementAction():
        emit(state + 1);
        break;
      case ResetAction():
        emit(0);
        break;
    }
  }
}

final actionCounter = StoreProvider<ActionCounterStore, int>(
  (_) => ActionCounterStore(),
);

class IntentStoreExample extends StatelessWidget {
  const IntentStoreExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IntentStore')),
      body: Center(
        child: PopsicleConsumer<ActionCounterStore, int>(
          provider: actionCounter,
          build: (context, state, store) {
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
                      onPressed: () => store.dispatch(const IncrementAction()),
                      child: const Text('Dispatch increment'),
                    ),
                    OutlinedButton(
                      onPressed: () => store.dispatch(const ResetAction()),
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
