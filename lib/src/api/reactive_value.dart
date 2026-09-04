import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../engine/engine.dart';
import '../flutter_engine/consumer.dart';
import 'core_types.dart';

/// A lightweight scoped reactive value.
///
/// Prefer `Popsicle.value(initialValue)` for declarations.
final class ReactiveValue<T> implements PopsicleSource<T> {
  ReactiveValue(
    T initialValue, {
    String? name,
  }) : _delegate = StateProvider<T>(
          (_) => initialValue,
          name: name,
        );

  final StateProvider<T> _delegate;

  @override
  @internal
  Object get engine => _delegate;

  PopsicleOverride overrideWith(T value) {
    return PopsicleOverride.engine(
      _delegate.overrideWith((_) => value),
    );
  }
}

/// Builds UI whenever a [ReactiveValue] changes.
class ReactiveBuilder<T> extends ConsumerWidget {
  const ReactiveBuilder({
    super.key,
    required this.value,
    required this.builder,
  });

  final ReactiveValue<T> value;
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context, WidgetRef engine) {
    final current = engine.watch(engineSource(value));
    return builder(context, current);
  }
}

/// Compact `UI = f(state)` projection for a [ReactiveValue].
extension ReactiveValueUi<T> on ReactiveValue<T> {
  Widget ui(
    Widget Function(T value) builder, {
    Key? key,
  }) {
    return ReactiveBuilder<T>(
      key: key,
      value: this,
      builder: (_, value) => builder(value),
    );
  }
}

/// Mutation helpers for [ReactiveValue] on [Scope].
extension PopsicleScopeReactiveValueExtension on Scope {
  void set<T>(ReactiveValue<T> reactiveValue, T next) {
    final provider = reactiveValue.engine as StateProvider<T>;
    get(_ReactiveController<T>(provider)).state = next;
  }

  T update<T>(
    ReactiveValue<T> reactiveValue,
    T Function(T current) update,
  ) {
    final provider = reactiveValue.engine as StateProvider<T>;
    return get(_ReactiveController<T>(provider)).update(update);
  }
}

/// Dart-only mutation helpers for [ReactiveValue].
extension PopsicleContainerReactiveValueExtension on PopsicleContainer {
  void set<T>(ReactiveValue<T> reactiveValue, T next) {
    final provider = reactiveValue.engine as StateProvider<T>;
    get(_ReactiveController<T>(provider)).state = next;
  }

  T update<T>(
    ReactiveValue<T> reactiveValue,
    T Function(T current) update,
  ) {
    final provider = reactiveValue.engine as StateProvider<T>;
    return get(_ReactiveController<T>(provider)).update(update);
  }
}

final class _ReactiveController<T> implements PopsicleSource<StateController<T>> {
  const _ReactiveController(this.provider);

  final StateProvider<T> provider;

  @override
  Object get engine => provider.notifier;
}
