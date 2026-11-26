import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart' show Component;
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// Holds the server to emitting no refraction at all.
///
/// The displacement map is generated from a measured rectangle, so there is
/// nothing to compute before the element exists. Markup that referenced a
/// filter anyway would point at a map nothing had built — and it would do
/// so in the first frame a user sees, which is the worst place for it.
void main() {
  _markupTests();

  group('the server emits no bending', () {
    testComponents('a surface that asked for it renders without one', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        OutlinedContainer(
          refraction: const CoreSurfaceRefraction(bezel: 0.2),
          child: const Component.text('content'),
        ),
      );
      await tester.pump();

      // No filter reference, and no element minted to hold one.
      expect(find.tag('filter'), findsNothing);
      expect(find.tag('feDisplacementMap'), findsNothing);
    });

    testComponents('and one that asked for none renders the same shape', (
      tester,
    ) async {
      // The parity claim: asking is opt-in, so a surface that did not ask
      // must be untouched by this unit existing.
      pumpWithTheme(
        tester,
        const OutlinedContainer(child: Component.text('content')),
      );
      await tester.pump();

      expect(find.tag('filter'), findsNothing);
      expect(find.tag('div'), findsComponents);
    });
  });

  group('the request is not a theme value', () {
    test('the surface takes it as its own parameter', () {
      const asked = OutlinedContainer(
        refraction: CoreSurfaceRefraction(bezel: 0.2),
      );
      const silent = OutlinedContainer();

      expect(asked.refraction, isNotNull);
      expect(silent.refraction, isNull);
      // The style slot is what a theme fills, and it knows nothing of this.
      expect(asked.containerStyle, isNull);
    });
  });
}

/// Everything the filter markup has to get right, tested off the browser.
///
/// The builder is a pure function of five numbers, split out of the runtime
/// for exactly that reason: the runtime imports `dart:js_interop` and cannot
/// be loaded here at all, so anything left inside it is unreachable from a
/// test. That is not hypothetical — the channel split below shipped with a
/// bug that turned every glass surface bright green, and a screenshot found
/// it because nothing else could.
void _markupTests() {
  String markup({double dispersion = 0}) => buildRefractionFilterMarkup(
    filterId: 'f',
    map: 'data:image/png;base64,AA',
    width: 240,
    height: 140,
    peak: 20,
    dispersion: dispersion,
  );

  group('the lens runs first and the band reads from it', () {
    String lensed({double dispersion = 0}) => buildRefractionFilterMarkup(
      filterId: 'f',
      map: 'data:image/png;base64,AA',
      width: 240,
      height: 140,
      peak: 20,
      dispersion: dispersion,
      lensMap: 'data:image/png;base64,BB',
      lensPeak: 11,
    );

    test('as its own pass over the source, scaled to its own peak', () {
      final css = lensed();

      expect(css, contains('result="lens"'));
      expect(
        css,
        contains(
          '<feDisplacementMap in="SourceGraphic" in2="lens" scale="22.0" ',
        ),
      );
      expect(css, contains('result="lensed"'));
    });

    test('and every band pass reads the lensed image, never the source', () {
      // The composition order is the parity claim: the Flutter shader
      // evaluates the lens at the rim-shifted point, which is what reading
      // the band from the lensed result does here.
      for (final css in [lensed(), lensed(dispersion: 0.5)]) {
        final bandPasses = RegExp(
          r'<feDisplacementMap in="(\w+)" in2="map"',
        ).allMatches(css).map((m) => m.group(1)).toList();

        expect(bandPasses, isNotEmpty);
        expect(bandPasses.every((source) => source == 'lensed'), isTrue);
      }
    });

    test('and the lens never disperses', () {
      final css = lensed(dispersion: 0.5);
      final lensPasses = RegExp(r'in2="lens"').allMatches(css).length;

      expect(lensPasses, 1);
    });

    test('a request with no lens emits the filter it always did', () {
      expect(markup(), isNot(contains('lens')));
      expect(
        markup(),
        contains('<feDisplacementMap in="SourceGraphic" in2="map"'),
      );
    });

    test('and the lens map is keyed by the box and the lens alone', () {
      const a = CoreSurfaceRefraction(bezel: 0.2, lens: 0.08);
      const b = CoreSurfaceRefraction(bezel: 0.4, lens: 0.08);
      const c = CoreSurfaceRefraction(bezel: 0.2, lens: 0.1);

      expect(
        lensMapKey(width: 240, height: 140, refraction: a),
        lensMapKey(width: 240, height: 140, refraction: b),
      );
      expect(
        lensMapKey(width: 240, height: 140, refraction: a),
        isNot(lensMapKey(width: 240, height: 140, refraction: c)),
      );
    });
  });

  group('the filter carries the bend', () {
    test('one pass when nothing disperses', () {
      // Three passes for a material that asked for none is three times the
      // filter cost to draw the same picture.
      final one = markup();

      expect('feDisplacementMap'.allMatches(one).length, 1);
      expect(one, isNot(contains('feColorMatrix')));
    });

    test('and the scale is twice the peak, because the map stores a ratio', () {
      expect(markup(), contains('scale="40.0"'));
    });
  });

  group('the channels are split and put back', () {
    test('three passes, one per channel', () {
      final split = markup(dispersion: 0.5);

      expect('feDisplacementMap'.allMatches(split).length, 3);
      expect('feColorMatrix'.allMatches(split).length, 3);
    });

    test('and every isolating matrix forces alpha to one', () {
      // The green bug, pinned. Filter results are premultiplied, so a
      // matrix that zeroes alpha has multiplied its own channel away — the
      // pass contributes nothing to the sum and the surface renders in
      // whichever single channel survived.
      final split = markup(dispersion: 0.5);
      final matrices = RegExp(
        r'<feColorMatrix[^>]*values="([^"]+)"',
      ).allMatches(split).map((m) => m.group(1)!).toList();

      expect(matrices, hasLength(3));
      for (final values in matrices) {
        expect(
          values.trim().endsWith('0 0 0 0 1'),
          isTrue,
          reason: 'a premultiplied pass with no alpha contributes no colour',
        );
      }
    });

    test('and they are summed rather than composited', () {
      // Every operator but `arithmetic` combines by alpha, which would let
      // the last pass cover the first two.
      final split = markup(dispersion: 0.5);

      expect('operator="arithmetic"'.allMatches(split).length, 2);
      expect(split, contains('k2="1" k3="1"'));
    });

    test('and the three passes travel different distances', () {
      // The whole point: identical scales would draw the same image three
      // times and cost three passes to look like one.
      final scales = RegExp(r'<feDisplacementMap[^>]*scale="([^"]+)"')
          .allMatches(markup(dispersion: 0.5))
          .map((m) => double.parse(m.group(1)!))
          .toList();

      expect(scales, hasLength(3));
      expect(scales.toSet(), hasLength(3));
      expect(scales[0], greaterThan(scales[1]));
      expect(scales[1], greaterThan(scales[2]));
    });

    test('and the middle pass is the undispersed one', () {
      // So dispersion spreads the channels *around* the bend rather than
      // shifting the whole image, which would read as a stronger bend.
      final scales = RegExp(r'<feDisplacementMap[^>]*scale="([^"]+)"')
          .allMatches(markup(dispersion: 0.5))
          .map((m) => double.parse(m.group(1)!))
          .toList();

      expect(scales[1], closeTo(40, 1e-9));
    });
  });
}
