import 'package:meta/meta.dart';

import '../engine/engine.dart';
import 'core_types.dart';

/// A non-state dependency managed by Popsicle's scoped graph.
///
/// Prefer `Popsicle.inject(...)` for declarations in application code.
final class Dependency<T> implements PopsicleSource<T> {
  Dependency(
    T Function(Scope scope) create, {
    String? name,
  }) : _delegate = Provider<T>(
          (engine) => create(scopeFromEngine(engine)),
          name: name,
        );

  final Provider<T> _delegate;

  @override
  @internal
  Object get engine => _delegate;

  /// Creates a parameterized non-state dependency.
  static const params = DependencyParamsBuilder();

  /// Overrides this dependency in a Popsicle scope/container.
  PopsicleOverride overrideWith(T Function(Scope scope) create) {
    return PopsicleOverride.engine(
      _delegate.overrideWith(
        (engine) => create(scopeFromEngine(engine)),
      ),
    );
  }
}

/// Builder used by [Dependency.params].
final class DependencyParamsBuilder {
  const DependencyParamsBuilder();

  DependencyParams<T, Arg> call<T, Arg>(
    T Function(Scope scope, Arg arg) create, {
    String? name,
  }) {
    return DependencyParams<T, Arg>._(
      ProviderFamily<T, Arg>(
        (engine, arg) => create(scopeFromEngine(engine), arg),
        name: name,
      ),
    );
  }
}

/// A callable parameterized dependency.
final class DependencyParams<T, Arg> {
  const DependencyParams._(this._delegate);

  final ProviderFamily<T, Arg> _delegate;

  DependencyHandle<T> call(Arg arg) {
    return DependencyHandle<T>._(_delegate(arg));
  }

  PopsicleOverride overrideWith(
    T Function(Scope scope, Arg arg) create,
  ) {
    return PopsicleOverride.engine(
      _delegate.overrideWith(
        (engine, arg) => create(scopeFromEngine(engine), arg),
      ),
    );
  }
}

/// Handle returned from a parameterized dependency.
final class DependencyHandle<T> implements PopsicleSource<T> {
  const DependencyHandle._(this._delegate);

  final Provider<T> _delegate;

  @override
  @internal
  Object get engine => _delegate;
}
