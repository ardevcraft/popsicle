import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

class ItemCounterStore extends Store<int> {
  ItemCounterStore(this.itemId) : super(0);

  final int itemId;

  void increment() => commit(state + 1);
}

final itemCounters = Popsicle.params(
  (_, int itemId) => ItemCounterStore(itemId),
);

class ParamsExample extends StatelessWidget {
  const ParamsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popsicle.params')),
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
    return Card(
      child: itemCounters(itemId).ui(
        (context, count, store) {
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
