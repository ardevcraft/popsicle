import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

final tickerStream = Popsicle.inject(
  (_) => Stream<int>.periodic(
    const Duration(seconds: 1),
    (tick) => tick + 1,
  ),
);

class TickerStore extends Store<int> {
  TickerStore(Stream<int> stream) : super(0) {
    listenTo(
      stream,
      onData: commit,
      onError: (error, stackTrace) {
        effect(TickerFailed(error));
      },
    );
  }
}

final class TickerFailed {
  const TickerFailed(this.error);

  final Object error;
}

final ticker = Popsicle.create(
  (scope) => TickerStore(
    scope.get(tickerStream),
  ),
);

class StreamStoreExample extends StatelessWidget {
  const StreamStoreExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store streams')),
      body: Center(
        child: ticker.ui(
          (context, tick, store) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$tick',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                const Text('The Store owns and disposes the subscription.'),
              ],
            );
          },
          effect: (context, effect) {
            if (effect is TickerFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Stream failed: ${effect.error}')),
              );
            }
          },
        ),
      ),
    );
  }
}
