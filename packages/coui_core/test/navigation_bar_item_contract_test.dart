import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// A destination composed by the bar and one placed on its own read the
/// same defaults — these rules are the one place both platforms, and both
/// the bar and the item, ask.
void main() {
  group('CoreNavigationBarItemContract', () {
    test('a standalone item draws a sidebar row unless told otherwise', () {
      expect(
        CoreNavigationBarItemContract.defaultMode,
        CoreNavigationBarMode.sidebar,
      );
    });
  });

  group('CoreNavigationBarMode.defaultLabelMode', () {
    test('each mode answers with its own stated default', () {
      expect(
        CoreNavigationBarMode.bar.defaultLabelMode,
        CoreNavigationLabelMode.defaultBarMode,
      );
      expect(
        CoreNavigationBarMode.rail.defaultLabelMode,
        CoreNavigationLabelMode.defaultRailMode,
      );
      expect(
        CoreNavigationBarMode.sidebar.defaultLabelMode,
        CoreNavigationLabelMode.defaultSidebarMode,
      );
    });

    test('the three answers are the shapes the layouts draw', () {
      // Spelled as values too, so a default and the mode-to-default mapping
      // drifting together still fails.
      // The bottom bar names its destinations under their icons (#5740).
      expect(
        CoreNavigationBarMode.bar.defaultLabelMode,
        CoreNavigationLabelMode.all,
      );
      expect(
        CoreNavigationBarMode.rail.defaultLabelMode,
        CoreNavigationLabelMode.all,
      );
      expect(
        CoreNavigationBarMode.sidebar.defaultLabelMode,
        CoreNavigationLabelMode.all,
      );
    });
  });

  group('CoreNavigationBarMode.defaultLabelPosition', () {
    test('the sidebar sets the label beside the icon, the others under it', () {
      expect(
        CoreNavigationBarMode.sidebar.defaultLabelPosition,
        CoreNavigationLabelPosition.defaultSidebarPosition,
      );
      expect(
        CoreNavigationBarMode.sidebar.defaultLabelPosition,
        CoreNavigationLabelPosition.end,
      );
      for (final mode in [
        CoreNavigationBarMode.bar,
        CoreNavigationBarMode.rail,
      ]) {
        expect(
          mode.defaultLabelPosition,
          CoreNavigationLabelPosition.defaultBarPosition,
          reason: '$mode',
        );
        expect(
          mode.defaultLabelPosition,
          CoreNavigationLabelPosition.bottom,
          reason: '$mode',
        );
      }
    });
  });

  group('CoreNavigationBarMode.badgeAtRowEnd', () {
    test('a sidebar row carries its badge at the far end', () {
      expect(
        CoreNavigationBarMode.sidebar.badgeAtRowEnd(hasIcon: true),
        isTrue,
      );
      expect(
        CoreNavigationBarMode.sidebar.badgeAtRowEnd(hasIcon: false),
        isTrue,
      );
    });

    test('the bar and the rail hang it on the icon while there is one', () {
      for (final mode in [
        CoreNavigationBarMode.bar,
        CoreNavigationBarMode.rail,
      ]) {
        expect(mode.badgeAtRowEnd(hasIcon: true), isFalse, reason: '$mode');
        expect(mode.badgeAtRowEnd(hasIcon: false), isTrue, reason: '$mode');
      }
    });
  });

  group('CoreNavigationLabelMode.showsLabel', () {
    test('all — always', () {
      expect(CoreNavigationLabelMode.all.showsLabel(selected: true), isTrue);
      expect(CoreNavigationLabelMode.all.showsLabel(selected: false), isTrue);
    });

    test('selected — only the current destination', () {
      expect(
        CoreNavigationLabelMode.selected.showsLabel(selected: true),
        isTrue,
      );
      expect(
        CoreNavigationLabelMode.selected.showsLabel(selected: false),
        isFalse,
      );
    });

    test('none — never', () {
      expect(CoreNavigationLabelMode.none.showsLabel(selected: true), isFalse);
      expect(CoreNavigationLabelMode.none.showsLabel(selected: false), isFalse);
    });
  });
}
