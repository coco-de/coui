import 'package:jaspr/jaspr.dart';

/// Marks a subtree as already carrying the `main` landmark.
///
/// `Scaffold` publishes it when it emits the landmark, and every scaffold
/// nested inside reads it and stays silent. Without this each scaffold in
/// a shell-plus-page composition would emit its own, nesting `main` inside
/// `main`.
///
/// Named and shaped like the Flutter counterpart so the two platforms read
/// the same; the transport is whatever each framework already offers.
class MainLandmarkScope extends InheritedComponent {
  /// Creates a scope declaring the landmark present for [child].
  const MainLandmarkScope({required super.child, super.key});

  /// Whether an enclosing `Scaffold` already emitted the landmark.
  static bool existsAbove(BuildContext context) =>
      context.dependOnInheritedComponentOfExactType<MainLandmarkScope>() !=
      null;

  @override
  bool updateShouldNotify(MainLandmarkScope oldComponent) => false;
}
