import '../engine/riverpod.dart';
import 'core_types.dart';

/// A non-state dependency managed by Popsicle's container graph.
///
/// This is intentionally backed by Riverpod 2.6.1's proven Provider engine in
/// the first Popsicle iteration. The public naming separates dependencies from
/// reactive [Store] state.
class Dependency<T> extends Provider<T> {
  Dependency(
    T Function(PopRef<T> ref) create, {
    super.name,
    super.dependencies,
  }) : super(
          (ref) => create(ref),
        );

  /// Creates a parameterized dependency while keeping Riverpod's family
  /// identity/caching semantics internally.
  static const params = DependencyParamsBuilder();
}

/// Builder used by [Dependency.params].
final class DependencyParamsBuilder {
  const DependencyParamsBuilder();

  DependencyParams<T, Arg> call<T, Arg>(
    T Function(PopRef<T> ref, Arg arg) create, {
    String? name,
    Iterable<PopsicleNode>? dependencies,
  }) {
    return DependencyParams<T, Arg>._(
      ProviderFamily<T, Arg>(
        (ref, arg) => create(ref, arg),
        name: name,
        dependencies: dependencies,
      ),
    );
  }
}

/// A callable parameterized dependency.
///
/// The `family` terminology remains an implementation detail in this release.
final class DependencyParams<T, Arg> {
  const DependencyParams._(this._delegate);

  final ProviderFamily<T, Arg> _delegate;

  DependencyHandle<T> call(Arg arg) => _delegate(arg);

  /// Advanced graph node for declaring scoped dependency relationships.
  PopsicleNode get node => _delegate;

  PopsicleOverride overrideWith(
    T Function(PopRef<T> ref, Arg arg) create,
  ) {
    return _delegate.overrideWith((ref, arg) => create(ref, arg));
  }
}

/// Public handle returned from a parameterized dependency.
typedef DependencyHandle<T> = Provider<T>;
