import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

final appName = Dependency<String>((_) => 'Popsicle');
final welcomeMessage = Dependency<String>(
  (ref) => 'Hello from ${ref.read(appName)} dependency injection.',
);

class DependencyExample extends StatelessWidget {
  const DependencyExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dependency')),
      body: Center(
        child: PopsicleBuilder(
          builder: (context, ref, child) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                ref.watch(welcomeMessage),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          },
        ),
      ),
    );
  }
}
