import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

class HistoryCounterStore extends Store<int> with History<int> {
  HistoryCounterStore() : super(0);

  void increment() => commit(state + 1);

  void decrement() => commit(state - 1);

  @override
  int get historyLimit => 20;
}

final historyCounter = Popsicle.create(
  (_) => HistoryCounterStore(),
);

class HistoryExample extends StatelessWidget {
  const HistoryExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Center(
        child: historyCounter.ui(
          (context, state, store) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$state',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Undo: ${store.undoCount}  •  Redo: ${store.redoCount}',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
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
                    OutlinedButton.icon(
                      onPressed: store.canUndo ? store.undo : null,
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: store.canRedo ? store.redo : null,
                      icon: const Icon(Icons.redo),
                      label: const Text('Redo'),
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
