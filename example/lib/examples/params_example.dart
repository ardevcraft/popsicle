import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

class ItemCounterStore extends Store<int> {
  ItemCounterStore(this.itemId) : super(0);

  final int itemId;

  void increment() => emit(state + 1);
}

final itemCounters = StoreProvider.params<ItemCounterStore, int, int>(
  (_, itemId) => ItemCounterStore(itemId),
);

class ParamsExample extends StatelessWidget {
  const ParamsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StoreProvider.params')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _CounterTile(itemId: 101),
          _CounterTile(itemId: 202),
          _CounterTile(itemId: 303),
        ],
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context) {
    final provider = itemCounters(itemId);

    return Card(
      child: PopsicleConsumer<ItemCounterStore, int>(
        provider: provider,
        build: (context, count, store) {
          return ListTile(
            title: Text('Item ${store.itemId}'),
            subtitle: Text('Count: $count'),
            trailing: IconButton(
              onPressed: store.increment,
              icon: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
