import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

final class MessageLoadFailed {
  const MessageLoadFailed(this.error);

  final Object error;
}

class MessageStore extends Store<AsyncState<String>> {
  MessageStore() : super(const AsyncState.idle());

  Future<void> load() async {
    commit(AsyncState.loading(previous: state));

    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      commit(const AsyncState.data('Loaded with a normal Store.'));
    } catch (error, stackTrace) {
      commit(
        AsyncState.error(
          error,
          stackTrace,
          previous: state,
        ),
      );
      effect(MessageLoadFailed(error));
    }
  }
}

final messageStore = Popsicle.create(
  (_) => MessageStore(),
);

class AsyncStoreExample extends StatelessWidget {
  const AsyncStoreExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Store')),
      body: Center(
        child: messageStore.ui(
          (context, asyncState, store) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  asyncState.when(
                    idle: () => const Text('Press load to start.'),
                    loading: () => const CircularProgressIndicator(),
                    data: (value, refreshing) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(value, textAlign: TextAlign.center),
                        if (refreshing) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                      ],
                    ),
                    error: (error, stackTrace, previousValue) => Text(
                      previousValue ?? 'Error: $error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: asyncState.isLoading ? null : store.load,
                    child: Text(asyncState.hasValue ? 'Refresh' : 'Load'),
                  ),
                ],
              ),
            );
          },
          effect: (context, effect) {
            if (effect case MessageLoadFailed(:final error)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed: $error')),
              );
            }
          },
        ),
      ),
    );
  }
}
