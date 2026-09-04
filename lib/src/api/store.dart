import 'dart:async';

import 'package:meta/meta.dart';

import '../engine/engine.dart';
import 'core_types.dart';

/// Base class for structured reactive Popsicle state.
abstract class Store<State> extends StateNotifier<State> {
  Store(super.initialState);

  final StreamController<Object> _effects =
      StreamController<Object>.broadcast(sync: true);
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  @override
  State get state => super.state;

  /// Commits the next persistent state.
  @protected
  void commit(State next) {
    super.state = next;
  }

  /// Sends a one-shot side effect.
  @protected
  void effect(Object value) {
    if (!_effects.isClosed) {
      _effects.add(value);
    }
  }

  /// Subscribes this Store to an external stream.
  ///
  /// The subscription is owned by the Store and is cancelled automatically
  /// when the Store is disposed. The returned subscription can still be used
  /// for explicit pause, resume, or early cancellation when needed.
  @protected
  StreamSubscription<T> listenTo<T>(
    Stream<T> stream, {
    required void Function(T value) onData,
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onDone,
    bool cancelOnError = false,
  }) {
    final subscription = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    _subscriptions.add(subscription);
    return subscription;
  }

  /// Low-level subscription to one-shot Store effects.
  StreamSubscription<Object> listenEffects(
    void Function(Object effect) listener, {
    Function? onError,
  }) {
    return _effects.stream.listen(listener, onError: onError);
  }

  State get value => state;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();

    unawaited(_effects.close());
    super.dispose();
  }
}

/// Optional intent-driven Store for explicit `Intent -> Store -> State` flows.
abstract class IntentStore<State, Intent> extends Store<State> {
  IntentStore(super.initialState);

  FutureOr<void> dispatch(Intent intent) => onIntent(intent);

  @protected
  FutureOr<void> onIntent(Intent intent);
}

/// Popsicle-owned handle for one scoped Store declaration.
///
/// Prefer `Popsicle.create(...)` rather than constructing this directly.
class StoreHandle<StoreT extends Store<State>, State>
    implements PopsicleSource<State> {
  @internal
  const StoreHandle.engine(this._delegate);

  final StateNotifierProvider<StoreT, State> _delegate;

  @override
  @internal
  Object get engine => _delegate;

  /// Overrides Store construction in a Popsicle scope/container.
  PopsicleOverride overrideWith(StoreT Function(Scope scope) create) {
    return PopsicleOverride.engine(
      _delegate.overrideWith(
        (engine) => create(scopeFromEngine(engine)),
      ),
    );
  }
}

@internal
StateNotifierProvider<StoreT, State>
    engineStore<StoreT extends Store<State>, State>(
  StoreHandle<StoreT, State> source,
) {
  return source._delegate;
}

/// Advanced compatibility declaration type.
///
/// New code should prefer `Popsicle.create(...)`.
final class StoreProvider<StoreT extends Store<State>, State>
    extends StoreHandle<StoreT, State> {
  StoreProvider(
    StoreT Function(Scope scope) create, {
    String? name,
  }) : super.engine(
          StateNotifierProvider<StoreT, State>(
            (engine) => create(scopeFromEngine(engine)),
            name: name,
          ),
        );

  static const params = StoreParamsBuilder();
}

/// Builder used by `Popsicle.params` and the advanced `StoreProvider.params`.
final class StoreParamsBuilder {
  const StoreParamsBuilder();

  StoreParams<StoreT, State, Arg> call<StoreT extends Store<State>, State, Arg>(
    StoreT Function(Scope scope, Arg arg) create, {
    String? name,
  }) {
    return StoreParams<StoreT, State, Arg>._(
      StateNotifierProviderFamily<StoreT, State, Arg>(
        (engine, arg) => create(scopeFromEngine(engine), arg),
        name: name,
      ),
    );
  }
}

/// Callable parameterized Store declaration returned by `Popsicle.params`.
final class StoreParams<StoreT extends Store<State>, State, Arg> {
  const StoreParams._(this._delegate);

  final StateNotifierProviderFamily<StoreT, State, Arg> _delegate;

  StoreHandle<StoreT, State> call(Arg arg) {
    return StoreHandle<StoreT, State>.engine(_delegate(arg));
  }

  PopsicleOverride overrideWith(
    StoreT Function(Scope scope, Arg arg) create,
  ) {
    return PopsicleOverride.engine(
      _delegate.overrideWith(
        (engine, arg) => create(scopeFromEngine(engine), arg),
      ),
    );
  }
}

/// Store conveniences on [Scope].
extension PopsicleScopeStoreExtension on Scope {
  /// Returns the Store instance without subscribing to state changes.
  StoreT store<StoreT extends Store<State>, State>(
    StoreHandle<StoreT, State> source,
  ) {
    return get(_StoreAccessor<StoreT, State>(source));
  }

  /// Observes only a selected projection of Store state.
  Selected select<StoreT extends Store<State>, State, Selected>(
    StoreHandle<StoreT, State> source,
    Selected Function(State state) selector,
  ) {
    return use(_StoreSelection<StoreT, State, Selected>(source, selector));
  }
}

/// Store conveniences for Dart-only [PopsicleContainer] usage.
extension PopsicleContainerStoreExtension on PopsicleContainer {
  StoreT store<StoreT extends Store<State>, State>(
    StoreHandle<StoreT, State> source,
  ) {
    return get(_StoreAccessor<StoreT, State>(source));
  }
}

final class _StoreAccessor<StoreT extends Store<State>, State>
    implements PopsicleSource<StoreT> {
  const _StoreAccessor(this.source);

  final StoreHandle<StoreT, State> source;

  @override
  Object get engine => engineStore(source).notifier;
}

final class _StoreSelection<StoreT extends Store<State>, State, Selected>
    implements PopsicleSource<Selected> {
  _StoreSelection(this.source, this.selector);

  final StoreHandle<StoreT, State> source;
  final Selected Function(State state) selector;

  @override
  Object get engine => engineStore(source).select(selector);
}
