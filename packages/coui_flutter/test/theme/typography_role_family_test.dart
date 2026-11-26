// A role's own font family on Flutter — a product's display face on its
// headings. A named face falls back to the text face, so glyphs it lacks
// still draw in Pretendard rather than the platform default; the default
// scale names no face for its text roles, so nothing they render changes.
// The code roles name the mono face, which falls back to the Geist Mono
// this package bundles, then the text face for Hangul.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const face = 'Hahmlet';
  const geistSans = 'packages/coui_flutter/GeistSans';

  ThemeData themeWith(CoreTypography typography) => ThemeData.fromCore(
    CoreThemePresets.previewLight.copyWith(
      typography: typography,
      textScaling: 1.0,
      sizeScaling: 1.0,
      radiusScaling: 1.0,
    ),
  );

  final faced = themeWith(CoreTypography.coui.withFamily(face));
  final plain = themeWith(CoreTypography.coui);

  test('a heading role draws in the face, then the text face', () {
    final style = faced.typography.displayLarge.toValue(theme: faced);
    expect(style.fontFamily, face);
    expect(style.fontFamilyFallback, [CoreFontFamily.sans, geistSans]);
  });

  test('the other roles stay in the text face', () {
    final style = faced.typography.bodyMedium.toValue(theme: faced);
    expect(style.fontFamily, CoreFontFamily.sans);
    expect(style.fontFamilyFallback, kCoreSansFontFallback);
  });

  test('the default scale draws every role as before', () {
    final style = plain.typography.displayLarge.toValue(theme: plain);
    expect(style.fontFamily, CoreFontFamily.sans);
    expect(style.fontFamilyFallback, kCoreSansFontFallback);
  });

  test('naming the text face keeps its fallback', () {
    final style = const CoreTextStyle(
      fontSize: 16,
      fontFamily: CoreFontFamily.sans,
    ).toValue(theme: plain);
    expect(style.fontFamilyFallback, kCoreSansFontFallback);
  });

  test('the mono face falls back to the bundled face, then the text face', () {
    final style = const CoreTextStyle(
      fontSize: 16,
      fontFamily: CoreFontFamily.mono,
    ).toValue(theme: plain);
    expect(style.fontFamilyFallback, kCoreMonoFontFallback);
  });

  test('a code role draws in the mono face and its stack', () {
    for (final role in [
      plain.typography.codeXs,
      plain.typography.codeSm,
      plain.typography.codeMd,
    ]) {
      final style = role.toValue(theme: plain);
      expect(style.fontFamily, CoreFontFamily.mono);
      expect(style.fontFamilyFallback, kCoreMonoFontFallback);
    }
  });

  test('a display face leaves the code roles in the mono face', () {
    final style = faced.typography.codeMd.toValue(theme: faced);
    expect(style.fontFamily, CoreFontFamily.mono);
    expect(style.fontFamilyFallback, kCoreMonoFontFallback);
  });

  testWidgets('a heading drawn through the Text chain is set in the face', (
    tester,
  ) async {
    await tester.pumpWidget(
      CoUIApp(
        theme: faced,
        home: Scaffold(
          headers: const [],
          child: Column(
            children: [
              const Text('제목').displayLarge,
              const Text('본문').bodyMedium,
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    widgets.TextStyle? styleOf(String text) => tester
        .widget<widgets.RichText>(
          find.descendant(
            of: find.text(text),
            matching: find.byType(widgets.RichText),
          ),
        )
        .text
        .style;

    expect(styleOf('제목')?.fontFamily, face);
    expect(styleOf('본문')?.fontFamily, CoreFontFamily.sans);
  });
}
