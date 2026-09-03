import '../engine/riverpod.dart';

/// Resolver available while creating dependencies/stores.
typedef PopRef<T> = Ref<T>;

/// Advanced node type used only when declaring scoped dependency relationships.
typedef PopsicleNode = ProviderOrFamily;

/// A container-level override.
typedef PopsicleOverride = Override;

/// Observer for graph/provider lifecycle events in the compatibility engine.
typedef PopsicleObserver = ProviderObserver;

/// Subscription returned by manual container listeners.
typedef PopsicleSubscription<T> = ProviderSubscription<T>;

/// Dart-only Popsicle container.
///
/// This intentionally delegates to the Riverpod 2.6.1 container implementation
/// in the first Popsicle iteration.
class PopsicleContainer extends ProviderContainer {
  PopsicleContainer({
    PopsicleContainer? super.parent,
    super.overrides,
    super.observers,
  });
}
