import 'dart:async';

import 'package:flutter/widgets.dart';

import '../engine/riverpod.dart';
import '../flutter_engine/consumer.dart';
import '../flutter_engine/framework.dart';
import 'core_types.dart';
import 'reactive_value.dart';
import 'store.dart';

/// Flutter-side reference used by Popsicle widgets.
typedef PopsicleRef = WidgetRef;

/// Root/scoped Flutter bridge for Popsicle's existing container engine.
class Popsicle extends StatelessWidget {
  const Popsicle({
    super.key,
    this.overrides = const [],
    this.observers,
    required this.child,
  });

  final List<PopsicleOverride> overrides;
  final List<PopsicleObserver>? observers;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      observers: observers,
      child: child,
    );
  }
}

/// Stateless Popsicle widget with reactive access through [PopsicleRef].
abstract class PopsicleWidget extends ConsumerWidget {
  const PopsicleWidget({super.key});

  @override
  Widget build(BuildContext context, PopsicleRef ref);
}

/// Stateful Popsicle widget.
abstract class PopsicleStatefulWidget extends ConsumerStatefulWidget {
  const PopsicleStatefulWidget({super.key});
}

/// State base class for [PopsicleStatefulWidget].
abstract class PopsicleState<T extends PopsicleStatefulWidget>
    extends ConsumerState<T> {}

/// Builder signature for [PopsicleBuilder].
typedef PopsicleBuilderCallback = Widget Function(
  BuildContext context,
  PopsicleRef ref,
  Widget? child,
);

/// Creates a small generic reactive rebuild boundary.
///
/// Use [PopsicleConsumer] when rendering a [Store] and handling its one-shot
/// effects together. [PopsicleBuilder] is intended for dependency-only or
/// mixed low-level reads where a Store-specific consumer is unnecessary.
class PopsicleBuilder extends ConsumerWidget {
  const PopsicleBuilder({
    super.key,
    required this.builder,
    this.child,
  });

  final PopsicleBuilderCallback builder;
  final Widget? child;

  @override
  Widget build(BuildContext context, PopsicleRef ref) {
    return builder(context, ref, child);
  }
}

/// Builds UI from a Store's current state.
typedef PopsicleStoreBuild<StoreT extends Store<State>, State> = Widget
    Function(
  BuildContext context,
  State state,
  StoreT store,
);

/// Handles one-shot Store effects.
///
/// Effects are delivered exactly when the Store emits them. They are not
/// reconstructed from state transitions and are never replayed on rebuild.
typedef PopsicleStoreEffect = void Function(
  BuildContext context,
  Object effect,
);

/// Store-focused UI boundary with separate state and side-effect channels.
///
/// The public model intentionally stays small:
///
/// - [provider] identifies the Store.
/// - [build] renders persistent Store state.
/// - [effect] handles optional one-shot Store effects.
///
/// ```dart
/// PopsicleConsumer(
///   provider: counterStore,
///   effect: (context, effect) {
///     if (effect is CounterReachedLimit) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Reached ${effect.count}')),
///       );
///     }
///   },
///   build: (context, state, store) {
///     return FilledButton(
///       onPressed: store.increment,
///       child: Text('$state'),
///     );
///   },
/// )
/// ```
class PopsicleConsumer<StoreT extends Store<State>, State>
    extends ConsumerStatefulWidget {
  const PopsicleConsumer({
    super.key,
    required this.provider,
    required this.build,
    this.effect,
  });

  /// Store definition consumed by this widget.
  final StoreHandle<StoreT, State> provider;

  /// Renders the latest persistent Store state.
  final PopsicleStoreBuild<StoreT, State> build;

  /// Handles one-shot effects emitted by the Store.
  final PopsicleStoreEffect? effect;

  @override
  ConsumerState<PopsicleConsumer<StoreT, State>> createState() =>
      _PopsicleConsumerState<StoreT, State>();
}

class _PopsicleConsumerState<StoreT extends Store<State>, State>
    extends ConsumerState<PopsicleConsumer<StoreT, State>> {
  ProviderSubscription<State>? _stateSubscription;
  StreamSubscription<Object>? _effectSubscription;
  late State _state;
  late StoreT _store;

  @override
  void initState() {
    super.initState();
    _bind(widget.provider);
  }

  @override
  void didUpdateWidget(covariant PopsicleConsumer<StoreT, State> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.provider != widget.provider) {
      _unbind();
      _bind(widget.provider);
      return;
    }

    final latestStore = ref.read(widget.provider.notifier);
    if (!identical(latestStore, _store)) {
      _store = latestStore;
      _bindEffects(latestStore);
    }
  }

  void _bind(StoreHandle<StoreT, State> provider) {
    _state = ref.read(provider);
    _store = ref.read(provider.notifier);
    _bindEffects(_store);

    _stateSubscription = ref.listenManual<State>(
      provider,
      (_, next) {
        if (!mounted) return;

        _state = next;

        final latestStore = ref.read(provider.notifier);
        if (!identical(latestStore, _store)) {
          _store = latestStore;
          _bindEffects(latestStore);
        }

        setState(() {});
      },
    );
  }

  void _bindEffects(StoreT store) {
    final previous = _effectSubscription;
    if (previous != null) {
      unawaited(previous.cancel());
    }
    _effectSubscription = store.listenEffects((value) {
      if (!mounted) return;
      widget.effect?.call(context, value);
    });
  }

  void _unbind() {
    _stateSubscription?.close();
    _stateSubscription = null;
    final effectSubscription = _effectSubscription;
    if (effectSubscription != null) {
      unawaited(effectSubscription.cancel());
    }
    _effectSubscription = null;
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, _state, _store);
  }
}

// consumer UI = F(STATE)

// Examaple: =======================
// provider.view(
//   effect: (context, effect) {
//     switch (effect) {
//       case UserProfileRefreshFailed(:final message):
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(message)),
//         );

//       case UserProfileLoaded():
//         break;
//     }
//   },
//   build: (context, state, store) {
//     return RefreshIndicator(
//       onRefresh: store.refresh,
//       child: ...
//     );
//   },
// );

extension StoreProviderView<StoreType extends Store<State>, State>
    on StoreProvider<StoreType, State> {
  Widget view(
    Widget Function(
      BuildContext context,
      State state,
      StoreType store,
    ) build, {
    void Function(
      BuildContext context,
      Object effect,
    )? effect,
    Key? key,
  }) {
    return PopsicleConsumer<StoreType, State>(
      key: key,
      provider: this,
      effect: effect,
      build: build,
    );
  }
}

/// OR,
///
// provider.view(
//   build: (context, state, store) {
//     return Text(state.toString());
//   },
// );

/// Store-specific conveniences on Flutter's Popsicle reference.
extension PopsicleWidgetRefStoreExtension on WidgetRef {
  /// Reads the Store instance for invoking actions without rebuilding.
  StoreT store<StoreT extends Store<State>, State>(
    StoreHandle<StoreT, State> provider,
  ) {
    return read(provider.notifier);
  }

  /// Watches only a projection of a Store's state.
  Selected selectStore<StoreT extends Store<State>, State, Selected>(
    StoreHandle<StoreT, State> provider,
    Selected Function(State state) selector,
  ) {
    return watch(provider.select(selector));
  }

  /// Low-level Store state listener.
  ///
  /// Prefer [PopsicleConsumer] for UI side effects. Store effects use a
  /// dedicated one-shot channel and are not derived from this listener.
  void listenStore<StoreT extends Store<State>, State>(
    StoreHandle<StoreT, State> provider,
    void Function(State? previous, State next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    listen(provider, listener, onError: onError);
  }
}

/// Mutation helpers for [ReactiveValue] in Flutter widgets.
extension PopsicleWidgetRefReactiveValueExtension on WidgetRef {
  /// Replaces the current reactive value.
  void set<T>(ReactiveValue<T> reactiveValue, T next) {
    read(reactiveValue.notifier).state = next;
  }

  /// Updates the current reactive value and returns the result.
  T update<T>(
    ReactiveValue<T> reactiveValue,
    T Function(T current) update,
  ) {
    return read(reactiveValue.notifier).update(update);
  }
}
