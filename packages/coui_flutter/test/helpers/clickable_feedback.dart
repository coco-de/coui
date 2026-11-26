import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

typedef ClickableFeedback = ({
  double scale,
  Matrix4 transform,
  Duration duration,
});

/// Reads the painted press transform and the resolver's motion policy.
///
/// Independent of which animation widget implements the feedback. Callers
/// checking the final appearance should settle first; quick-tap tests can
/// sample intermediate frames instead.
Iterable<ClickableFeedback> clickableFeedback(WidgetTester tester) sync* {
  for (final element in find.byType(Clickable).evaluate()) {
    final clickable = element.widget as Clickable;
    final root = find.byElementPredicate((candidate) => candidate == element);
    final child = find
        .descendant(
          of: root,
          matching: find.byWidget(clickable.child),
        )
        .first;
    final rootBox = element.findRenderObject()! as RenderBox;
    final childBox = tester.renderObject<RenderBox>(child);
    final transform = tester
        .widgetList<Container>(
          find.descendant(of: root, matching: find.byType(Container)),
        )
        .where((widget) => widget.transform != null)
        .map((widget) => widget.transform!)
        .firstOrNull;
    yield (
      scale: childBox.getTransformTo(rootBox).storage[0],
      transform: transform ?? Matrix4.identity(),
      duration: resolveClickable(
        element,
        clickableStyle: clickable.clickableStyle,
      ).pressDuration,
    );
  }
}
