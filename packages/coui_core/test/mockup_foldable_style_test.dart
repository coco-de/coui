// Tests for CoreMockupFoldableStyle / CoreMockupFoldableTheme and the layout
// that sizes a folding device's two faces (CoreMockupFoldableLayout).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kEdge = CoreColor.token(CoreColors.primary);
const _kShade = CoreColor.token(CoreColors.error);

CoreMockupFoldableLayout _layout({
  double width = CoreMockupFoldableStyle.defaultWidth,
  CoreMockupDeviceStyle inner = CoreMockupFoldableStyle.defaultInnerDeviceStyle,
  CoreMockupDeviceStyle cover = CoreMockupFoldableStyle.defaultCoverDeviceStyle,
  double islandWidth = CoreMockupFoldableStyle.defaultIslandWidth,
  double islandOffset = CoreMockupFoldableStyle.defaultIslandOffset,
  double islandCameraSize = CoreMockupFoldableStyle.defaultIslandCameraSize,
}) => CoreMockupFoldableLayout.compute(
  width: width,
  innerDeviceStyle: inner,
  coverDeviceStyle: cover,
  thickness: CoreMockupFoldableStyle.defaultThickness,
  perspective: CoreMockupFoldableStyle.defaultPerspective,
  islandWidth: islandWidth,
  islandOffset: islandOffset,
  islandCameraSize: islandCameraSize,
);

/// Whether [path] is written in the four commands a `CoreVectorGlyph` allows,
/// every number separated by one space.
bool _isGlyphPath(String path) => path
    .split(' ')
    .every((t) => 'MLCZ'.contains(t) || double.tryParse(t) != null);

void main() {
  group('CoreMockupFoldableStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreMockupFoldableStyle(
        thickness: CoreMockupFoldableStyle.defaultThickness,
        edgeColor: CoreMockupFoldableStyle.defaultEdgeColor,
        shadeOpacity: CoreMockupFoldableStyle.defaultShadeOpacity,
      );
      const themeStyle = CoreMockupFoldableStyle(edgeColor: _kEdge);
      const widgetStyle = CoreMockupFoldableStyle(
        thickness: 20,
        shadeColor: _kShade,
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.thickness, 20);
      expect(effective.edgeColor, _kEdge);
      expect(effective.shadeColor, _kShade);
      expect(
        effective.shadeOpacity,
        CoreMockupFoldableStyle.defaultShadeOpacity,
      );
    });

    test('the nested device styles merge field by field', () {
      const base = CoreMockupFoldableStyle(
        innerDeviceStyle: CoreMockupDeviceStyle(railWidth: 4, bezelWidth: 10),
        coverDeviceStyle: CoreMockupDeviceStyle(bezelWidth: 6),
      );
      const patch = CoreMockupFoldableStyle(
        innerDeviceStyle: CoreMockupDeviceStyle(bezelWidth: 12),
      );

      final merged = base.merge(patch);

      // The patch states one field; the other survives.
      expect(merged.innerDeviceStyle?.railWidth, 4);
      expect(merged.innerDeviceStyle?.bezelWidth, 12);
      expect(merged.coverDeviceStyle?.bezelWidth, 6);
    });

    test("the clock's text style merges field by field", () {
      const base = CoreMockupFoldableStyle(
        islandTextStyle: CoreTextStyle.token(CoreTextStyles.titleSmall),
      );
      const patch = CoreMockupFoldableStyle(
        islandTextStyle: CoreTextStyle(color: _kEdge),
      );

      final merged = base.merge(patch).islandTextStyle;

      // The patch states a colour; the role survives.
      expect(merged?.token, CoreTextStyles.titleSmall);
      expect(merged?.color, _kEdge);
    });

    test('a nested style stated only by the patch is taken whole', () {
      const patch = CoreMockupFoldableStyle(
        coverDeviceStyle: CoreMockupDeviceStyle(bezelWidth: 6),
      );

      expect(
        const CoreMockupFoldableStyle().merge(patch).coverDeviceStyle,
        patch.coverDeviceStyle,
      );
    });

    test('merge(null) is the style itself', () {
      const style = CoreMockupFoldableStyle(thickness: 9);
      expect(style.merge(null), same(style));
    });

    test('copyWith replaces only what it names', () {
      const style = CoreMockupFoldableStyle(
        thickness: 9,
        perspective: 3,
        duration: Duration.zero,
        curve: CoreEasing.enter,
      );

      final copy = style.copyWith(perspective: 4);

      expect(copy.thickness, 9);
      expect(copy.perspective, 4);
      expect(copy.duration, Duration.zero);
      expect(copy.curve, CoreEasing.enter);
    });

    test('== and hashCode read every field', () {
      const base = CoreMockupFoldableStyle();
      // One instance per field, each differing from `base` in that field
      // alone: a field left out of `==` would make its instance equal.
      const variants = <CoreMockupFoldableStyle>[
        CoreMockupFoldableStyle(
          innerDeviceStyle: CoreMockupDeviceStyle(railWidth: 1),
        ),
        CoreMockupFoldableStyle(
          coverDeviceStyle: CoreMockupDeviceStyle(railWidth: 1),
        ),
        CoreMockupFoldableStyle(thickness: 1),
        CoreMockupFoldableStyle(perspective: 1),
        CoreMockupFoldableStyle(edgeColor: _kEdge),
        CoreMockupFoldableStyle(screenOffColor: _kEdge),
        CoreMockupFoldableStyle(shadeColor: _kEdge),
        CoreMockupFoldableStyle(shadeOpacity: 1),
        CoreMockupFoldableStyle(islandWidth: 1),
        CoreMockupFoldableStyle(islandOffset: 1),
        CoreMockupFoldableStyle(islandCameraSize: 1),
        CoreMockupFoldableStyle(islandCameraColor: _kEdge),
        CoreMockupFoldableStyle(
          islandTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
        ),
        CoreMockupFoldableStyle(islandIconColor: _kEdge),
        CoreMockupFoldableStyle(islandDotColor: _kEdge),
        CoreMockupFoldableStyle(duration: Duration.zero),
        CoreMockupFoldableStyle(curve: CoreEasing.linear),
      ];

      for (final variant in variants) {
        expect(variant, isNot(base));
        expect(variant.hashCode, isNot(base.hashCode));
        expect(variant, variant.copyWith());
      }
      expect(variants.toSet(), hasLength(variants.length));
    });

    test('the fold runs within the transition tier', () {
      // Longer, and the reduced-motion setting would leave it running.
      expect(
        CoreReducedMotion.isTransitionMotion(
          CoreMockupFoldableStyle.defaultDuration,
        ),
        isTrue,
      );
    });
  });

  group('CoreMockupFoldableTheme', () {
    test('== follows the style', () {
      const a = CoreMockupFoldableTheme(
        style: CoreMockupFoldableStyle(thickness: 9),
      );
      const b = CoreMockupFoldableTheme(
        style: CoreMockupFoldableStyle(thickness: 9),
      );
      const c = CoreMockupFoldableTheme(
        style: CoreMockupFoldableStyle(thickness: 10),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('rides CoreComponentTheme', () {
      const theme = CoreMockupFoldableTheme(
        style: CoreMockupFoldableStyle(thickness: 9),
      );
      const component = CoreComponentTheme(mockupFoldable: theme);

      expect(component.mockupFoldable, theme);
      expect(component.copyWith().mockupFoldable, theme);
      expect(
        const CoreComponentTheme().mergeWith(component).mockupFoldable,
        theme,
      );
      expect(component, isNot(const CoreComponentTheme()));
    });
  });

  group('CoreMockupFoldableLayout', () {
    final tablet =
        CoreMockupDeviceStyle.defaultsByDevice[CoreMockupDevice.tablet]!;
    final phone =
        CoreMockupDeviceStyle.defaultsByDevice[CoreMockupDevice.phone]!;

    test('the open body is the tablet on its side', () {
      final layout = _layout();
      final inset = CoreMockupDeviceStyle.defaultRailWidth + tablet.bezelWidth!;
      final screenWidth = CoreMockupFoldableStyle.defaultWidth - inset * 2;
      // The tablet's screen is 299 : 433; on its side the long side runs
      // across.
      final screenHeight = screenWidth * 299 / 433;

      expect(layout.width, CoreMockupFoldableStyle.defaultWidth);
      expect(layout.innerScreen.left, inset);
      expect(layout.innerScreen.top, inset);
      expect(layout.innerScreen.width, closeTo(screenWidth, 1e-9));
      expect(layout.innerScreen.height, closeTo(screenHeight, 1e-9));
      expect(layout.height, closeTo(screenHeight + inset * 2, 1e-9));
      expect(layout.hingeX, layout.width / 2);
    });

    test('the cover is half the open body wide and as tall', () {
      final layout = _layout();
      final inset = CoreMockupDeviceStyle.defaultRailWidth + phone.bezelWidth!;

      expect(layout.coverWidth, layout.width / 2);
      expect(layout.coverScreen.left, inset);
      expect(
        layout.coverScreen.width + inset * 2,
        closeTo(layout.coverWidth, 1e-9),
      );
      expect(
        layout.coverScreen.height + inset * 2,
        closeTo(layout.height, 1e-9),
      );
      // The proportions handed to the cover's device are that screen box,
      // so the body it derives is the half body.
      expect(
        layout.coverDeviceStyle.screenAspectWidth,
        layout.coverScreen.width,
      );
      expect(
        layout.coverDeviceStyle.screenAspectHeight,
        layout.coverScreen.height,
      );
      // Upright: taller than wide, or the device would read it turned.
      expect(layout.coverScreen.height, greaterThan(layout.coverScreen.width));
    });

    test('the cover keeps the body corners outside and is cut straight at '
        'the hinge', () {
      final layout = _layout();
      final body = layout.innerDeviceStyle.borderRadius!;
      final radius = layout.coverDeviceStyle.borderRadius!;

      expect(radius.topLeft, 0);
      expect(radius.bottomLeft, 0);
      expect(radius.topRight, body.topRight);
      expect(radius.bottomRight, body.bottomRight);
    });

    test("a caller's body colour on either face is the body's colour", () {
      // A stated gradient would win over it; the defaults state none.
      for (final defaults in [
        CoreMockupFoldableStyle.defaultInnerDeviceStyle,
        CoreMockupFoldableStyle.defaultCoverDeviceStyle,
      ]) {
        final face = defaults.merge(
          const CoreMockupDeviceStyle(railColor: _kEdge),
        );

        expect(face.railColor, _kEdge);
        expect(
          CoreMockupDeviceStyle.resolveBodyGradient(
            railColor: face.railColor,
            railGradient: face.railGradient,
          ),
          isNull,
        );
      }
    });

    test('the body is rounder than the tablet it is drawn as', () {
      final body = _layout().innerDeviceStyle.borderRadius!;

      expect(body, const CoreBorderRadius.all(CoreRadius.radius36));
      expect(body.topLeft, greaterThan(tablet.borderRadius!.topLeft));
    });

    test('each face states the values the fold depends on', () {
      final layout = _layout();

      expect(
        layout.innerDeviceStyle.railWidth,
        CoreMockupDeviceStyle.defaultRailWidth,
      );
      expect(layout.innerDeviceStyle.bezelWidth, tablet.bezelWidth);
      expect(
        layout.innerDeviceStyle.borderRadius,
        CoreMockupFoldableStyle.defaultInnerDeviceStyle.borderRadius,
      );
      expect(
        layout.coverDeviceStyle.railWidth,
        CoreMockupDeviceStyle.defaultRailWidth,
      );
      expect(layout.coverDeviceStyle.bezelWidth, phone.bezelWidth);
      // The scale each face draws its system lengths at — the one its
      // island is laid out by — is stated back, so a device theme cannot
      // move the face's bars without its island.
      expect(
        layout.innerDeviceStyle.landscapeSystemBarReferenceScale,
        layout.innerSystemScale,
      );
      expect(
        layout.coverDeviceStyle.systemBarReferenceScale,
        layout.coverSystemScale,
      );
    });

    test("a caller's nested values move the geometry with them", () {
      final layout = _layout(
        inner: const CoreMockupDeviceStyle(railWidth: 0, bezelWidth: 20),
        cover: const CoreMockupDeviceStyle(
          bezelWidth: 10,
          borderRadius: CoreBorderRadius.all(4),
        ),
      );

      expect(layout.innerScreen.left, 20);
      expect(
        layout.coverScreen.left,
        CoreMockupDeviceStyle.defaultRailWidth + 10,
      );
      expect(
        layout.coverDeviceStyle.borderRadius,
        const CoreBorderRadius.all(4),
      );
      // Still half the body wide and as tall.
      expect(
        layout.coverScreen.height +
            (CoreMockupDeviceStyle.defaultRailWidth + 10) * 2,
        closeTo(layout.height, 1e-9),
      );
    });

    test('the screens round concentrically with their bodies', () {
      final layout = _layout();
      final innerInset = layout.innerScreen.left;
      final coverInset = layout.coverScreen.left;
      final body = layout.innerDeviceStyle.borderRadius!;

      expect(layout.innerScreenBorderRadius.topLeft, body.topLeft - innerInset);
      expect(
        layout.coverScreenBorderRadius.topRight,
        body.topRight - coverInset,
      );
      // The cover's hinge side is square all the way in.
      expect(layout.coverScreenBorderRadius.topLeft, 0);
    });

    test('the app on the inner screen reads one fold down its middle', () {
      final layout = _layout();
      final halfOpen = layout.foldLayoutAt(CoreMockupFold.halfOpen);
      final flat = layout.foldLayoutAt(CoreMockupFold.flat);

      expect(halfOpen.width, layout.innerScreen.width);
      expect(halfOpen.height, layout.innerScreen.height);
      expect(halfOpen.kind, CoreFoldableKind.fold);
      expect(halfOpen.posture, CoreFoldPosture.book);
      expect(halfOpen.isSplit, isTrue);
      expect(halfOpen.segments, hasLength(2));
      expect(halfOpen.segments.first.width, layout.innerScreen.width / 2);

      // Flat, a fold with no width leaves one surface.
      expect(flat.posture, CoreFoldPosture.flat);
      expect(flat.isSplit, isFalse);
      expect(flat.segments, hasLength(1));
    });

    test('the app on the cover reads a screen with no fold', () {
      final layout = _layout();
      final closed = layout.foldLayoutAt(CoreMockupFold.closed);

      expect(closed.width, layout.coverScreen.width);
      expect(closed.height, layout.coverScreen.height);
      expect(closed.fold, isNull);
      expect(closed.posture, isNull);
      expect(closed.segments, hasLength(1));
    });

    test('the default system scale is the one the default body stands for a '
        '958-point screen at', () {
      final layout = _layout();

      expect(
        layout.innerScreen.width / 958,
        closeTo(CoreMockupFoldableStyle.defaultSystemScale, 5e-4),
      );
      expect(
        layout.innerSystemScale,
        CoreMockupFoldableStyle.defaultSystemScale,
      );
      expect(
        layout.coverSystemScale,
        CoreMockupFoldableStyle.defaultSystemScale,
      );
    });

    test('poseAt draws the layout at the scale it is given', () {
      final layout = _layout();
      const scale = 1.25;
      final pose = layout.poseAt(CoreMockupFold.flat, scale: scale);
      final far = CoreMockupFoldPose.project(
        pose.innerRight.matrix,
        layout.width * scale,
        layout.height * scale,
      );

      expect(far.x, closeTo(layout.width * scale, 1e-6));
      expect(far.y, closeTo(layout.height * scale, 1e-6));
    });
  });

  group('CoreMockupFoldableLayout — the status island', () {
    // Written out by hand from the lengths in iOS points and the default
    // scale (0.478), so the layout and this table cannot be wrong together.
    //   column 96 → 45.888 · offset 30 → 14.34 · camera 36 → 17.208
    //   camera gap 16 · clock 22 → 10.516 · clock gap 6 · indicator 42 →
    //   20.076
    const column = 45.888;

    test('the inner screen: the clock, then the indicator, no camera', () {
      final layout = _layout();
      final island = layout.islandOf(
        CoreMockupFoldScreen.inner,
        showCamera: true,
        showStatus: true,
      )!;
      final left = layout.innerScreen.width - column;

      expect(island.scale, 0.478);
      expect(island.camera, isNull);
      expect(island.column.left, closeTo(left, 1e-9));
      expect(island.column.top, 0);
      expect(island.column.width, closeTo(column, 1e-9));
      expect(island.column.height, layout.innerScreen.height);
      expect(island.clock!.left, closeTo(left, 1e-9));
      expect(island.clock!.top, closeTo(14.34, 1e-9));
      expect(island.clock!.width, closeTo(column, 1e-9));
      expect(island.clock!.height, closeTo(10.516, 1e-9));
      // (30 + 22 + 6) × 0.478
      expect(island.indicator!.top, closeTo(27.724, 1e-9));
      expect(island.indicator!.width, closeTo(20.076, 1e-9));
      expect(island.indicator!.height, closeTo(20.076, 1e-9));
      expect(
        island.indicator!.left,
        closeTo(left + (column - 20.076) / 2, 1e-9),
      );
    });

    test('the cover: the camera at the top of the column, at the right edge '
        'of the screen', () {
      final layout = _layout();
      final island = layout.islandOf(
        CoreMockupFoldScreen.cover,
        showCamera: true,
        showStatus: true,
      )!;
      final left = layout.coverScreen.width - column;
      final camera = island.camera!;

      expect(camera.top, closeTo(14.34, 1e-9));
      expect(camera.width, closeTo(17.208, 1e-9));
      expect(camera.height, closeTo(17.208, 1e-9));
      expect(camera.left, closeTo(left + (column - 17.208) / 2, 1e-9));
      // In the right half of the screen, hard against its edge — not in the
      // middle, where a slab phone has it.
      expect(camera.left, greaterThan(layout.coverScreen.width / 2));
      expect(
        layout.coverScreen.width - (camera.left + camera.width),
        closeTo((column - 17.208) / 2, 1e-9),
      );
      // (30 + 36 + 16) × 0.478, then + (22 + 6) × 0.478
      expect(island.clock!.top, closeTo(39.196, 1e-9));
      expect(island.indicator!.top, closeTo(52.58, 1e-9));
    });

    test('without its camera the cover starts with the clock', () {
      final island = _layout().islandOf(
        CoreMockupFoldScreen.cover,
        showCamera: false,
        showStatus: true,
      )!;

      expect(island.camera, isNull);
      expect(island.clock!.top, closeTo(14.34, 1e-9));
    });

    test('without the status the cover keeps its camera and the inner '
        'screen has no island', () {
      final layout = _layout();
      final cover = layout.islandOf(
        CoreMockupFoldScreen.cover,
        showCamera: true,
        showStatus: false,
      )!;

      expect(cover.camera, isNotNull);
      expect(cover.clock, isNull);
      expect(cover.indicator, isNull);
      expect(cover.column.width, closeTo(column, 1e-9));
      expect(
        layout.islandOf(
          CoreMockupFoldScreen.inner,
          showCamera: true,
          showStatus: false,
        ),
        isNull,
      );
      expect(
        layout.islandOf(
          CoreMockupFoldScreen.cover,
          showCamera: false,
          showStatus: false,
        ),
        isNull,
      );
    });

    test('the parts stand in the column, top to bottom, without touching', () {
      for (final layout in [
        _layout(),
        _layout(width: 960),
        _layout(islandWidth: 60, islandOffset: 10),
        _layout(islandCameraSize: 50),
      ]) {
        for (final screen in CoreMockupFoldScreen.values) {
          final island = layout.islandOf(
            screen,
            showCamera: true,
            showStatus: true,
          )!;
          final parts = [
            island.camera,
            island.clock,
            island.indicator,
          ].nonNulls.toList();
          final right = island.column.left + island.column.width;

          for (var i = 0; i < parts.length; i++) {
            final part = parts[i];
            // Centred across the column.
            expect(
              part.left + part.width / 2,
              closeTo(island.column.left + island.column.width / 2, 1e-9),
            );
            expect(part.left, greaterThanOrEqualTo(island.column.left - 1e-9));
            expect(part.left + part.width, lessThanOrEqualTo(right + 1e-9));
            if (i > 0) {
              final above = parts[i - 1];
              expect(part.top, greaterThan(above.top + above.height));
            }
          }
        }
      }
    });

    test('a wider device is a larger screen, not a larger island', () {
      final narrow = _layout().islandOf(
        CoreMockupFoldScreen.inner,
        showCamera: true,
        showStatus: true,
      )!;
      final wide = _layout(width: 960).islandOf(
        CoreMockupFoldScreen.inner,
        showCamera: true,
        showStatus: true,
      )!;

      expect(wide.column.width, narrow.column.width);
      expect(wide.indicator!.width, narrow.indicator!.width);
      expect(wide.clock!.top, narrow.clock!.top);
    });

    test("the island follows its own face's system scale", () {
      final layout = _layout(
        inner: CoreMockupFoldableStyle.defaultInnerDeviceStyle.merge(
          const CoreMockupDeviceStyle(landscapeSystemBarReferenceScale: 1),
        ),
      );
      final inner = layout.islandOf(
        CoreMockupFoldScreen.inner,
        showCamera: true,
        showStatus: true,
      )!;
      final cover = layout.islandOf(
        CoreMockupFoldScreen.cover,
        showCamera: true,
        showStatus: true,
      )!;

      expect(inner.scale, 1);
      expect(inner.column.width, CoreMockupFoldableStyle.defaultIslandWidth);
      expect(inner.clock!.top, CoreMockupFoldableStyle.defaultIslandOffset);
      // The cover is another device: it keeps its own.
      expect(cover.scale, CoreMockupFoldableStyle.defaultSystemScale);
    });

    test('the column is never wider than its screen', () {
      final layout = _layout(islandWidth: 5000);
      final island = layout.islandOf(
        CoreMockupFoldScreen.cover,
        showCamera: true,
        showStatus: true,
      )!;

      expect(island.column.left, 0);
      expect(island.column.width, layout.coverScreen.width);
    });
  });

  group('CoreMockupFoldableGlyphs', () {
    test('both drawings are written in the four glyph commands', () {
      expect(_isGlyphPath(CoreMockupFoldableGlyphs.statusRing.path), isTrue);
      expect(_isGlyphPath(CoreMockupFoldableGlyphs.statusDots.path), isTrue);
    });

    test('both are drawn in the same box, the one the layout sizes', () {
      const box = CoreMockupFoldableGlyphs.statusBox;

      for (final glyph in [
        CoreMockupFoldableStyle.islandRingGlyph,
        CoreMockupFoldableStyle.islandDotsGlyph,
      ]) {
        expect(glyph.width, box);
        expect(glyph.height, box);
      }
      expect(CoreMockupFoldableStyle.islandIndicatorSize, box);
    });

    test('the dots are four shapes; the ring carries the wifi glyph', () {
      int shapes(CoreVectorGlyph glyph) =>
          glyph.path.split(' ').where((t) => t == 'M').length;

      expect(shapes(CoreMockupFoldableGlyphs.statusDots), 4);
      // One outline for the ring, then the phone wifi glyph's own.
      expect(
        shapes(CoreMockupFoldableGlyphs.statusRing),
        1 + shapes(CoreMockupStatusBarGlyphs.phoneWifi),
      );
      expect(
        CoreMockupFoldableGlyphs.statusRing.fillRule,
        CoreMockupStatusBarGlyphs.phoneWifi.fillRule,
      );
    });

    test('the dots sit in the opening the ring leaves at the bottom', () {
      // The ring's outline starts at its right end: the first point is the
      // lowest the ring reaches on that side.
      final ring = CoreMockupFoldableGlyphs.statusRing.path.split(' ');
      final ringEndY = double.parse(ring[2]);
      final dots = CoreMockupFoldableGlyphs.statusDots.path.split(' ');
      final dotYs = [
        for (var i = 0; i < dots.length; i++)
          if (dots[i] == 'M') double.parse(dots[i + 2]),
      ];

      for (final y in dotYs) {
        expect(y, greaterThan(ringEndY));
        expect(y, lessThanOrEqualTo(CoreMockupFoldableGlyphs.statusBox));
      }
    });
  });

  group('CoreMockupFoldableContract', () {
    test('by default the device shows its camera and status and no home '
        'bar', () {
      expect(CoreMockupFoldableContract.defaultShowCamera, isTrue);
      expect(CoreMockupFoldableContract.defaultShowStatus, isTrue);
      expect(CoreMockupFoldableContract.defaultShowGestureBar, isFalse);
      expect(
        CoreMockupFoldableStyle.sampleTime,
        CoreMockupDeviceStyle.sampleTime,
      );
    });
  });
}
