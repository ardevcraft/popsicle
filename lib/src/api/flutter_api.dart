import 'dart:async';

import 'package:flutter/widgets.dart';

import '../engine/engine.dart';
import '../flutter_engine/consumer.dart';
import '../flutter_engine/framework.dart';
import 'core_types.dart';
import 'dependency.dart';
import 'reactive_value.dart';
import 'store.dart';

Scope _scopeFromEngine(WidgetRef engine) {
  return Scope(
    get: <T>(source) => engine.read(engineSource(source)),
    use: <T>(source) => engine.watch(engineSource(source)),
  );
}

/// Root Flutter scope and declaration namespace for Popsicle.
class Popsicle extends StatelessWidget {
  const Popsicle({
    super.key,
    this.overrides = const [],
    required this.child,
  });

  final List<PopsicleOverride> overrides;
  final Widget child;

  /// Declares a non-state dependency.
  static Dependency<T> inject<T>(
    T Function(Scope scope) create, {
    String? name,
  }) {
    return Dependency<T>(create, name: name);
  }

  /// Declares a small scoped reactive value.
  static ReactiveValue<T> value<T>(
    T initialValue, {
    String? name,
  }) {
    return ReactiveValue<T>(initialValue, name: name);
  }

  /// Declares a structured reactive Store.
  static StoreHandle<StoreT, State>
      create<StoreT extends Store<State>, State>(
    StoreT Function(Scope scope) create, {
    String? name,
  }) {
    return StoreProvider<StoreT, State>(create, name: name);
  }

  /// Declares parameterized Store state.
  static StoreParams<StoreT, State, Arg>
      params<StoreT extends Store<State>, State, Arg>(
    StoreT Function(Scope scope, Arg arg) create, {
    String? name,
  }) {
    return StoreProvider.params<StoreT, State, Arg>(create, name: name);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides.map(engineOverride).toList(growable: false),
      child: child,
    );
  }
}

/// Stateless-style Popsicle widget with scoped `get/use` access.
abstract class PopsicleWidget extends ConsumerStatefulWidget {
  const PopsicleWidget({super.key});

  Widget build(BuildContext context, Scope scope);

  @override
  ConsumerState<PopsicleWidget> createState() => _PopsicleWidgetState();
}

final class _PopsicleWidgetState extends ConsumerState<PopsicleWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.build(context, _scopeFromEngine(ref));
  }
}

/// Builder signature for [PopsicleBuilder].
typedef PopsicleBuilderCallback = Widget Function(
  BuildContext context,
  Scope scope,
  Widget? child,
);

/// Small generic reactive rebuild boundary.
class PopsicleBuilder extends ConsumerWidget {
  const PopsicleBuilder({
    super.key,
    required this.builder,
    this.child,
  });

  final PopsicleBuilderCallback builder;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef engine) {
    return builder(context, _scopeFromEngine(engine), child);
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
typedef PopsicleStoreEffect = void Function(
  BuildContext context,
  Object effect,
);

/// Explicit Store widget used underneath the `.view()` API.
class PopsicleConsumer<StoreT extends Store<State>, State>
    extends ConsumerStatefulWidget {
  const PopsicleConsumer({
    super.key,
    required this.source,
    required this.build,
    this.effect,
  });

  final StoreHandle<StoreT, State> source;
  final PopsicleStoreBuild<StoreT, State> build;
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
    _bind(widget.source);
  }

  @override
  void didUpdateWidget(covariant PopsicleConsumer<StoreT, State> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.source != widget.source) {
      _unbind();
      _bind(widget.source);
      return;
    }

    final engine = ref;
    final provider = engineStore(widget.source);
    final latestStore = engine.read(provider.notifier);
    if (!identical(latestStore, _store)) {
      _store = latestStore;
      _bindEffects(latestStore);
    }
  }

  void _bind(StoreHandle<StoreT, State> source) {
    final engine = ref;
    final provider = engineStore(source);

    _state = engine.read(provider);
    _store = engine.read(provider.notifier);
    _bindEffects(_store);

    _stateSubscription = engine.listenManual<State>(
      provider,
      (_, next) {
        if (!mounted) return;

        _state = next;

        final latestStore = engine.read(provider.notifier);
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

/// Compact `UI = f(state)` projection for direct and parameterized Stores.
extension PopsicleStoreView<StoreT extends Store<State>, State>
    on StoreHandle<StoreT, State> {
  Widget view(
    Widget Function(
      BuildContext context,
      State state,
      StoreT store,
    ) build, {
    void Function(BuildContext context, Object effect)? effect,
    Key? key,
  }) {
    return PopsicleConsumer<StoreT, State>(
      key: key,
      source: this,
      effect: effect,
      build: build,
    );
  }
}
