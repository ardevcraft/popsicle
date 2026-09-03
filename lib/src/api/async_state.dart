/// Immutable async operation state that can preserve stale data while loading
/// or after a refresh error.
///
/// Unlike a provider-level async abstraction, [AsyncState] is a normal value.
/// A single Store can therefore own multiple independent async sources.
final class AsyncState<T> {
  const AsyncState._({
    required bool hasValue,
    required T? value,
    required this.isLoading,
    required this.isIdle,
    this.error,
    this.stackTrace,
  })  : _hasValue = hasValue,
        _value = value;

  const AsyncState.idle()
      : this._(
          hasValue: false,
          value: null,
          isLoading: false,
          isIdle: true,
        );

  const AsyncState.data(T value)
      : this._(
          hasValue: true,
          value: value,
          isLoading: false,
          isIdle: false,
        );

  /// Creates a loading state. Passing [previous] preserves its value, making
  /// this a refresh rather than an initial load.
  factory AsyncState.loading({AsyncState<T>? previous}) {
    return AsyncState<T>._(
      hasValue: previous?.hasValue ?? false,
      value: previous?.valueOrNull,
      isLoading: true,
      isIdle: false,
    );
  }

  /// Creates an error state. Passing [previous] preserves stale data so the UI
  /// may continue rendering useful content after a failed refresh.
  factory AsyncState.error(
    Object error,
    StackTrace stackTrace, {
    AsyncState<T>? previous,
  }) {
    return AsyncState<T>._(
      hasValue: previous?.hasValue ?? false,
      value: previous?.valueOrNull,
      isLoading: false,
      isIdle: false,
      error: error,
      stackTrace: stackTrace,
    );
  }

  final bool _hasValue;
  final T? _value;

  /// Whether an async operation is currently running.
  final bool isLoading;

  /// Whether no operation has started yet.
  final bool isIdle;

  /// Latest error, including a refresh error when stale data is preserved.
  final Object? error;

  /// Stack trace associated with [error].
  final StackTrace? stackTrace;

  bool get hasValue => _hasValue;
  bool get hasError => error != null;

  /// Initial loading without renderable data.
  bool get isInitialLoading => isLoading && !hasValue;

  /// Background/refresh loading while old data remains renderable.
  bool get isRefreshing => isLoading && hasValue;

  T? get valueOrNull => _hasValue ? _value : null;

  T get requireValue {
    if (!_hasValue) {
      throw StateError('AsyncState has no value.');
    }
    return _value as T;
  }

  /// Transforms only the value while preserving loading/error metadata.
  AsyncState<R> map<R>(R Function(T value) transform) {
    if (!hasValue) {
      return AsyncState<R>._(
        hasValue: false,
        value: null,
        isLoading: isLoading,
        isIdle: isIdle,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return AsyncState<R>._(
      hasValue: true,
      value: transform(requireValue),
      isLoading: isLoading,
      isIdle: isIdle,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Combines this state with another required async source.
  AsyncState<(T, B)> zip<B>(AsyncState<B> other) {
    return Async.combine2(this, other);
  }

  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T value, bool refreshing) data,
    required R Function(
      Object error,
      StackTrace? stackTrace,
      T? previousValue,
    ) error,
  }) {
    if (hasValue) {
      if (hasError) {
        return error(this.error!, stackTrace, valueOrNull);
      }
      return data(requireValue, isRefreshing);
    }
    if (hasError) {
      return error(this.error!, stackTrace, null);
    }
    if (isLoading) {
      return loading();
    }
    return idle();
  }

  @override
  String toString() {
    return 'AsyncState<$T>('
        'hasValue: $hasValue, '
        'isLoading: $isLoading, '
        'isIdle: $isIdle, '
        'error: $error, '
        'value: $valueOrNull)';
  }
}

/// Composition helpers for required async sources.
abstract final class Async {
  static AsyncState<(A, B)> combine2<A, B>(
    AsyncState<A> a,
    AsyncState<B> b,
  ) {
    final allHaveValue = a.hasValue && b.hasValue;
    final loading = a.isLoading || b.isLoading;
    final firstError = _firstError([a, b]);

    if (allHaveValue) {
      return AsyncState<(A, B)>._(
        hasValue: true,
        value: (a.requireValue, b.requireValue),
        isLoading: loading,
        isIdle: false,
        error: firstError?.$1,
        stackTrace: firstError?.$2,
      );
    }

    return _withoutCompleteValue<(A, B)>(
      states: [a, b],
      loading: loading,
      firstError: firstError,
    );
  }

  static AsyncState<(A, B, C)> combine3<A, B, C>(
    AsyncState<A> a,
    AsyncState<B> b,
    AsyncState<C> c,
  ) {
    final allHaveValue = a.hasValue && b.hasValue && c.hasValue;
    final loading = a.isLoading || b.isLoading || c.isLoading;
    final firstError = _firstError([a, b, c]);

    if (allHaveValue) {
      return AsyncState<(A, B, C)>._(
        hasValue: true,
        value: (a.requireValue, b.requireValue, c.requireValue),
        isLoading: loading,
        isIdle: false,
        error: firstError?.$1,
        stackTrace: firstError?.$2,
      );
    }

    return _withoutCompleteValue<(A, B, C)>(
      states: [a, b, c],
      loading: loading,
      firstError: firstError,
    );
  }

  static AsyncState<(A, B, C, D)> combine4<A, B, C, D>(
    AsyncState<A> a,
    AsyncState<B> b,
    AsyncState<C> c,
    AsyncState<D> d,
  ) {
    final allHaveValue =
        a.hasValue && b.hasValue && c.hasValue && d.hasValue;
    final loading = a.isLoading || b.isLoading || c.isLoading || d.isLoading;
    final firstError = _firstError([a, b, c, d]);

    if (allHaveValue) {
      return AsyncState<(A, B, C, D)>._(
        hasValue: true,
        value: (
          a.requireValue,
          b.requireValue,
          c.requireValue,
          d.requireValue,
        ),
        isLoading: loading,
        isIdle: false,
        error: firstError?.$1,
        stackTrace: firstError?.$2,
      );
    }

    return _withoutCompleteValue<(A, B, C, D)>(
      states: [a, b, c, d],
      loading: loading,
      firstError: firstError,
    );
  }

  static (Object, StackTrace?)? _firstError(
    Iterable<AsyncState<Object?>> states,
  ) {
    for (final state in states) {
      if (state.hasError) {
        return (state.error!, state.stackTrace);
      }
    }
    return null;
  }

  static AsyncState<R> _withoutCompleteValue<R>({
    required Iterable<AsyncState<Object?>> states,
    required bool loading,
    required (Object, StackTrace?)? firstError,
  }) {
    if (firstError != null) {
      return AsyncState<R>._(
        hasValue: false,
        value: null,
        isLoading: loading,
        isIdle: false,
        error: firstError.$1,
        stackTrace: firstError.$2,
      );
    }

    if (loading) {
      return AsyncState<R>._(
        hasValue: false,
        value: null,
        isLoading: true,
        isIdle: false,
      );
    }

    final allIdle = states.every((state) => state.isIdle);
    return AsyncState<R>._(
      hasValue: false,
      value: null,
      isLoading: false,
      isIdle: allIdle,
    );
  }
}
