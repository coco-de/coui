import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// Every `--coui-*` name a reader could look up has to be in the sheet.
///
/// A name the docs reference advertises and the generator never emits
/// fails silently in both directions: a stylesheet cannot complain about
/// a name it was never asked for, and a reader who tries one gets the
/// fallback and moves on. So the absence is asserted rather than assumed.
void main() {
  final css =
      ThemeConfig.defaults().cssVariables +
      ThemeConfig.defaults().darkVariableBlock +
      ThemeConfig.defaults().surfaceStyleVariableBlocks;

  group('the glass colour model is not in the stylesheet', () {
    test('none of its four names is emitted', () {
      // The catalog guard in coui_core holds the other direction — every
      // `CoreColors` token is emitted. This holds this one: a variable
      // invented in the generator alone, under a name the docs once
      // advertised, would not show up there.
      for (final name in [
        'glass-tint',
        'glass-highlight',
        'glass-shadow',
        'glass-illumination',
      ]) {
        expect(
          css,
          isNot(contains('--coui-$name')),
          reason:
              'if this is emitted now, the docs reference should list '
              'it again — and the surface style should stop being the only '
              'glass model',
        );
      }
    });

    test('the live glass model states a treatment instead', () {
      // What replaced it: the surface style carries the translucency, and
      // that path reaches both platforms.
      final surface = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).surfaceFor(CoreSurfaceRole.functional);

      expect(surface, isNotNull);
      expect(surface!.opacity.isOpaque, isFalse);
    });
  });
}
