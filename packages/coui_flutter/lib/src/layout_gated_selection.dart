/// The layout gate that keeps a never-laid-out selectable out of
/// screen-order sorting — shared by the app-wide web selection scope
/// ([CoUIApp]), the scroll behaviors that put it inside every
/// `Scrollable`'s chrome, and CoUI scroll views that install a behavior of
/// their own.
///
/// Package-internal: not exported from the barrel.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart'
    as r
    show Selectable, SelectionRegistrar;

/// Holds a selectable back from its registrar until it has been laid out,
/// then hands it over.
///
/// Every registrar that orders its selectables does so by their boxes —
/// [MultiSelectableSelectionContainerDelegate] sorts new arrivals into
/// screen order — and a box that has never been laid out has no size to
/// read. Text on a page that has never been laid out has never been on
/// screen, so it has no place in a screen order yet; it is handed over on
/// the first frame its box has a size.
class LayoutGate {
  /// Creates a [LayoutGate].
  LayoutGate({required this.admit, required this.withdraw});

  /// Hands a laid-out selectable to the registrar.
  final void Function(r.Selectable) admit;

  /// Takes a handed-over selectable back from the registrar.
  final void Function(r.Selectable) withdraw;

  final _awaitingLayout = <r.Selectable>{};
  bool _recheckScheduled = false;
  bool _disposed = false;

  static bool _hasBeenLaidOut(r.Selectable selectable) {
    // Nested selection containers — every `Text` is one — are states.
    if (selectable case final State state) {
      if (!state.mounted) return false;
      final box = state.context.findRenderObject();

      return box is! RenderBox || box.hasSize;
    }
    if (selectable case final RenderBox box) return box.hasSize;

    return true;
  }

  /// Admits [selectable] now if it has been laid out, else after the
  /// first frame that lays it out.
  void add(r.Selectable selectable) {
    if (_hasBeenLaidOut(selectable)) {
      admit(selectable);

      return;
    }
    _awaitingLayout.add(selectable);
    _scheduleRecheck();
  }

  /// Forgets [selectable], withdrawing it if it was already admitted.
  void remove(r.Selectable selectable) {
    if (_awaitingLayout.remove(selectable)) return;
    withdraw(selectable);
  }

  /// Runs after the frame's layout. Does not request frames of its own:
  /// a covered page only gains a size in a frame that something else
  /// asked for.
  void _scheduleRecheck() {
    if (_recheckScheduled) return;
    _recheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recheckScheduled = false;
      if (_disposed) return;
      final laidOut = _awaitingLayout.where(_hasBeenLaidOut).toList();
      _awaitingLayout.removeAll(laidOut);
      laidOut.forEach(admit);
      if (_awaitingLayout.isNotEmpty) _scheduleRecheck();
    }, debugLabel: 'CoUIWebTextSelection.recheckLayout');
  }

  /// Stops admitting; pending selectables are dropped.
  void dispose() {
    _disposed = true;
    _awaitingLayout.clear();
  }
}

/// Puts a [_LayoutGatedSelectionRegistrar] between the selection
/// container above it and the selectables below it.
///
/// Where selection is off above it there is nothing to gate; where a gate
/// already sits above it, it passes that one through instead of stacking
/// a second.
class LayoutGatedSelectionScope extends StatefulWidget {
  /// Creates a [LayoutGatedSelectionScope].
  const LayoutGatedSelectionScope({required this.child, super.key});

  /// The subtree whose selectables register through the gate.
  final Widget child;

  @override
  State<LayoutGatedSelectionScope> createState() =>
      _LayoutGatedSelectionScopeState();
}

class _LayoutGatedSelectionScopeState extends State<LayoutGatedSelectionScope> {
  final _registrar = _LayoutGatedSelectionRegistrar();
  r.SelectionRegistrar? _ambient;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ambient = SelectionContainer.maybeOf(context);
    _registrar.target = _ambient is _LayoutGatedSelectionRegistrar
        ? null
        : _ambient;
  }

  @override
  void dispose() {
    _registrar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ambient = _ambient;
    // Nothing to gate where selection is off. (A scrollable only builds
    // its selection container while it has a registrar, so its chrome —
    // this scope included — remounts whenever that changes anyway.)
    if (ambient == null) return widget.child;

    return SelectionRegistrarScope(
      registrar: ambient is _LayoutGatedSelectionRegistrar
          ? ambient
          : _registrar,
      child: widget.child,
    );
  }
}

/// Forwards registrations to [target], each one once its selectable has
/// been laid out — see [LayoutGate].
class _LayoutGatedSelectionRegistrar implements r.SelectionRegistrar {
  late final _gate = LayoutGate(admit: _admit, withdraw: _withdraw);

  /// Everything handed over, so a change of [target] can move it.
  final _admitted = <r.Selectable>{};

  r.SelectionRegistrar? _target;
  r.SelectionRegistrar? get target => _target;

  set target(r.SelectionRegistrar? value) {
    if (identical(value, _target)) return;
    final previous = _target;
    _target = value;
    for (final selectable in _admitted) {
      previous?.remove(selectable);
      value?.add(selectable);
    }
  }

  void _admit(r.Selectable selectable) {
    _admitted.add(selectable);
    _target?.add(selectable);
  }

  void _withdraw(r.Selectable selectable) {
    if (_admitted.remove(selectable)) _target?.remove(selectable);
  }

  @override
  void add(r.Selectable selectable) => _gate.add(selectable);

  @override
  void remove(r.Selectable selectable) => _gate.remove(selectable);

  void dispose() => _gate.dispose();
}
