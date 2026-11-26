import 'package:coui_core/coui_core.dart';
import 'package:jaspr/jaspr.dart';

/// Lets the `SwipeActions` rows below it share one open row: when a row
/// starts to move or opens, the row that was open closes.
///
/// Mirrors Flutter `SwipeActionScope`: same constructor, same
/// [maybeOf]. Rows outside any scope are independent. The rule — who holds the
/// claim, who is closed when another takes it — is Core's
/// [CoreSwipeExclusivity]; the scope only carries one to the rows beneath it.
///
/// ```dart
/// SwipeActionScope(
///   child: div([
///     for (final item in items)
///       SwipeActions(trailingActions: [...], child: Row(item)),
///   ]),
/// )
/// ```
class SwipeActionScope extends StatefulComponent {
  /// Creates a [SwipeActionScope].
  const SwipeActionScope({required this.child, super.key});

  /// The subtree whose rows share the scope.
  final Component child;

  /// The scope the rows above [context] share, or `null` when there is none.
  static CoreSwipeExclusivity? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<_SwipeActionScopeInherited>()
        ?.exclusivity;
  }

  @override
  State<SwipeActionScope> createState() => _SwipeActionScopeState();
}

class _SwipeActionScopeState extends State<SwipeActionScope> {
  final CoreSwipeExclusivity _exclusivity = CoreSwipeExclusivity();

  @override
  Component build(BuildContext context) {
    return _SwipeActionScopeInherited(
      exclusivity: _exclusivity,
      child: component.child,
    );
  }
}

class _SwipeActionScopeInherited extends InheritedComponent {
  const _SwipeActionScopeInherited({
    required this.exclusivity,
    required super.child,
  });

  final CoreSwipeExclusivity exclusivity;

  @override
  bool updateShouldNotify(_SwipeActionScopeInherited oldComponent) {
    return !identical(exclusivity, oldComponent.exclusivity);
  }
}
