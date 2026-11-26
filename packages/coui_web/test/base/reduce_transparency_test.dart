import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/theme_config.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:test/test.dart';

// `role: .functional` at the liquidGlass call sites — that is the role
// this preset's translucency rides now (#4424); content draws flat and
// has no transparency for this query to remove.
String _treatment(
  CoreSurfaceStyleId id, {
  CoreSurfaceRole role = CoreSurfaceRole.content,
}) => ThemeConfig.defaults().surfaceStyleTreatmentBlock(
  id,
  CoreSurfaceRecipe.of(id).surfaceFor(role),
  role: role,
);

/// The sheet the page actually gets — a builder can return the right
/// rule while nothing calls it.
String get _sheet => ThemeConfig.defaults().surfaceStyleVariableBlocks;

void main() {
  group('the stylesheet answers reduce transparency', () {
    test('a translucent preset states the fallback', () {
      final css = _treatment(.liquidGlass, role: CoreSurfaceRole.functional);

      expect(css, contains('@media (prefers-reduced-transparency:reduce)'));
      // Both halves. Dropping only the fill leaves a blur behind an
      // opaque panel; dropping only the blur leaves the panel see-
      // through. The setting asked for neither.
      expect(css, contains('backdrop-filter:none !important;'));
      expect(
        css,
        contains(
          'background-color:rgb(var($kWebSurfaceFillVar) / '
          'var($kWebSurfaceFillAlphaVar, 1)) !important;',
        ),
      );
    });

    test('and it reaches the sheet, not just the builder', () {
      expect(_sheet, contains('prefers-reduced-transparency'));
    });

    test('a preset with no transparency states no fallback', () {
      // Nothing to remove, and a query that turns off a filter nobody
      // set is noise in every sheet that carries it.
      expect(
        _treatment(.neoBrutalism),
        isNot(contains('prefers-reduced-transparency')),
      );
    });
  });

  group('and it says the same thing the shared policy says', () {
    // Web writes CSS and Flutter rebuilds a token, so the two can only
    // be held together by comparing each to one statement. This is that
    // comparison: the CSS is checked against what
    // `withoutTransparency()` produces rather than against a second copy
    // of the rule.
    test('opaque fill, no backdrop pass, band kept', () {
      final authored = CoreSurfaceRecipe.of(.liquidGlass).functionalSurface!;
      final fallback = authored.withoutTransparency();
      final css = _treatment(.liquidGlass, role: CoreSurfaceRole.functional);

      expect(
        fallback.opacity,
        CoreSurfaceOpacity.opaque,
        reason: 'policy: fill goes opaque',
      );
      expect(
        css,
        contains(
          'background-color:rgb(var($kWebSurfaceFillVar) / '
          'var($kWebSurfaceFillAlphaVar, 1)) !important;',
        ),
        reason:
            'and the CSS states the same — the share gone, the alpha of the '
            'token kept, as the Flutter twin keeps the token',
      );

      expect(fallback.blurRadius, isNull, reason: 'policy: no backdrop pass');
      expect(
        css,
        contains('backdrop-filter:none !important;'),
        reason: 'and the CSS states the same',
      );

      expect(fallback.sheen, isNotNull, reason: 'policy: the band stays');
      // The band is emitted as a `::after` rule outside the query, so
      // the query must not touch it.
      final query = css.substring(
        css.indexOf('@media (prefers-reduced-transparency:reduce)'),
      );
      expect(query, isNot(contains('background-image')));
    });
  });
}
