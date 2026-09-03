import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

class ApiConfig {
  const ApiConfig(this.baseUrl);

  final String baseUrl;
}

class ApiService {
  const ApiService(this.config);

  final ApiConfig config;

  String get message => 'Connected to ${config.baseUrl}';
}

final apiConfig = Popsicle.inject(
  (_) => const ApiConfig('https://api.example.com'),
);

final apiService = Popsicle.inject(
  (scope) => ApiService(scope.get(apiConfig)),
);

class DependencyExample extends StatelessWidget {
  const DependencyExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popsicle.inject')),
      body: Center(
        child: PopsicleBuilder(
          builder: (context, scope, child) {
            final service = scope.use(apiService);

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                service.message,
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
