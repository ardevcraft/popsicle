import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

final reactiveCounter = Popsicle.value(0);

class ReactiveValueExample extends StatelessWidget {
  const ReactiveValueExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popsicle.value')),
      body: Center(
        child: reactiveCounter.ui(
          (count) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
                PopsicleBuilder(
                  builder: (context, scope, child) {
                    return Wrap(
                      spacing: 12,
                      children: [
                        FilledButton.tonal(
                          onPressed: () {
                            scope.update(
                              reactiveCounter,
                              (value) => value - 1,
                            );
                          },
                          child: const Text('Decrease'),
                        ),
                        FilledButton(
                          onPressed: () {
                            scope.update(
                              reactiveCounter,
                              (value) => value + 1,
                            );
                          },
                          child: const Text('Increase'),
                        ),
                        OutlinedButton(
                          onPressed: () => scope.set(reactiveCounter, 0),
                          child: const Text('Reset'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
