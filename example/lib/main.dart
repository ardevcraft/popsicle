import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

import 'examples/intent_store_example.dart';
import 'examples/async_store_example.dart';
import 'examples/combined_async_example.dart';
import 'examples/counter_consumer_example.dart';
import 'examples/dependency_example.dart';
import 'examples/params_example.dart';
import 'examples/reactive_value_example.dart';

void main() {
  runApp(
    const PopsicleScope(
      child: PopsicleExampleApp(),
    ),
  );
}

class PopsicleExampleApp extends StatelessWidget {
  const PopsicleExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Popsicle examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final examples = <({String title, String subtitle, Widget page})>[
      (
        title: 'Dependency',
        subtitle: 'Plain DI plus a generic PopsicleBuilder boundary',
        page: const DependencyExample(),
      ),
      (
        title: 'ReactiveValue',
        subtitle: 'Small scoped mutable state without creating a Store',
        page: const ReactiveValueExample(),
      ),
      (
        title: 'PopsicleConsumer',
        subtitle: 'Store state + one-off side effects with one subscription',
        page: const CounterConsumerExample(),
      ),
      (
        title: 'Async Store',
        subtitle: 'AsyncState inside a normal Store',
        page: const AsyncStoreExample(),
      ),
      (
        title: 'Combined async sources',
        subtitle: 'Compose two independent async values with Async.combine2',
        page: const CombinedAsyncExample(),
      ),
      (
        title: 'IntentStore',
        subtitle: 'Optional Action -> Store -> State workflow',
        page: const IntentStoreExample(),
      ),
      (
        title: 'Parameterized Store',
        subtitle: 'StoreProvider.params without public family terminology',
        page: const ParamsExample(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Popsicle 0.1.4 examples')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: examples.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final example = examples[index];
          return Card(
            child: ListTile(
              title: Text(example.title),
              subtitle: Text(example.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => example.page,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
