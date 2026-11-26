import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  test('layout defaults to center and the split gutter is space32', () {
    expect(CoreHeroStyle.defaultLayout, CoreHeroLayout.center);
    expect(
      CoreHeroStyle.defaultSplitGapStyle.size,
      CoreSpace.space32,
    );
    expect(CoreHeroContract.defaultAppear, isFalse);
  });

  test('merge lets a later layout win and keeps an omitted one', () {
    const base = CoreHeroStyle(layout: CoreHeroLayout.center);
    final split = base.merge(const CoreHeroStyle(layout: CoreHeroLayout.split));
    expect(split.layout, CoreHeroLayout.split);
    expect(
      const CoreHeroStyle(minHeight: 200).merge(null).minHeight,
      200,
    );
  });

  test('split is a row at the tablet tier and a stack below it', () {
    expect(heroSplitIsRow(CoreBreakpointTier.mobile), isFalse);
    expect(heroSplitIsRow(CoreBreakpointTier.tablet), isTrue);
    expect(heroSplitIsRow(CoreBreakpointTier.desktop), isTrue);
    expect(
      CoreResponsiveRowColumnContract.defaultSwitchAt,
      CoreBreakpointTier.tablet,
    );
  });
}
