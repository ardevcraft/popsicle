import 'package:meta/meta.dart';

import '../engine/engine.dart';

/// A readable declaration in Popsicle's scoped graph.
///
/// Application code normally works with concrete declarations returned by
/// `Popsicle.inject`, `Popsicle.value`, `Popsicle.create`, or
/// `Popsicle.params` instead of naming this interface directly.
abstract interface class PopsicleSource<T> {
  /// Internal engine handle.
  @internal
  Object get engine;
}

@internal
ProviderListenable<T> engineSource<T>(PopsicleSource<T> source) {
  return source.engine as ProviderListenable<T>;
}

/// A scoped override used by [Popsicle] and [PopsicleContainer].
final class PopsicleOverride {
  @internal
  const PopsicleOverride.engine(this.engine);

  @internal
  final Object engine;
}

@internal
Override engineOverride(PopsicleOverride override) {
  return override.engine as Override;
}

/// Subscription returned by [PopsicleContainer.subscribe].
final class PopsicleSubscription<T> {
  @internal
  PopsicleSubscription.engine(Object engine)
      : _delegate = engine as ProviderSubscription<T>;

  final ProviderSubscription<T> _delegate;

  bool get closed => _delegate.closed;

  T get current => _delegate.read();

  void close() => _delegate.close();
}

/// Scoped dependency context used while creating dependencies and Stores.
///
/// [get] accesses a value without creating a reactive dependency.
/// [use] accesses a value and makes the current computation depend on it.
final class Scope {
  @internal
  Scope({
    required T Function<T>(PopsicleSource<T> source) get,
    required T Function<T>(PopsicleSource<T> source) use,
  })  : _get = get,
        _use = use;

  final T Function<T>(PopsicleSource<T> source) _get;
  final T Function<T>(PopsicleSource<T> source) _use;

  /// Accesses [source] without subscribing the current computation to changes.
  T get<T>(PopsicleSource<T> source) => _get<T>(source);

  /// Accesses [source] and subscribes the current computation to changes.
  T use<T>(PopsicleSource<T> source) => _use<T>(source);
}

@internal
Scope scopeFromEngine(Ref engine) {
  return Scope(
    get: <T>(source) => engine.read(engineSource(source)),
    use: <T>(source) => engine.watch(engineSource(source)),
  );
}

/// Dart-only Popsicle container.
///
/// The container owns an isolated scoped graph. The same declarations can hold
/// independent values in separate containers, which makes testing and
/// environment overrides straightforward.
final class PopsicleContainer {
  PopsicleContainer({
    PopsicleContainer? parent,
    List<PopsicleOverride> overrides = const [],
  }) : _delegate = ProviderContainer(
          parent: parent?._delegate,
          overrides: overrides.map(engineOverride).toList(growable: false),
        );

  final ProviderContainer _delegate;

  /// Accesses a dependency, reactive value, or Store state without subscribing.
  T get<T>(PopsicleSource<T> source) {
    return _delegate.read(engineSource(source));
  }

  /// Subscribes to [source] changes outside Flutter widgets.
  PopsicleSubscription<T> subscribe<T>(
    PopsicleSource<T> source,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    final subscription = _delegate.listen<T>(
      engineSource(source),
      listener,
      onError: onError,
      fireImmediately: fireImmediately,
    );

    return PopsicleSubscription<T>.engine(subscription);
  }

  /// Disposes all instances owned by this container.
  void dispose() => _delegate.dispose();
}
