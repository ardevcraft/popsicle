import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

final reactiveCounter = ReactiveValue(0);

class ReactiveValueExample extends PopsicleWidget {
  const ReactiveValueExample({super.key});

  @override
  Widget build(BuildContext context, PopsicleRef ref) {
    final count = ref.watch(reactiveCounter);

    return Scaffold(
      appBar: AppBar(title: const Text('ReactiveValue')),
      body: Center(
        child: Column(
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
                FilledButton.tonal(
                  onPressed: () {
                    ref.update(reactiveCounter, (value) => value - 1);
                  },
                  child: const Text('Decrease'),
                ),
                FilledButton(
                  onPressed: () {
                    ref.update(reactiveCounter, (value) => value + 1);
                  },
                  child: const Text('Increase'),
                ),
                OutlinedButton(
                  onPressed: () => ref.set(reactiveCounter, 0),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
