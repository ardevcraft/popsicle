import 'dart:async';

import 'package:meta/meta.dart';

import '../engine/riverpod.dart';
import 'core_types.dart';

/// Base class for reactive Popsicle state.
///
/// A Store owns one immutable state value and exposes ordinary methods/actions
/// that update it. Async work does not require a different Store type.
///
/// Stores also expose a dedicated one-shot effect channel. Use [effect] for
/// transient UI work such as snackbars, navigation, dialogs, or launching URLs.
/// Effects are not retained, replayed, or used to rebuild widgets.
abstract class Store<State> extends StateNotifier<State> {
  Store(super.initialState);

  final StreamController<Object> _effects =
      StreamController<Object>.broadcast(sync: true);

  /// Current immutable state exposed by this Store.
  @override
  State get state => super.state;

  /// Emits the next persistent state and notifies state listeners.
  @protected
  void emit(State next) {
    super.state = next;
  }

  /// Emits a one-shot side effect.
  ///
  /// Effects are delivered only to listeners that are active at emission time.
  /// They are never cached or replayed to future listeners.
  @protected
  void effect(Object value) {
    if (!_effects.isClosed) {
      _effects.add(value);
    }
  }

  /// Low-level subscription to one-shot Store effects.
  ///
  /// Flutter UI should normally use `PopsicleConsumer` instead of subscribing
  /// directly. This method is public so non-widget orchestration and tests can
  /// observe effects without depending on Flutter.
  StreamSubscription<Object> listenEffects(
    void Function(Object effect) listener, {
    Function? onError,
  }) {
    return _effects.stream.listen(listener, onError: onError);
  }

  /// Alias for [state].
  State get value => state;

  @override
  void dispose() {
    unawaited(_effects.close());
    super.dispose();
  }
}

/// Optional action-driven Store for workflows that benefit from an explicit
/// `Action -> Store -> State` flow.
///
/// Simple Stores should continue exposing ordinary methods; actions are not
/// required for basic state management.
abstract class IntentStore<State, Action> extends Store<State> {
  IntentStore(super.initialState);

  FutureOr<void> dispatch(Action action) => onIntent(action);

  @protected
  FutureOr<void> onIntent(Action action);
}

/// Provides a [Store] to Popsicle's dependency graph.
///
/// Watching this provider returns the Store's current state. Use `ref.store(...)`
/// to obtain the Store instance and invoke its actions.
class StoreProvider<StoreT extends Store<State>, State>
    extends StateNotifierProvider<StoreT, State> {
  StoreProvider(
    StoreT Function(PopRef<State> ref) create, {
    super.name,
    super.dependencies,
  }) : super(
          (ref) => create(ref),
        );

  /// Parameterized Store creation using Riverpod's mature family machinery
  /// internally, exposed as the clearer `.params` API.
  static const params = StoreParamsBuilder();

  /// Alias for the underlying notifier handle.
  StoreAccessor<StoreT> get store => notifier;
}

/// Builder used by [StoreProvider.params].
final class StoreParamsBuilder {
  const StoreParamsBuilder();

  StoreParams<StoreT, State, Arg> call<StoreT extends Store<State>, State, Arg>(
    StoreT Function(PopRef<State> ref, Arg arg) create, {
    String? name,
    Iterable<PopsicleNode>? dependencies,
  }) {
    return StoreParams<StoreT, State, Arg>._(
      StateNotifierProviderFamily<StoreT, State, Arg>(
        (ref, arg) => create(ref, arg),
        name: name,
        dependencies: dependencies,
      ),
    );
  }
}

/// Callable parameterized Store definition.
final class StoreParams<StoreT extends Store<State>, State, Arg> {
  const StoreParams._(this._delegate);

  final StateNotifierProviderFamily<StoreT, State, Arg> _delegate;

  StoreHandle<StoreT, State> call(Arg arg) => _delegate(arg);

  /// Advanced graph node for declaring scoped dependency relationships.
  PopsicleNode get node => _delegate;

  PopsicleOverride overrideWith(
    StoreT Function(PopRef<State> ref, Arg arg) create,
  ) {
    return _delegate.overrideWith((ref, arg) => create(ref, arg));
  }
}

/// Public handle returned from a parameterized Store.
typedef StoreHandle<StoreT extends StateNotifier<State>, State>
    = StateNotifierProvider<StoreT, State>;

/// Read-only provider handle for obtaining the Store instance.
typedef StoreAccessor<StoreT> = AlwaysAliveRefreshable<StoreT>;

/// Popsicle conveniences for interacting with a Store provider from a Ref.
extension PopsicleStoreRefExtension on Ref {
  /// Reads the Store instance without subscribing to state changes.
  StoreT store<StoreT extends Store<State>, State>(
    StoreHandle<StoreT, State> provider,
  ) {
    return read(provider.notifier);
  }

  /// Watches only a selected projection of Store state.
  Selected selectStore<StoreT extends Store<State>, State, Selected>(
    StoreHandle<StoreT, State> provider,
    Selected Function(State state) selector,
  ) {
    return watch(provider.select(selector));
  }
}
