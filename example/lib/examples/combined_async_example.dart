import 'package:flutter/material.dart';
import 'package:popsicle/popsicle.dart';

class DashboardState {
  const DashboardState({
    this.profile = const AsyncState.idle(),
    this.metrics = const AsyncState.idle(),
  });

  final AsyncState<String> profile;
  final AsyncState<int> metrics;

  AsyncState<(String, int)> get content => Async.combine2(profile, metrics);

  DashboardState withProfile(AsyncState<String> value) {
    return DashboardState(profile: value, metrics: metrics);
  }

  DashboardState withMetrics(AsyncState<int> value) {
    return DashboardState(profile: profile, metrics: value);
  }
}

final class DashboardReady {
  const DashboardReady();
}

final class DashboardLoadFailed {
  const DashboardLoadFailed(this.error);

  final Object error;
}

class DashboardStore extends Store<DashboardState> {
  DashboardStore() : super(const DashboardState());

  Future<void> load() async {
    await Future.wait<void>([
      _loadProfile(),
      _loadMetrics(),
    ]);

    final content = state.content;
    if (content.hasValue && !content.hasError) {
      effect(const DashboardReady());
    }
  }

  Future<void> _loadProfile() async {
    final previous = state.profile;
    commit(state.withProfile(AsyncState.loading(previous: previous)));

    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      commit(state.withProfile(const AsyncState.data('AR Rahman')));
    } catch (error, stackTrace) {
      commit(
        state.withProfile(
          AsyncState.error(error, stackTrace, previous: previous),
        ),
      );
      effect(DashboardLoadFailed(error));
    }
  }

  Future<void> _loadMetrics() async {
    final previous = state.metrics;
    commit(state.withMetrics(AsyncState.loading(previous: previous)));

    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      commit(state.withMetrics(const AsyncState.data(42)));
    } catch (error, stackTrace) {
      commit(
        state.withMetrics(
          AsyncState.error(error, stackTrace, previous: previous),
        ),
      );
      effect(DashboardLoadFailed(error));
    }
  }
}

final dashboardStore = Popsicle.create(
  (_) => DashboardStore(),
);

class CombinedAsyncExample extends StatelessWidget {
  const CombinedAsyncExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Combined async sources')),
      body: Center(
        child: dashboardStore.ui(
          (context, state, store) {
            final content = state.content;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  content.when(
                    idle: () => const Text('Load the dashboard sources.'),
                    loading: () => const CircularProgressIndicator(),
                    data: (value, refreshing) {
                      final (name, score) = value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text('Metric score: $score'),
                          if (refreshing) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                          ],
                        ],
                      );
                    },
                    error: (error, stackTrace, previousValue) => Text(
                      'Could not combine sources: $error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: content.isLoading ? null : store.load,
                    child:
                        Text(content.hasValue ? 'Refresh both' : 'Load both'),
                  ),
                ],
              ),
            );
          },
          effect: (context, effect) {
            if (effect is DashboardReady) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Both async sources are ready')),
              );
            } else if (effect is DashboardLoadFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dashboard failed: ${effect.error}')),
              );
            }
          },
        ),
      ),
    );
  }
}
