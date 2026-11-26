// `shape` picks the outline a chip is drawn in, beside its `size`:
// `rounded` keeps the size row's corner (6 · 8 · 10) and is the default,
// `pill` draws both ends as a half circle on every size.
//
// Two things have to hold, and only one of them is about the new option.
// The other is that adding it changed nothing — `rounded` is what every chip
// already rendered.
//
// The pill is the full corner (9999), never a half-height a resolver works
// out, so the half circle only exists once the painter clamps that corner
// to the box. Reading the resolver says the clamp was asked for; only the
// pixel tests below show it happened — on the face, on the focus ring and
// on the cast that a style throws beneath it.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kPill = CoreBorderRadius.all(CoreRadius.radius9999);

const _kRadius4 = CoreBorderRadius.all(CoreRadius.radius4);

/// The size rows' own corners, written out so a change to the ladder fails
/// here rather than moving implementation and expectation together.
const Map<CoreChipSize, double> _kRowCorner = {
  CoreChipSize.sm: 6.0,
  CoreChipSize.md: 8.0,
  CoreChipSize.lg: 10.0,
};

/// The size rows' height floors — a pill is no taller than a rounded chip.
const Map<CoreChipSize, double> _kFloor = {
  CoreChipSize.sm: 28.0,
  CoreChipSize.md: 32.0,
  CoreChipSize.lg: 40.0,
};

/// Room around the chip so a ring or a cast paints inside the captured
/// boundary rather than being clipped off its edge.
const double _kPad = 20;

/// Bytes per pixel in the captured `rawRgba` buffer.
const int _kStride = 4;

/// Index of the alpha channel within one `rawRgba` pixel.
const int _kAlpha = 3;

/// Rows skipped at the top and bottom of a measured box. There the edge
/// runs almost level, so a pixel's coverage stops tracking where the edge
/// crosses the row's centre line.
const int _kFlatRows = 2;

final GlobalKey _boundaryKey = GlobalKey(debugLabel: 'boundary');

/// Resolves a chip under the default theme.
Future<ResolvedChip> _resolve(
  WidgetTester tester, {
  required CoreChipSize size,
  required CoreChipShape shape,
  CoreChipStyle? chipStyle,
  CoreChipTheme? chipTheme,
}) async {
  late ResolvedChip resolved;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: ThemeData(
          coreComponentTheme: CoreComponentTheme(chip: chipTheme),
        ),
        child: Builder(
          builder: (context) {
            resolved = resolveChip(
              context,
              chipColor: CoreChipColor.neutral,
              variant: CoreChipVariant.outlined,
              emphasis: CoreChipEmphasis.high,
              size: size,
              shape: shape,
              selected: false,
              enabled: true,
              chipStyle: chipStyle,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return resolved;
}

/// Pumps [chip] in the shared test harness, from a cleared tree — the
/// harness mounts its child as an overlay entry, which a second
/// `pumpWidget` in the same test would not rebuild.
Future<void> _pump(
  WidgetTester tester,
  Widget chip, {
  CoreComponentTheme? componentTheme,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(tester, chip, componentTheme: componentTheme);
}

/// The chip's face — the composed `OutlinedContainer`.
Finder _face() => find.descendant(
  of: find.byType(Chip),
  matching: find.byType(OutlinedContainer),
);

/// The corner the face's decoration hands the painter. `OutlinedContainer`
/// nests two `AnimatedContainer`s — the outer one carries the fill, the
/// border and the corner.
BorderRadius _paintedCorner(WidgetTester tester) {
  final decoration =
      tester
              .widgetList<AnimatedContainer>(
                find.descendant(
                  of: _face(),
                  matching: find.byType(AnimatedContainer),
                ),
              )
              .first
              .decoration!
          as BoxDecoration;
  return decoration.borderRadius! as BorderRadius;
}

/// The ring `FocusOutline` paints around a tappable chip — the outermost
/// bordered box under it. The face's own containers sit inside the ring.
Container _ring(WidgetTester tester) {
  final containers = tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(FocusOutline),
          matching: find.byType(Container),
        ),
      )
      .where(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).border != null,
      )
      .toList();
  Size sizeOf(Container c) => tester.getSize(find.byWidget(c));
  containers.sort((a, b) => sizeOf(b).width.compareTo(sizeOf(a).width));
  return containers.first;
}

/// Moves keyboard focus onto the chip and lets the ring finish fading in.
///
/// `Chip` exposes no `focusNode` — `Clickable` hands its own to
/// `FocusableActionDetector`. A real key event is what flips the focus
/// highlight mode to `.traditional`; `requestFocus()` alone would leave
/// the ring hidden (`chip_state_layer_engage_test.dart` documents the
/// same trap).
Future<void> _focusChip(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
  tester
      .widget<FocusableActionDetector>(find.byType(FocusableActionDetector))
      .focusNode!
      .requestFocus();
  await tester.pump();
  await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
}

/// A bare tree with a transparent background, so a painted pixel can only
/// be the chip's own.
Widget _bare(
  Widget chip, {
  CoreSurfaceStyleId surfaceStyle = .defaultId,
}) {
  return Directionality(
    textDirection: .ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Theme(
        // A resolved palette — a surface style bends the scheme's colours,
        // which the token-only default `ThemeData` cannot hand it.
        data: applySurfaceStyle(
          ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: surfaceStyle,
          highContrast: false,
        ),
        child: SurfaceStyleScope(
          surfaceStyle: surfaceStyle,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Padding(padding: const .all(_kPad), child: chip),
            ),
          ),
        ),
      ),
    ),
  );
}

/// One rendered frame of the [_bare] boundary, read back as pixels.
class _Shot {
  const _Shot(this.bytes, this.width, this.origin);

  final ByteData bytes;
  final int width;

  /// The boundary's top-left in global coordinates.
  final Offset origin;

  int alphaAt(int x, int y) =>
      bytes.getUint8((((y * width) + x) * _kStride) + _kAlpha);

  /// The first and last columns on row [y] at least half covered.
  (int, int)? span(int y) {
    int? first;
    int? last;
    for (var x = 0; x < width; x++) {
      if (alphaAt(x, y) < 128) continue;
      first ??= x;
      last = x;
    }
    return first == null ? null : (first, last!);
  }

  Rect local(Rect global) => global.shift(-origin);
}

Future<_Shot> _shoot(WidgetTester tester) async {
  final origin = tester.getTopLeft(find.byKey(_boundaryKey));
  final render =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  late ByteData bytes;
  late int width;
  await tester.runAsync(() async {
    final image = await render.toImage();
    width = image.width;
    // `rawRgba` is the default format — [_kStride] / [_kAlpha] read it.
    bytes = (await image.toByteData())!;
    image.dispose();
  });

  return _Shot(bytes, width, origin);
}

/// How far in from the side of a [height]-tall box the outline sits on the
/// centre line of row [y], for a corner of [radius] — clamped to half the
/// height, the way the painter clamps it.
double _inset(int y, double height, double radius) {
  final r = math.min(radius, height / 2);
  final centre = y + 0.5;
  final double dy;
  if (centre < r) {
    dy = r - centre;
  } else if (centre > height - r) {
    dy = centre - (height - r);
  } else {
    dy = 0;
  }
  return r - math.sqrt(math.max(0, (r * r) - (dy * dy)));
}

/// Asserts that every row of [box] (boundary-local) is painted between the
/// two sides of a rounded rect of corner [radius] — the left and right
/// outline, read row by row.
void _expectOutline(_Shot shot, Rect box, double radius, String reason) {
  final top = box.top.round();
  final height = box.height;
  for (var row = _kFlatRows; row < height.round() - _kFlatRows; row++) {
    final inset = _inset(row, height, radius);
    final span = shot.span(top + row);
    expect(span, isNotNull, reason: '$reason: row $row painted nothing');
    final (first, last) = span!;
    expect(
      first,
      closeTo(box.left + inset, 1),
      reason: '$reason: left outline on row $row',
    );
    expect(
      last + 1,
      closeTo(box.right - inset, 1),
      reason: '$reason: right outline on row $row',
    );
  }
}

void main() {
  group('Chip shape — the default', () {
    test('defaults to rounded, the outline every chip already drew', () {
      expect(CoreChipShape.defaultShape, CoreChipShape.rounded);
      expect(const Chip(label: 'Tag').shape, CoreChipShape.rounded);
    });

    test('copyWith carries the shape and can replace it', () {
      const pill = Chip(label: 'Tag', shape: CoreChipShape.pill);
      expect(pill.copyWith(label: 'Other').shape, CoreChipShape.pill);
      expect(
        pill.copyWith(shape: CoreChipShape.rounded).shape,
        CoreChipShape.rounded,
      );
    });

    testWidgets('rounded resolves the size row corner — 6 · 8 · 10', (
      tester,
    ) async {
      for (final size in CoreChipSize.values) {
        final corner = CoreBorderRadius.all(_kRowCorner[size]!);
        final r = await _resolve(
          tester,
          size: size,
          shape: CoreChipShape.rounded,
        );
        // The row is still where the number comes from.
        expect(
          CoreChipStyle.defaultsBySize[size]!.borderRadius,
          corner,
          reason: '${size.name} row',
        );
        expect(r.containerStyle.borderRadius, corner, reason: size.name);
        expect(r.hoverContainerStyle.borderRadius, corner, reason: size.name);
        expect(r.focusContainerStyle.borderRadius, corner, reason: size.name);
        expect(
          r.pressedContainerStyle.borderRadius,
          corner,
          reason: size.name,
        );
        expect(r.castBorderRadius.topLeft.x, _kRowCorner[size]);
        expect(r.clickableStyle.borderRadius, corner, reason: size.name);
      }
    });

    testWidgets('a chip that names no shape paints the row corner', (
      tester,
    ) async {
      for (final size in CoreChipSize.values) {
        await _pump(tester, Chip(label: 'Tag', size: size));
        expect(
          _paintedCorner(tester).topLeft.x,
          _kRowCorner[size],
          reason: size.name,
        );
      }
    });
  });

  group('Chip shape — pill', () {
    testWidgets('resolves the full corner on every size', (tester) async {
      for (final size in CoreChipSize.values) {
        final r = await _resolve(
          tester,
          size: size,
          shape: CoreChipShape.pill,
        );
        expect(r.containerStyle.borderRadius, _kPill, reason: size.name);
        expect(r.hoverContainerStyle.borderRadius, _kPill, reason: size.name);
        expect(r.focusContainerStyle.borderRadius, _kPill, reason: size.name);
        expect(
          r.pressedContainerStyle.borderRadius,
          _kPill,
          reason: size.name,
        );
        expect(r.castBorderRadius.topLeft.x, CoreRadius.radius9999);
        expect(r.clickableStyle.borderRadius, _kPill, reason: size.name);
        // The close button keeps its own row's corner — every one of them
        // is less round than the pill around it.
        expect(
          r.closeButtonStyle?.borderRadius,
          CoreChipStyle.defaultsBySize[size]!.closeButtonStyle?.borderRadius,
          reason: '${size.name} close button',
        );
      }
    });

    testWidgets('the face, the cast and the focus ring are handed the pill', (
      tester,
    ) async {
      for (final size in CoreChipSize.values) {
        await _pump(
          tester,
          Chip(
            label: 'Tag',
            size: size,
            shape: CoreChipShape.pill,
            onTap: () {},
          ),
        );
        expect(
          _paintedCorner(tester).topLeft.x,
          CoreRadius.radius9999,
          reason: '${size.name} face',
        );
        expect(
          tester.widget<InjectedCast>(find.byType(InjectedCast)).borderRadius,
          BorderRadius.circular(CoreRadius.radius9999),
          reason: '${size.name} cast',
        );
        expect(
          tester
              .widget<Clickable>(find.byType(Clickable))
              .clickableStyle
              ?.borderRadius,
          _kPill,
          reason: '${size.name} clickable',
        );
        expect(
          tester
              .widget<FocusOutline>(find.byType(FocusOutline))
              .focusOutlineStyle
              ?.borderRadius,
          _kPill,
          reason: '${size.name} focus ring',
        );
      }
    });

    testWidgets('keeps the height floor — 28 · 32 · 40', (tester) async {
      for (final size in CoreChipSize.values) {
        for (final shape in CoreChipShape.values) {
          await _pump(
            tester,
            Chip(label: 'Tag', size: size, shape: shape, onTap: () {}),
          );
          expect(
            tester.getSize(_face()).height,
            _kFloor[size],
            reason: '${size.name} ${shape.name}',
          );
        }
      }
    });

    testWidgets('paints both ends as half circles on every size', (
      tester,
    ) async {
      for (final size in CoreChipSize.values) {
        for (final shape in CoreChipShape.values) {
          // Selected — an opaque fill, with a border that mirrors it, so
          // every pixel inside the outline is painted.
          await tester.pumpWidget(
            _bare(
              Chip(
                label: 'Tag',
                size: size,
                shape: shape,
                selected: true,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final shot = await _shoot(tester);
          final face = shot.local(tester.getRect(_face()));
          final radius = shape == CoreChipShape.pill
              ? CoreRadius.radius9999
              : _kRowCorner[size]!;
          _expectOutline(shot, face, radius, '${size.name} ${shape.name}');
        }
      }
    });

    testWidgets('the focus ring is a pill around the pill', (tester) async {
      for (final size in CoreChipSize.values) {
        await tester.pumpWidget(
          _bare(
            Chip(
              label: 'Tag',
              size: size,
              shape: CoreChipShape.pill,
              onTap: () {},
            ),
          ),
        );
        await _focusChip(tester);
        expect(tester.takeException(), isNull);
        expect(
          tester.widget<FocusOutline>(find.byType(FocusOutline)).focused,
          isTrue,
          reason: '${size.name}: focus traversal found nothing to land on',
        );

        final ring = _ring(tester);
        // The ring stands off the face, so its corner is the face's grown
        // by the stand-off — still past half its height.
        expect(
          (ring.decoration! as BoxDecoration).borderRadius!
              .resolve(.ltr)
              .topLeft
              .x,
          greaterThan(CoreRadius.radius9999),
          reason: '${size.name} ring corner',
        );

        final shot = await _shoot(tester);
        final ringBox = shot.local(tester.getRect(find.byWidget(ring)));
        expect(
          ringBox.height,
          greaterThan(_kFloor[size]!),
          reason: '${size.name}: the ring sits outside the face',
        );
        _expectOutline(
          shot,
          ringBox,
          CoreRadius.radius9999,
          '${size.name} focus ring',
        );
      }
    });

    testWidgets('a style cast is knocked out by the pill, not its box', (
      tester,
    ) async {
      // Neo-brutalism throws a hard cast under every control and caps
      // corners at 6 — but a full corner is a fixed point of that cap, so
      // the chip stays a pill and the cast's knock-out has to be one too.
      for (final size in CoreChipSize.values) {
        await tester.pumpWidget(
          _bare(
            Chip(
              size: size,
              shape: CoreChipShape.pill,
              // A wide, empty face: an unselected chip has no fill, so the
              // middle of the face shows whatever was painted beneath it.
              child: const SizedBox(width: 48),
            ),
            surfaceStyle: .neoBrutalism,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final cast = tester.widget<InjectedCast>(find.byType(InjectedCast));
        expect(cast.shadows, isNotEmpty, reason: '${size.name}: no cast');
        expect(
          cast.borderRadius,
          BorderRadius.circular(CoreRadius.radius9999),
          reason: '${size.name} cast corner',
        );
        final offset = cast.shadows.first.offset;
        expect(offset.dx, greaterThan(0));
        expect(offset.dy, greaterThan(0));

        final shot = await _shoot(tester);
        final face = shot.local(tester.getRect(_face()));
        final centre = face.center;
        expect(
          shot.alphaAt(centre.dx.floor(), centre.dy.floor()),
          0,
          reason: '${size.name}: the cast shows through the face',
        );
        // Below the face, where only the cast reaches.
        expect(
          shot.alphaAt(centre.dx.floor(), (face.bottom + 1).floor()),
          greaterThan(0),
          reason: '${size.name}: the cast was not painted',
        );
        // Below the left end: inside the face's bounding box shifted by
        // the cast, outside the pill shifted by it.
        expect(
          shot.alphaAt(
            (face.left + offset.dx + 1).floor(),
            (face.bottom + offset.dy - 1).floor(),
          ),
          0,
          reason: '${size.name}: the cast is a box, not a pill',
        );
        // Inside the face's bounding box but outside its right end, and
        // inside the cast beneath it: a knock-out cut to the box rather
        // than to the pill erases the cast here, leaving a notch beside
        // the shadow.
        expect(
          shot.alphaAt((face.right - 3).floor(), (face.bottom - 3).floor()),
          greaterThan(0),
          reason: '${size.name}: the knock-out is the box, not the pill',
        );
      }
    });
  });

  group('Chip shape — a stated corner wins', () {
    testWidgets('over the pill, from the instance', (tester) async {
      final r = await _resolve(
        tester,
        size: CoreChipSize.md,
        shape: CoreChipShape.pill,
        chipStyle: const CoreChipStyle(borderRadius: _kRadius4),
      );
      expect(r.containerStyle.borderRadius, _kRadius4);
      expect(r.hoverContainerStyle.borderRadius, _kRadius4);
      expect(r.castBorderRadius.topLeft.x, CoreRadius.radius4);
      expect(r.clickableStyle.borderRadius, _kRadius4);

      await _pump(
        tester,
        const Chip(
          label: 'Tag',
          shape: CoreChipShape.pill,
          chipStyle: CoreChipStyle(borderRadius: _kRadius4),
        ),
      );
      expect(_paintedCorner(tester).topLeft.x, CoreRadius.radius4);
    });

    testWidgets('over the pill, from the theme', (tester) async {
      const theme = CoreChipTheme(
        style: CoreChipStyle(borderRadius: _kRadius4),
      );
      final r = await _resolve(
        tester,
        size: CoreChipSize.md,
        shape: CoreChipShape.pill,
        chipTheme: theme,
      );
      expect(r.containerStyle.borderRadius, _kRadius4);
      expect(r.castBorderRadius.topLeft.x, CoreRadius.radius4);
      expect(r.clickableStyle.borderRadius, _kRadius4);

      await _pump(
        tester,
        const Chip(label: 'Tag', shape: CoreChipShape.pill),
        componentTheme: const CoreComponentTheme(chip: theme),
      );
      expect(_paintedCorner(tester).topLeft.x, CoreRadius.radius4);
    });
  });
}
