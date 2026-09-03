import 'package:flutter/widgets.dart';

import '../engine/riverpod.dart';
import '../flutter_engine/consumer.dart';
import 'core_types.dart';

/// A lightweight scoped reactive value.
///
/// Use [ReactiveValue] for simple mutable state that does not justify creating
/// a full Store.
///
/// The value is owned by Popsicle's container graph, so the same declaration
/// can hold independent state in different [PopsicleContainer]s.
///
/// ```dart
/// final counter = ReactiveValue(0);
///
/// final count = ref.watch(counter);
/// ref.update(counter, (value) => value + 1);
/// ```
///
/// For lightweight UI rendering:
///
/// ```dart
/// counter.view(
///   (count) => Text('$count'),
/// );
/// ```
class ReactiveValue<T> extends StateProvider<T> {
  ReactiveValue(
    T initialValue, {
    String? name,
  }) : super(
          (_) => initialValue,
          name: name,
        );
}

/// Builds UI whenever a [ReactiveValue] changes.
///
/// Unlike [PopsicleWidget], this can be used inside any normal Flutter widget
/// as long as it is below a Popsicle scope.
///
/// ```dart
/// ReactiveBuilder(
///   value: counter,
///   builder: (context, count) {
///     return Text('$count');
///   },
/// );
/// ```
class ReactiveBuilder<T> extends ConsumerWidget {
  const ReactiveBuilder({
    super.key,
    required this.value,
    required this.builder,
  });

  final ReactiveValue<T> value;

  final Widget Function(
    BuildContext context,
    T value,
  ) builder;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final current = ref.watch(value);

    return builder(context, current);
  }
}

/// Convenient UI projection for a [ReactiveValue].
///
/// This follows Popsicle's:
///
/// ```text
/// UI = f(state)
/// ```
///
/// Example:
///
/// ```dart
/// counter.view(
///   (count) => Text('$count'),
/// );
/// ```
extension ReactiveValueView<T> on ReactiveValue<T> {
  Widget view(
    Widget Function(T value) builder,
  ) {
    return ReactiveBuilder<T>(
      value: this,
      builder: (_, value) => builder(value),
    );
  }
}

/// Mutation helpers for [ReactiveValue] inside Popsicle factories/widgets.
extension PopsicleRefReactiveValueExtension<State> on Ref<State> {
  /// Replaces the current value.
  void set<T>(
    ReactiveValue<T> reactiveValue,
    T next,
  ) {
    read(reactiveValue.notifier).state = next;
  }

  /// Updates the current value from its previous value and returns the result.
  T update<T>(
    ReactiveValue<T> reactiveValue,
    T Function(T current) update,
  ) {
    return read(
      reactiveValue.notifier,
    ).update(update);
  }
}

/// Dart-only mutation helpers for [ReactiveValue].
extension PopsicleContainerReactiveValueExtension on PopsicleContainer {
  /// Replaces the current value in this container.
  void set<T>(
    ReactiveValue<T> reactiveValue,
    T next,
  ) {
    read(reactiveValue.notifier).state = next;
  }

  /// Updates the current value in this container and returns the result.
  T update<T>(
    ReactiveValue<T> reactiveValue,
    T Function(T current) update,
  ) {
    return read(
      reactiveValue.notifier,
    ).update(update);
  }
}
