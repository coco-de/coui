import 'package:coui_flutter/coui_flutter.dart';

/// Makes the [SwipeActions] rows below it exclusive: at most one of them is
/// open (or being swiped) at a time, and starting to swipe or opening another
/// closes it.
///
/// The scope owns one [CoreSwipeExclusivity] — the same object the Web seat's
/// scope owns — and a row below it claims that object when its drag arms and
/// releases it once it has come to rest closed. Rows with no scope above them
/// are independent of one another.
///
/// Typically wrap the list the rows are in:
///
/// ```dart
/// SwipeActionScope(
///   child: ListView(children: [SwipeActions(...), SwipeActions(...)]),
/// )
/// ```
///
/// A scope does not close rows when the list scrolls or when the user taps
/// outside the open row; only another row's swipe closes it.
class SwipeActionScope extends StatefulWidget {
  /// Creates a [SwipeActionScope].
  const SwipeActionScope({required this.child, super.key});

  /// The subtree whose [SwipeActions] rows are made exclusive.
  final Widget child;

  /// The exclusivity the nearest scope above [context] owns, or `null` when
  /// there is none.
  ///
  /// This is a lookup, not a dependency: the object lives as long as the
  /// scope, so nothing has to rebuild when it is read.
  static CoreSwipeExclusivity? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<_SwipeActionScopeState>()?._exclusivity;

  @override
  State<SwipeActionScope> createState() => _SwipeActionScopeState();
}

class _SwipeActionScopeState extends State<SwipeActionScope> {
  final CoreSwipeExclusivity _exclusivity = CoreSwipeExclusivity();

  @override
  Widget build(BuildContext context) => widget.child;
}
