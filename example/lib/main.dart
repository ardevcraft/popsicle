import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

import 'examples/async_store_example.dart';
import 'examples/combined_async_example.dart';
import 'examples/counter_consumer_example.dart';
import 'examples/dependency_example.dart';
import 'examples/history_example.dart';
import 'examples/intent_store_example.dart';
import 'examples/params_example.dart';
import 'examples/reactive_value_example.dart';
import 'examples/stream_store_example.dart';

final themeMode = Popsicle.value(ThemeMode.system);

void main() {
  runApp(
    const Popsicle(
      child: PopsicleExampleApp(),
    ),
  );
}

class PopsicleExampleApp extends PopsicleWidget {
  const PopsicleExampleApp({super.key});

  @override
  Widget build(BuildContext context, Scope scope) {
    final mode = scope.use(themeMode);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Popsicle examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: mode,
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
        subtitle: 'Popsicle.inject with scope.get / scope.use',
        page: const DependencyExample(),
      ),
      (
        title: 'ReactiveValue',
        subtitle: 'Popsicle.value + value.ui()',
        page: const ReactiveValueExample(),
      ),
      (
        title: 'Store UI',
        subtitle: 'Popsicle.create + state/effect UI projection',
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
        subtitle: 'Optional Intent -> Store -> State workflow',
        page: const IntentStoreExample(),
      ),
      (
        title: 'History',
        subtitle: 'Opt-in undo/redo for immutable Store state',
        page: const HistoryExample(),
      ),
      (
        title: 'Streams',
        subtitle: 'Store-owned subscriptions with automatic disposal',
        page: const StreamStoreExample(),
      ),
      (
        title: 'Parameterized Store',
        subtitle: 'Popsicle.params with independent keyed state',
        page: const ParamsExample(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Popsicle examples'),

        actions: [
          PopsicleBuilder(
            builder: (context, scope, child) {
              final mode = scope.use(themeMode);
              return IconButton(
                tooltip: 'Toggle theme',
                onPressed: () {
                  scope.set(
                    themeMode,
                    mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
                icon: Icon(
                  mode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              );
            },
          ),
        ],
      ),
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
