import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Room around the outline so the ring paints inside the captured
/// boundary rather than being clipped off its edge.
const double _kPad = 20;

/// Bytes per pixel in the captured `rawRgba` buffer.
const int _kStride = 4;

/// Index of the alpha channel within one `rawRgba` pixel.
const int _kAlpha = 3;

/// A non-square child. A circle decoration sizes itself from the
/// shortest side of its rect, so this is the width at which "circle"
/// stops meaning "a ring around the child".
const Size _kWide = Size(100, 40);

/// A square child — the shape at which a pill radius and a circle
/// decoration agree, so a difference here can only come from the radius
/// field.
const Size _kSquare = Size(40, 40);

const CoreFocusOutlineStyle _kRadius4 = CoreFocusOutlineStyle(
  circleBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
);

final GlobalKey _boundaryKey = GlobalKey(debugLabel: 'boundary');
final GlobalKey _childKey = GlobalKey(debugLabel: 'child');

/// One rendered frame, read back as pixels.
///
/// The questions these tests ask — does the resolved circle radius reach
/// the screen, and does a circle ring enclose its child — are only
/// answerable in painted output. That is the whole shape of the defect:
/// every layer of the type wiring was correct, the resolver produced a
/// different value for an overridden style, and the pixels came out
/// byte-identical.
class _Shot {
  const _Shot(this.bytes, this.width, this.height, this.child);

  final ByteData bytes;
  final int width;
  final int height;

  /// The child's rect in boundary-local coordinates.
  final Rect child;

  int alphaAt(int x, int y) =>
      bytes.getUint8((((y * width) + x) * _kStride) + _kAlpha);

  /// Columns on row [y] where anything at all was painted.
  List<int> paintedColumns(int y) => [
    for (var x = 0; x < width; x++)
      if (alphaAt(x, y) > 0) x,
  ];

  /// How many pixels differ from [other]. Zero is the reproduction.
  int differingPixels(_Shot other) {
    final mine = bytes.buffer.asUint8List();
    final theirs = other.bytes.buffer.asUint8List();
    if (mine.length != theirs.length) return mine.length;

    var count = 0;
    for (var i = 0; i < mine.length; i += _kStride) {
      for (var channel = 0; channel < _kStride; channel++) {
        if (mine[i + channel] != theirs[i + channel]) {
          count++;
          break;
        }
      }
    }

    return count;
  }
}

Widget _harness({
  required CoreFocusOutlineShape shape,
  required Size childSize,
  CoreFocusOutlineStyle? style,
  void Function(BuildContext context)? probe,
}) {
  return Directionality(
    textDirection: .ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Theme(
        data: const ThemeData(),
        child: Builder(
          builder: (context) {
            probe?.call(context);

            return Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: Padding(
                  padding: const .all(_kPad),
                  child: FocusOutline(
                    focused: true,
                    shape: shape,
                    focusOutlineStyle: style,
                    child: SizedBox(
                      key: _childKey,
                      width: childSize.width,
                      height: childSize.height,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

Future<_Shot> _shoot(
  WidgetTester tester, {
  required CoreFocusOutlineShape shape,
  required Size childSize,
  CoreFocusOutlineStyle? style,
}) async {
  await tester.pumpWidget(
    _harness(shape: shape, childSize: childSize, style: style),
  );
  final _ = await tester.pumpAndSettle();

  final boundaryRect = tester.getRect(find.byKey(_boundaryKey));
  final childRect = tester.getRect(find.byKey(_childKey));
  final render =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  late ByteData bytes;
  late int width;
  late int height;
  await tester.runAsync(() async {
    final image = await render.toImage();
    width = image.width;
    height = image.height;
    bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    image.dispose();
  });

  return _Shot(bytes, width, height, childRect.shift(-boundaryRect.topLeft));
}

/// Every `BoxDecoration` the outline paints — the border ring. The gap
/// band is a shape stroke, read by [_bands].
List<BoxDecoration> _decorations(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(FocusOutline),
        matching: find.byType(Container),
      ),
    )
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .toList();

/// The gap band's stroke shape, when the outline renders one.
List<RoundedRectangleBorder> _bands(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(FocusOutline),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((d) => d.decoration)
    .whereType<ShapeDecoration>()
    .map((d) => d.shape)
    .whereType<RoundedRectangleBorder>()
    .toList();

/// The radius the widget must paint for a ring sitting [add] px outside
/// a child whose own corner radius is [base] — the outer corner has to
/// be rounder by exactly the distance it stands off.
///
/// Only ever fed a round corner here. A square one stays square, which
/// is a different claim and has its own test below.
BorderRadius _plus(BorderRadiusGeometry base, double add) {
  final resolved = base.resolve(.ltr);
  final grow = Radius.circular(add);

  return BorderRadius.only(
    topLeft: resolved.topLeft + grow,
    topRight: resolved.topRight + grow,
    bottomLeft: resolved.bottomLeft + grow,
    bottomRight: resolved.bottomRight + grow,
  );
}

void main() {
  group('FocusOutline circle radius reaches paint', () {
    testWidgets('the ring paints exactly the radius the resolver produced', (
      tester,
    ) async {
      // The offset band only renders when `offsetColor` is set, so ask
      // for it — otherwise only one of the two shape branches is under
      // test and the other stays free to regress.
      final style = _kRadius4.copyWith(
        offsetColor: const CoreColor.token(CoreColors.surface),
      );
      late ResolvedFocusOutline resolved;
      await tester.pumpWidget(
        _harness(
          shape: .circle,
          childSize: _kSquare,
          style: style,
          probe: (context) =>
              resolved = resolveFocusOutline(context, widgetStyle: style),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final decorations = _decorations(tester);
      final offsetBand = _bands(tester).single;
      final ring = decorations.firstWhere((d) => d.border != null);
      final offsetExtent = resolved.align - resolved.borderWidth;

      expect(
        ring.borderRadius,
        equals(_plus(resolved.circleBorderRadius, resolved.align)),
        reason:
            'the ring layer must paint the resolved circleBorderRadius. '
            'Before this fix it painted null and let the circle '
            'decoration derive its own geometry, so the resolved value '
            'reached nothing.',
      );
      expect(
        offsetBand.borderRadius,
        equals(_plus(resolved.circleBorderRadius, offsetExtent)),
        reason:
            'the offset (gap) band is the second branch on the same '
            'condition — the issue quoted only the ring layer, and '
            'fixing one leaves the other dead.',
      );

      for (final decoration in decorations) {
        expect(
          decoration.shape,
          equals(BoxShape.rectangle),
          reason:
              'a circle decoration ignores borderRadius outright, so any '
              'layer that keeps one cannot honour the field no matter '
              'what the resolver produced.',
        );
      }
    });

    testWidgets('overriding circleBorderRadius changes what is painted', (
      tester,
    ) async {
      final base = await _shoot(
        tester,
        shape: .circle,
        childSize: _kSquare,
      );
      final overridden = await _shoot(
        tester,
        shape: .circle,
        childSize: _kSquare,
        style: _kRadius4,
      );

      expect(
        base.differingPixels(overridden),
        greaterThan(0),
        reason:
            'this count was exactly 0 on Flutter — for a 40x40 and a '
            '100x40 child alike — while the same override moved Web from '
            'the pill radius token to the radius-4 one. A one-platform '
            'gap, which is what the issue reported.',
      );
    });

    testWidgets('a circle ring encloses a non-square child', (tester) async {
      final shot = await _shoot(tester, shape: .circle, childSize: _kWide);

      final painted = shot.paintedColumns(shot.child.center.dy.round());

      expect(
        painted,
        isNotEmpty,
        reason: 'a focused ring has to paint something',
      );
      expect(
        painted.first,
        lessThan(shot.child.left),
        reason:
            'a circle decoration takes its diameter from the shortest '
            'side of its rect and centres it, so a circle ring around a '
            '100x40 child drew a 48px disc floating inside the child '
            'instead of a ring around it. The ring must start outside '
            'the child edge.',
      );
      expect(
        painted.last,
        greaterThan(shot.child.right),
        reason: 'and it must end outside the opposite edge.',
      );
    });

    testWidgets('a preset that caps corners keeps the circle ring capped', (
      tester,
    ) async {
      // The circle radius rides the same corner ladder every other
      // radius does, so a preset that caps radii small must hand this
      // branch a capped radius too — not the all-9999 default's raw
      // sentinel value. Standing the ring off its child (`align`/
      // `offsetExtent` below) is a separate, legitimate growth on top
      // of that capped base — a ring drawn *outside* a small-radius
      // child legitimately needs a slightly larger outer radius to
      // stay a consistent ring, so the painted corners are not the raw
      // cap itself, they are the cap plus that growth. What the theme
      // must not do is leak the pre-cap all-9999 sentinel through
      // (`theme.geometry.radius()`'s pill-preservation branch, which
      // Range/Badge rely on to stay round, also matches this field's
      // *default* — a circle ring is not a pill stating its own
      // roundness, so the resolver must clamp back down; see
      // `focus_outline_style.dart`).
      //
      // Neo-brutalism's cap is `CoreRadius.radius6` today, not zero —
      // read from `theme.geometry.radiusCap` rather than hardcoded, so
      // this stays true if the shipped recipe's cap value ever moves
      // again (`radiusCap: 0` absolute-squaring is a synthetic-only
      // case covered separately in `surface_radius_range_test.dart`,
      // not what any shipped preset states).
      final style = CoreFocusOutlineStyle(
        offsetColor: const CoreColor.token(CoreColors.surface),
      );
      late ResolvedFocusOutline resolved;
      late double radiusCap;
      late double scaling;
      final home = Center(
        child: Builder(
          builder: (context) {
            resolved = resolveFocusOutline(context, widgetStyle: style);
            radiusCap = Theme.of(context).geometry.radiusCap!;
            scaling = Theme.of(context).scaling;
            return FocusOutline(
              focused: true,
              shape: .circle,
              focusOutlineStyle: style,
              child: const SizedBox(width: 40, height: 40),
            );
          },
        ),
      );
      await tester.pumpWidget(
        CoUIApp(
          surfaceStyle: .neoBrutalism,
          home: home,
          theme: ThemeData.fromCore(CoreThemePresets.light),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // The resolver's own output must respect the cap — this is the
      // regression this test exists to catch. `resolved.circleBorderRadius`
      // is already `* scaling` (`resolver/scaling-and-gap.md`), so the
      // bound is the cap scaled the same way, not the raw token.
      final resolvedCorners = resolved.circleBorderRadius.resolve(.ltr);
      final cappedBound = radiusCap * scaling;
      expect(
        [
          resolvedCorners.topLeft.x,
          resolvedCorners.topRight.x,
          resolvedCorners.bottomLeft.x,
          resolvedCorners.bottomRight.x,
        ],
        everyElement(lessThanOrEqualTo(cappedBound)),
        reason:
            'the resolver leaked the pre-cap sentinel through instead of '
            'clamping to the theme cap: ${resolved.circleBorderRadius}',
      );

      // And the widget must paint exactly what the resolver produced,
      // standoff-grown — the same contract test #1 above checks for a
      // non-capping style, checked again here because this is a
      // different preset exercising a different resolver branch.
      final offsetExtent = resolved.align - resolved.borderWidth;
      final decorations = _decorations(tester);
      final ring = decorations.firstWhere((d) => d.border != null);
      expect(
        ring.borderRadius,
        equals(_plus(resolved.circleBorderRadius, resolved.align)),
        reason: 'the ring layer must paint the capped resolved radius.',
      );
      // The preset's stroke floor can widen the ring until it fills
      // `align`, leaving no gap to paint. A band then has nowhere to go —
      // a zero-width stroke would be a hairline, not nothing — so the
      // outline drops it rather than drawing one.
      if (offsetExtent > 0) {
        expect(
          _bands(tester).single.borderRadius,
          equals(_plus(resolved.circleBorderRadius, offsetExtent)),
          reason: 'the offset band must paint the capped resolved radius too.',
        );
      } else {
        expect(
          _bands(tester),
          isEmpty,
          reason: 'a collapsed gap draws no band layer at all.',
        );
      }
    });

    testWidgets('the rectangle branch ignores the circle radius field', (
      tester,
    ) async {
      final base = await _shoot(
        tester,
        shape: .rectangle,
        childSize: _kWide,
      );
      final withCircleOverride = await _shoot(
        tester,
        shape: .rectangle,
        childSize: _kWide,
        style: _kRadius4,
      );

      expect(
        base.differingPixels(withCircleOverride),
        equals(0),
        reason:
            'the two radius fields are mutually exclusive by shape — a '
            'rectangle taking a circle radius would be the bug, not the '
            'fix.',
      );
    });
  });
}
