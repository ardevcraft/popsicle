import 'package:meta/meta.dart';

import 'store.dart';

/// Opt-in undo/redo history for a [Store].
///
/// History tracks committed state snapshots only. One-shot effects are never
/// recorded or replayed.
///
/// State used with [History] should be immutable so older snapshots cannot be
/// changed accidentally through shared mutable references.
mixin History<State> on Store<State> {
  final List<State> _undoHistory = <State>[];
  final List<State> _redoHistory = <State>[];

  /// Maximum number of snapshots retained in each history direction.
  ///
  /// Override this in a Store when a different limit is appropriate.
  int get historyLimit => 50;

  /// Whether an older state snapshot is available.
  bool get canUndo => _undoHistory.isNotEmpty;

  /// Whether a previously undone state snapshot is available.
  bool get canRedo => _redoHistory.isNotEmpty;

  /// Number of snapshots currently available to [undo].
  int get undoCount => _undoHistory.length;

  /// Number of snapshots currently available to [redo].
  int get redoCount => _redoHistory.length;

  @override
  @protected
  void commit(State next) {
    final previous = state;

    if (!identical(previous, next)) {
      _push(_undoHistory, previous);
      _redoHistory.clear();
    }

    super.commit(next);
  }

  /// Restores the previous committed state.
  ///
  /// Returns `true` when a state was restored and `false` when there was no
  /// undo history.
  bool undo() {
    if (!canUndo) return false;

    final previous = _undoHistory.removeLast();
    _push(_redoHistory, state);

    // Bypass this mixin's commit override so undo itself is not recorded as a
    // new forward transition.
    super.commit(previous);
    return true;
  }

  /// Restores the next state that was previously undone.
  ///
  /// Returns `true` when a state was restored and `false` when there was no
  /// redo history.
  bool redo() {
    if (!canRedo) return false;

    final next = _redoHistory.removeLast();
    _push(_undoHistory, state);

    // Bypass this mixin's commit override so redo does not clear its own
    // history chain.
    super.commit(next);
    return true;
  }

  /// Drops all undo and redo snapshots without changing the current state.
  void clearHistory() {
    _undoHistory.clear();
    _redoHistory.clear();
  }

  void _push(List<State> history, State snapshot) {
    final limit = historyLimit;
    if (limit <= 0) return;

    history.add(snapshot);

    final overflow = history.length - limit;
    if (overflow > 0) {
      history.removeRange(0, overflow);
    }
  }
}
