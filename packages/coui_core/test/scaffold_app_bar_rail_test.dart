import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  test('a single side needs room for an app-bar control rail', () {
    for (final (insets, expected) in [
      (const CoreEdgeInsets.only(right: 84, bottom: 34), true),
      (CoreEdgeInsets.zero, false),
      (const CoreEdgeInsets.only(top: 59, right: 84), false),
      (const CoreEdgeInsets.symmetric(horizontal: 44), false),
      (const CoreEdgeInsets.only(left: 84), true),
      (const CoreEdgeInsets.only(left: 84, right: 84), false),
      (const CoreEdgeInsets.only(left: 20), false),
      (const CoreEdgeInsets.only(right: 20), false),
    ]) {
      expect(
        CoreScaffoldContract.hasAppBarControlRail(
          insets: insets,
          controlWidth: 48,
          outerInset: 24,
        ),
        expected,
      );
    }
    expect(
      CoreScaffoldContract.hasAppBarControlRail(
        insets: const CoreEdgeInsets.only(right: 84),
        controlWidth: 96,
        outerInset: 24,
      ),
      isFalse,
    );
  });
  test('rail padding follows the same theme and instance merge contract', () {
    const theme = CoreScaffoldStyle(
      appBarRailPadding: CoreEdgeInsets.only(top: 140),
    );
    final changed = theme.merge(
      const CoreScaffoldStyle(appBarRailPadding: CoreEdgeInsets.only(top: 160)),
    );
    expect(changed.appBarRailPadding!.top, 160);
    expect(
      changed,
      theme.copyWith(appBarRailPadding: const CoreEdgeInsets.only(top: 160)),
    );
    expect(changed, isNot(theme));
  });
}
