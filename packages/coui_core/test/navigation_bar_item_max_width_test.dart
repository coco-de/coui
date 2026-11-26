import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The bar's destinations stop growing at 96 and gather in the middle; the
/// rail, the sidebar and the floating glass capsule keep their own widths.
void main() {
  group('itemMaxWidth defaults', () {
    test('the bar cell caps a destination at 96', () {
      expect(
        CoreNavigationBarStyle
            .defaultsByMode[CoreNavigationBarMode.bar]!
            .itemMaxWidth,
        CoreSize.size96,
      );
    });

    test('the rail and the sidebar state no cap', () {
      for (final mode in [
        CoreNavigationBarMode.rail,
        CoreNavigationBarMode.sidebar,
      ]) {
        expect(
          CoreNavigationBarStyle.defaultsByMode[mode]!.itemMaxWidth,
          isNull,
          reason: '$mode falls through to the flat default',
        );
      }
    });

    test('the flat default is no cap', () {
      expect(CoreNavigationBarStyle.defaultItemMaxWidth, double.infinity);
    });

    test('the glass bar states no cap, so its lens keeps equal cells', () {
      // The preset sits under the caller's chain and over the mode cell, so
      // stating "no cap" here is what keeps the capsule spanning its row.
      expect(
        CoreNavigationBarStyle.glassBarStyle.itemMaxWidth,
        double.infinity,
      );
      final resolved =
          CoreNavigationBarStyle.glassBarStyle.itemMaxWidth ??
          CoreNavigationBarStyle
              .defaultsByMode[CoreNavigationBarMode.bar]!
              .itemMaxWidth;
      expect(resolved!.isFinite, isFalse);
    });
  });

  group('CoreNavigationBarStyle.itemMaxWidth value semantics', () {
    const a = CoreNavigationBarStyle(itemMaxWidth: 80);

    test('merge takes the other side when it states one', () {
      expect(a.merge(const CoreNavigationBarStyle()).itemMaxWidth, 80);
      expect(
        a.merge(const CoreNavigationBarStyle(itemMaxWidth: 120)).itemMaxWidth,
        120,
      );
    });

    test('copyWith replaces it and keeps it otherwise', () {
      expect(a.copyWith(itemMaxWidth: 64).itemMaxWidth, 64);
      expect(a.copyWith().itemMaxWidth, 80);
    });

    test('== and hashCode see it', () {
      expect(a, const CoreNavigationBarStyle(itemMaxWidth: 80));
      expect(
        a.hashCode,
        const CoreNavigationBarStyle(itemMaxWidth: 80).hashCode,
      );
      expect(a == const CoreNavigationBarStyle(itemMaxWidth: 81), isFalse);
    });
  });

  group('CoreNavigationBarModeStyle.itemMaxWidth value semantics', () {
    const cell = CoreNavigationBarModeStyle(spacing: 0, itemMaxWidth: 96);

    test('copyWith replaces it and keeps it otherwise', () {
      expect(cell.copyWith(itemMaxWidth: 72).itemMaxWidth, 72);
      expect(cell.copyWith().itemMaxWidth, 96);
    });

    test('== and hashCode see it', () {
      const same = CoreNavigationBarModeStyle(spacing: 0, itemMaxWidth: 96);
      expect(cell, same);
      expect(cell.hashCode, same.hashCode);
      expect(
        cell == const CoreNavigationBarModeStyle(spacing: 0, itemMaxWidth: 97),
        isFalse,
      );
    });
  });
}
