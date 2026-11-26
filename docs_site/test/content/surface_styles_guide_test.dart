import 'dart:io';

import 'package:docs_site/components/surface_style_switcher.dart';
import 'package:test/test.dart';

/// Holds the surface-style guide to the axis it documents.
///
/// The labels come from the switcher rather than a list written here.
/// Copying them would create the second copy this unit exists to remove,
/// and a doc that names four of five presets reads as complete.
void main() {
  late String guide;

  setUpAll(() {
    guide = File('../docs_core/content/guides/surface-styles.md').readAsStringSync();
  });

  test('every preset the switcher offers is named in the guide', () {
    // `offered` is derived — it filters presets whose recipe says nothing,
    // so it can empty out without anyone editing this file. Then the loop
    // below reports every preset covered while reading none of them.
    expect(SurfaceStyleSwitcher.offered, isNotEmpty);

    for (final option in SurfaceStyleSwitcher.offered) {
      expect(
        guide,
        contains(option.label),
        reason: 'the switcher offers ${option.label} and the guide is silent',
      );
    }
  });

  test('it shows how to turn the axis on, on both platforms', () {
    // Two different handles, and a guide that shows one leaves half the
    // readers without an answer.
    expect(guide, contains('CoUIApp('));
    expect(guide, contains('surfaceStyle:'));
    expect(guide, contains('SurfaceStyleScope.setSurfaceStyle'));
  });

  test('the refraction paragraph names the engines that do not render it', () {
    // "Chromium only" is the kind of claim a reader checks by trying it in
    // the browser they have. Naming the two that do not render turns that
    // into something they can check before shipping.
    expect(guide, contains('Safari'));
    expect(guide, contains('Firefox'));
    expect(guide, contains('Flutter Web'));
  });

  test('it states the reduce-transparency fold, which both seats now have', () {
    // This used to assert the opposite — that the guide promised no such
    // fallback — while nothing on either platform read the preference. Both
    // do now: Flutter folds the material through
    // `CoUIApp(reduceTransparency:)` → `applySurfaceStyle`, and the Web
    // stylesheet carries a `prefers-reduced-transparency` rule that zeroes
    // the fill's alpha and the backdrop filter. A guide that stayed silent
    // would be describing the feature by its absence in the other direction.
    expect(guide, contains('투명도 줄이기'));
  });

  test('it does not teach the raw attribute as the way in', () {
    // The public path is the scope. A guide that demonstrates the attribute
    // pins a low-level route as canonical, and that route can express a
    // state the setter deliberately avoids.
    expect(guide, isNot(contains("setAttribute('data-coui-style'")));
  });

  test('the switcher is placed as this site, not as a kit feature', () {
    // It is on every page, so a reader will assume the kit ships a style
    // picker unless the guide says otherwise.
    expect(guide, contains('데모'));
    expect(guide, contains('최종 사용자용 스타일 피커를 출하하지 않습니다'));
  });

  test('and runtime switching is stated as possible, not denied', () {
    // Asserted positively. Searching for a denial catches the sentence
    // that *rejects* it too — the first version of this test failed on
    // the guide's own "that does not mean runtime switching is
    // impossible", which is the opposite of the thing it was hunting.
    expect(guide, contains('런타임 API'));
  });
}
