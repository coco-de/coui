import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// Which actions a bar keeps and which a column takes once a bar's actions
/// stand beside the content. `AppBar` and `ToolbarGroup` on both platforms
/// ask here, so one action cannot be drawn twice or not at all.
void main() {
  group('CoreBarActionAxisBehavior.allows', () {
    test('an automatic action goes on either axis', () {
      for (final axis in CoreAxis.values) {
        expect(
          CoreBarActionAxisBehavior.automatic.allows(axis),
          isTrue,
          reason: '$axis',
        );
      }
    });

    test('a horizontal-only action goes in a row and nowhere else', () {
      expect(
        CoreBarActionAxisBehavior.horizontalOnly.allows(CoreAxis.horizontal),
        isTrue,
      );
      expect(
        CoreBarActionAxisBehavior.horizontalOnly.allows(CoreAxis.vertical),
        isFalse,
      );
    });
  });

  test('an action no marker wraps goes where the actions go', () {
    expect(
      CoreBarActionContract.unmarkedAxisBehavior,
      CoreBarActionAxisBehavior.automatic,
    );
  });

  group('CoreAppBarContract.keepsAction', () {
    test('a bar draws its actions in its own row unless told otherwise', () {
      expect(CoreAppBarContract.defaultActionsAxis, CoreAxis.horizontal);
    });

    test('a bar with its actions in its row keeps every one', () {
      for (final behavior in CoreBarActionAxisBehavior.values) {
        expect(
          CoreAppBarContract.keepsAction(
            behavior,
            actionsAxis: CoreAxis.horizontal,
          ),
          isTrue,
          reason: '$behavior',
        );
      }
    });

    test('a bar with its actions in a column keeps the row-only ones', () {
      expect(
        CoreAppBarContract.keepsAction(
          CoreBarActionAxisBehavior.horizontalOnly,
          actionsAxis: CoreAxis.vertical,
        ),
        isTrue,
      );
      expect(
        CoreAppBarContract.keepsAction(
          CoreBarActionAxisBehavior.automatic,
          actionsAxis: CoreAxis.vertical,
        ),
        isFalse,
      );
    });

    test('every action is drawn exactly once: by the bar or the column', () {
      // The column draws what allows its axis; the bar keeps the rest.
      for (final behavior in CoreBarActionAxisBehavior.values) {
        final inBar = CoreAppBarContract.keepsAction(
          behavior,
          actionsAxis: CoreAxis.vertical,
        );
        final inColumn = behavior.allows(CoreAxis.vertical);

        expect(inBar, isNot(inColumn), reason: '$behavior');
      }
    });
  });
}
