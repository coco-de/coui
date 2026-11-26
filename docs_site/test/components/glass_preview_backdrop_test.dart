import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:docs_core/shared/glass_preview_backdrop.dart';
import 'package:test/test.dart';

/// The glass preview pane exists to make a translucent material judgeable,
/// and it can stop doing that without anything else noticing.
///
/// The failure it guards is not a crash or a wrong colour — it is a preview
/// that renders beautifully while saying nothing about the material. That
/// happened once already: the pane carried three smooth colour washes, and
/// against a smooth field a correct displacement and no displacement at all
/// produce the same picture. Removing the refraction pass entirely moved 22
/// channel levels; winding the frost from 4 back to the 12 it came from
/// moved 4. Nobody can see 4.
///
/// So these read the shipped blur out of the recipe rather than restating a
/// number. If someone raises the frost past what the backdrop's structure
/// can survive, the recipe quietly stops being able to show that very
/// decision — and this is what says so.
///
/// # Why this reads `glass_preview_backdrop.dart`, not `site_head.dart`
///
/// The gradient recipe used to live only as a CSS string literal inside
/// `site_head.dart`, and this file parsed that source text with regexes to
/// check it. That was itself the single-source violation this project
/// otherwise forbids everywhere else (`core/style-contract.md`): the only
/// reason Flutter's preview pane couldn't show the same backdrop was that
/// the numbers existed nowhere Flutter could read them. Now both `site_head
/// .dart` (CSS emit) and `glass_preview_backdrop_painter.dart` (Flutter
/// emit) read `docs_core/shared/glass_preview_backdrop.dart`, so this suite
/// asserts against that shared data directly — and separately checks that
/// neither emit side re-declares its own copy of it.
void main() {
  late String siteHead;
  late String previewApp;
  late String backdropPainter;

  setUpAll(() {
    siteHead = File('../docs_core/lib/site_head.dart').readAsStringSync();
    previewApp = File('lib/widgets/preview_app.dart').readAsStringSync();
    backdropPainter = File('lib/widgets/glass_preview_backdrop_painter.dart').readAsStringSync();
  });

  final glass = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    final recipe = dark ? kGlassPreviewBackdropDark : kGlassPreviewBackdropLight;

    group('the $mode glass preview recipe can be judged', () {
      test('carries a hard edge at all', () {
        // A backdrop of smooth gradients cannot show refraction: bending a
        // smooth field yields a smooth field. The grid is the one layer in
        // this recipe with a hard (non-gradual) edge.
        expect(
          recipe.horizontalGrid.lineWidth,
          greaterThan(0),
          reason: 'the horizontal grid line has no width — no hard edge to bend',
        );
        expect(
          recipe.verticalGrid.lineWidth,
          greaterThan(0),
          reason: 'the vertical grid line has no width — no hard edge to bend',
        );
      });

      test('and its structure is coarser than the frost erases', () {
        // The filter list runs blur before the displacement, so anything
        // finer than the blur radius is gone before refraction can bend it.
        // functional: the role liquidGlass actually blurs under now (#4424);
        // content draws flat, so reading its blur here would always throw.
        final blur = glass.surfaceFor(CoreSurfaceRole.functional)!.blurRadius!;
        final coarsest = [recipe.horizontalGrid.lineWidth, recipe.verticalGrid.lineWidth].reduce(
          (a, b) => a > b ? a : b,
        );

        expect(
          coarsest,
          greaterThanOrEqualTo(blur),
          reason:
              'the coarsest hard edge is ${coarsest}px and the frost is '
              '${blur}px — the blur erases the structure before the '
              'refraction reaches it, so this recipe cannot show either term',
        );
      });
    });
  }

  group('the recipe has exactly one home', () {
    test('site_head.dart emits it, rather than hand-writing its own copy', () {
      expect(
        siteHead,
        contains("import 'shared/glass_preview_backdrop.dart'"),
        reason: 'the CSS side must read the shared recipe, not restate it',
      );
      expect(
        siteHead,
        allOf(
          contains('_glassBackdropCss(kGlassPreviewBackdropLight)'),
          contains('_glassBackdropCss(kGlassPreviewBackdropDark)'),
        ),
        reason: 'both panes should build their CSS from the shared constants',
      );
      // The old hand-written grid layer, 8-digit-hex-and-all — not just its
      // 6-digit RGB (`#0f172a` is also a legitimate, unrelated colour used
      // elsewhere on this page) but the exact ARGB-with-alpha literal that
      // only ever existed as this recipe's grid line. Its reappearance
      // would mean someone reintroduced a hand-written second copy.
      expect(
        siteHead,
        isNot(contains('0f172a2e')),
        reason: 'the grid colour moved to glass_preview_backdrop.dart — a literal here is a second copy',
      );
    });

    test('the Flutter pane reads it too, instead of staying opaque forever', () {
      expect(
        previewApp,
        contains('CoreSurfaceStyleId.liquidGlass'),
        reason: 'the Flutter pane must gate the backdrop on the same style Web does',
      );
      expect(
        previewApp,
        allOf(contains('kGlassPreviewBackdropDark'), contains('kGlassPreviewBackdropLight')),
        reason: 'the Flutter pane must paint from the same shared constants as the CSS side',
      );
    });

    test('the Flutter painter has no colour literals of its own', () {
      // The painter takes a `GlassPreviewBackdrop` and reads every colour
      // off it — checked against the recipes' own values rather than a
      // blanket "no hex literal" rule, because the painter legitimately
      // needs its own literal transparent sentinel (`0x00000000`) to build
      // gradient stops, and that isn't a recipe colour to guard against.
      String argbHex(int argb) => '0x${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
      final recipeColors =
          [
            kGlassPreviewBackdropLight,
            kGlassPreviewBackdropDark,
          ].expand(
            (r) => [
              r.horizontalGrid.colorArgb,
              r.verticalGrid.colorArgb,
              r.band.colorArgb,
              ...r.washes.map((w) => w.colorArgb),
              r.baseColorArgb,
            ],
          );

      for (final argb in recipeColors) {
        expect(
          backdropPainter,
          isNot(contains(argbHex(argb))),
          reason:
              '${argbHex(argb)} is one of the recipe colours — the painter should read it off `recipe`, not restate it',
        );
      }
    });
  });

  test('and a style with nothing to see through gets no backdrop', () {
    // The four other presets are opaque, so a backdrop under them would be
    // invisible — and their captures must not move, which is what makes
    // this change reviewable at all.
    //
    // Which styles those are is computed from the recipes rather than
    // listed, so a preset that later turns translucent is allowed its own
    // backdrop without anyone editing this, and one that turns opaque
    // starts being checked without anyone remembering to.
    //
    // The fill share is a `CoreSurfaceOpacity` pair, so "is there anything
    // to see through" is asked once per mode. A style translucent in only
    // one mode has a backdrop to show there and nothing in the other.
    // Asking "in either mode" would let it keep a backdrop under its opaque
    // mode; asking "in both modes" would forbid the one its translucent
    // mode needs.
    bool seesThrough(CoreSurfaceStyleId id, CoreBrightness mode) {
      final recipe = CoreSurfaceRecipe.of(id);

      return CoreSurfaceRole.values.any((role) {
        final surface = recipe.surfaceFor(role);

        return surface != null &&
            (surface.opacity.resolve(mode) < CoreSurfaceOpacity.opaqueValue || surface.blurRadius != null);
      });
    }

    // A rule that names a theme applies only in that mode; one that names
    // none applies in every mode — the light glass rule is also what a dark
    // page gets wherever no dark rule overrides it.
    final themeAttribute = RegExp(r'\[data-theme="(\w+)"\]');
    bool appliesIn(String selector, CoreBrightness mode) {
      final theme = themeAttribute.firstMatch(selector)?.group(1);

      return theme == null || theme == mode.name;
    }

    // `\s*` around the quotes tolerates `css(\n  '...',\n)` — `dart format`
    // wraps the compound dark-mode selector onto its own line once it grows
    // a `.preview-web` suffix, and a regex that only matched `css('...')`
    // on one line would silently stop seeing that rule at all.
    final paneSelectors = RegExp(
      r"css\(\s*'([^']*\.preview-pane[^']*)'\s*\)",
    ).allMatches(siteHead).map((m) => m.group(1)!).toList();
    expect(paneSelectors, isNotEmpty);

    for (final mode in CoreBrightness.values) {
      for (final id in CoreSurfaceStyleId.values.where((i) => !seesThrough(i, mode))) {
        for (final selector in paneSelectors.where((s) => appliesIn(s, mode))) {
          expect(
            selector.contains(id.name),
            isFalse,
            reason:
                '$selector paints a backdrop for ${id.name} in ${mode.name}, '
                'where its material is opaque — nothing would show through '
                'it, and its preview captures move for no reason',
          );
        }
        // Same guarantee, Flutter side: the backdrop layer is gated on a
        // single style name (`liquidGlass`) and only then picks the recipe
        // by mode, so a gated style paints its backdrop in every mode — an
        // opaque one in any mode can only reach it if that name changes to
        // include it.
        expect(
          previewApp.contains('_surfaceStyle == CoreSurfaceStyleId.${id.name}'),
          isFalse,
          reason:
              'the Flutter pane must not gate the backdrop on ${id.name}, '
              'whose material is opaque in ${mode.name}',
        );
      }
    }
  });

  test('and a rule naming both a theme and a style is compound', () {
    // The site sets `data-theme` and `data-coui-style` on the same element
    // (`<html>`), so a space between those two attribute selectors asks for
    // one nested inside the other and matches nothing.
    //
    // This is not hypothetical. The dark glass pane was written with a
    // space and rendered flat — no washes, no structure — for as long as it
    // existed, and nothing failed. It was found by screenshotting the dark
    // preview and seeing plain navy where a material should have been.
    final descendant = RegExp(
      r'\[data-(theme|coui-style)="[^"]*"\]\s+\[data-(theme|coui-style)="',
    );

    expect(
      descendant.firstMatch(siteHead)?.group(0),
      isNull,
      reason:
          'these two attributes live on the same element, so this selector '
          'can never match — write it compound, with no space',
    );
  });
}
