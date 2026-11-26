import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kFrameWidth = 400.0;
const _kHandleSize = 40.0;
const _kHitSize = 44.0;

/// A 400-wide comparison between two flat colours. The aspect ratio is the
/// style default (16 / 9), so the frame is 400 x 225.
Widget _diff({
  void Function(double)? onChanged,
  bool interactive = true,
  Widget? beforeLabel,
  Widget? afterLabel,
  CoreDiffStyle? style,
}) {
  // `Shortcuts` / `Actions` / `FocusTraversalGroup` are what an app shell
  // supplies — the keys, and Tab moving focus, only exist under them.
  return buildTestApp(
    Shortcuts(
      shortcuts: WidgetsApp.defaultShortcuts,
      child: Actions(
        actions: WidgetsApp.defaultActions,
        child: FocusScope(
          autofocus: true,
          child: FocusTraversalGroup(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: _kFrameWidth,
                child: Diff(
                  before: const ColoredBox(color: Color(0xFFCC0000)),
                  after: const ColoredBox(color: Color(0xFF0000CC)),
                  onPositionChanged: onChanged,
                  interactive: interactive,
                  beforeLabel: beforeLabel,
                  afterLabel: afterLabel,
                  diffStyle: style,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Replaces the tree with [next] from scratch. The test shell mounts its
/// child through an overlay entry whose builder is fixed at the first pump,
/// so pumping a second tree over the first would silently keep the first.
Future<void> _remount(WidgetTester tester, Widget next) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(next);
  await tester.pumpAndSettle();
}

/// The strip around the handle — the nearest hover region above the ring.
Finder get _strip => find
    .ancestor(of: find.byType(FocusOutline), matching: find.byType(MouseRegion))
    .first;

/// The glyph on the handle.
Finder get _glyph => find.byWidgetPredicate(
  (widget) => widget is Icon && widget.icon == LucideIcons.chevronsLeftRight,
);

/// The round handle itself.
Finder get _disc => find.descendant(
  of: find.byType(FocusOutline),
  matching: find.byType(AnimatedContainer),
);

BoxDecoration _discDecoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(_disc).decoration! as BoxDecoration;

bool _ringShown(WidgetTester tester) => tester
    .widgetList<FocusOutline>(find.byType(FocusOutline))
    .any(
      (ring) => ring.focused,
    );

void main() {
  // Desktop platforms: the focus highlight mode defaults to `traditional`,
  // the only mode in which pointer-initiated focus would show a ring if the
  // widget let it.
  final desktop = TargetPlatformVariant.desktop();

  group('Diff handle', () {
    testWidgets('an interactive comparison draws a 40px handle', (
      tester,
    ) async {
      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();

      expect(find.byType(FocusOutline), findsOneWidget);
      expect(tester.getSize(_disc), const Size(_kHandleSize, _kHandleSize));
      expect(_glyph, findsOneWidget);
    });

    // Finding the glyph widget says nothing about whether it paints: a glyph
    // that resolves to no drawing leaves an empty disc and every widget
    // finder above still passes. Read the pixels.
    testWidgets('the glyph is painted — the disc is not blank', (tester) async {
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: boundary, child: _diff()));
      await tester.pumpAndSettle();

      final centre = tester.getCenter(_disc);
      late ui.Image image;
      late ByteData pixels;
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        image = await render.toImage(pixelRatio: 2);
        pixels = (await image.toByteData())!;
      });
      int at(double x, double y) => pixels.getUint32(
        (((y * 2).round() * image.width) + (x * 2).round()) * 4,
      );

      // The disc's own fill, sampled inside it and clear of the 16px glyph.
      final fill = at(centre.dx - 14, centre.dy);
      var inked = 0;
      for (var dy = -8.0; dy <= 8; dy += 0.5) {
        for (var dx = -8.0; dx <= 8; dx += 0.5) {
          if (at(centre.dx + dx, centre.dy + dy) != fill) inked++;
        }
      }
      expect(inked, greaterThan(20));
    });

    testWidgets('a non-interactive comparison draws the line only', (
      tester,
    ) async {
      await tester.pumpWidget(_diff(interactive: false));
      await tester.pumpAndSettle();

      expect(find.byType(FocusOutline), findsNothing);
      expect(_glyph, findsNothing);
      // The line is still there: a shadow-bearing box 2px wide.
      final line = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where(
            (box) =>
                box.decoration is BoxDecoration &&
                (box.decoration as BoxDecoration).boxShadow != null &&
                (box.decoration as BoxDecoration).boxShadow!.isNotEmpty,
          );
      expect(line, isNotEmpty);
    });

    testWidgets('the grab strip is 44px wide and runs the frame height', (
      tester,
    ) async {
      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();

      final size = tester.getSize(_strip);
      expect(size.width, _kHitSize);
      expect(size.height, tester.getSize(find.byType(Diff)).height);
    });

    testWidgets('the handle sits on the split, centred', (tester) async {
      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();

      expect(tester.getCenter(_disc).dx, closeTo(_kFrameWidth / 2, 0.01));
    });
  });

  group('Diff labels', () {
    testWidgets('draw nothing by default', (tester) async {
      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();

      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('sit twelve in from the top corners as chips', (tester) async {
      await tester.pumpWidget(
        _diff(
          beforeLabel: const SizedBox(width: 30, height: 10),
          afterLabel: const SizedBox(width: 30, height: 10),
        ),
      );
      await tester.pumpAndSettle();

      final badges = find.byType(Badge);
      expect(badges, findsNWidgets(2));
      final frame = tester.getRect(find.byType(Diff));
      final first = tester.getRect(badges.at(0));
      final second = tester.getRect(badges.at(1));
      expect(first.left - frame.left, 12);
      expect(first.top - frame.top, 12);
      expect(frame.right - second.right, 12);
      expect(second.top - frame.top, 12);
    });

    testWidgets('only the one given is drawn', (tester) async {
      await tester.pumpWidget(_diff(beforeLabel: const Text('Before')));
      await tester.pumpAndSettle();

      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('Before'), findsOneWidget);
    });

    testWidgets('a label does not catch the pointer', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(
        _diff(onChanged: seen.add, beforeLabel: const Text('Before')),
      );
      await tester.pumpAndSettle();

      // A tap on the chip is a tap on the frame behind it.
      await tester.tapAt(
        tester.getCenter(find.byType(Badge)),
      );
      await tester.pumpAndSettle();
      expect(seen, isNotEmpty);
    });
  });

  group('Diff frame', () {
    testWidgets('the edge is inside — the frame keeps its size', (
      tester,
    ) async {
      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();
      final withEdge = tester.getSize(find.byType(Diff));

      await _remount(tester, _diff(style: const CoreDiffStyle(borderWidth: 0)));
      final withoutEdge = tester.getSize(find.byType(Diff));

      expect(withEdge, withoutEdge);
      expect(withEdge, const Size(_kFrameWidth, _kFrameWidth * 9 / 16));
    });

    testWidgets('a zero border width draws no edge at all', (tester) async {
      Iterable<DecoratedBox> edges() => tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(Diff),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where(
            (box) =>
                box.decoration is BoxDecoration &&
                (box.decoration as BoxDecoration).border != null &&
                (box.decoration as BoxDecoration).borderRadius ==
                    BorderRadius.circular(16),
          );

      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();
      expect(edges(), hasLength(1));

      await _remount(tester, _diff(style: const CoreDiffStyle(borderWidth: 0)));
      expect(edges(), isEmpty);
    });
  });

  group('Diff keyboard', () {
    testWidgets('arrows move 5%, Page keys 10%, Home and End the ends', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(_diff(onChanged: seen.add));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(seen.last, closeTo(0.55, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(seen.last, closeTo(0.5, 1e-9));

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      expect(seen.last, closeTo(0.6, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      expect(seen.last, closeTo(0.5, 1e-9));

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      expect(seen.last, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      expect(seen.last, 1);
    }, variant: desktop);

    testWidgets('a key past an end stops at the end', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(_diff(onChanged: seen.add));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(seen.last, 1);
    }, variant: desktop);

    testWidgets('a non-interactive comparison ignores the keys', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(_diff(onChanged: seen.add, interactive: false));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);

      expect(seen, isEmpty);
    }, variant: desktop);

    testWidgets('the page step follows the style', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(
        _diff(
          onChanged: seen.add,
          style: const CoreDiffStyle(keyboardPageStep: 0.25),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);

      expect(seen.last, closeTo(0.75, 1e-9));
    }, variant: desktop);
  });

  group('Diff pointer', () {
    testWidgets('a mouse click anywhere moves the split there', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(_diff(onChanged: seen.add));
      await tester.pumpAndSettle();

      final origin = tester.getTopLeft(find.byType(Diff));
      await tester.tapAt(origin + const Offset(100, 60), kind: .mouse);
      await tester.pumpAndSettle();

      expect(seen.last, closeTo(0.25, 1e-9));
    });

    testWidgets('a touch tap anywhere moves the split there', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(_diff(onChanged: seen.add));
      await tester.pumpAndSettle();

      final origin = tester.getTopLeft(find.byType(Diff));
      await tester.tapAt(origin + const Offset(300, 60));
      await tester.pumpAndSettle();

      expect(seen.last, closeTo(0.75, 1e-9));
    });

    testWidgets('a mouse drags from anywhere on the frame', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(_diff(onChanged: seen.add));
      await tester.pumpAndSettle();

      final origin = tester.getTopLeft(find.byType(Diff));
      final gesture = await tester.startGesture(
        origin + const Offset(100, 60),
        kind: .mouse,
      );
      await gesture.moveTo(origin + const Offset(300, 60));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(seen.last, closeTo(0.75, 1e-9));
    });

    testWidgets('a touch dragging off the strip does not move the split', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(_diff(onChanged: seen.add));
      await tester.pumpAndSettle();

      // Well clear of the strip (200 ± 22): a swipe here is the page's.
      final origin = tester.getTopLeft(find.byType(Diff));
      final gesture = await tester.startGesture(
        origin + const Offset(60, 100),
      );
      await gesture.moveTo(origin + const Offset(160, 100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(seen, isEmpty);
    });

    testWidgets('a touch dragging the handle moves the split', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(_diff(onChanged: seen.add));
      await tester.pumpAndSettle();

      final origin = tester.getTopLeft(find.byType(Diff));
      final gesture = await tester.startGesture(
        origin + const Offset(_kFrameWidth / 2, 100),
      );
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(seen, isNotEmpty);
      expect(seen.last, closeTo(0.8, 0.01));
    });

    testWidgets('grabbing the disc off-centre does not snap the split', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(_diff(onChanged: seen.add));
      await tester.pumpAndSettle();

      // 15px right of the centre is still on the strip (22 half-width).
      final origin = tester.getTopLeft(find.byType(Diff));
      final gesture = await tester.startGesture(
        origin + const Offset(_kFrameWidth / 2 + 15, 100),
        kind: .mouse,
      );
      await tester.pump();
      expect(seen, isEmpty, reason: 'taking hold alone moves nothing');

      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // The handle travelled by the pointer's 40px, not 55.
      expect(seen.last, closeTo((_kFrameWidth / 2 + 40) / _kFrameWidth, 1e-9));
    });

    testWidgets('a non-interactive comparison ignores the pointer', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(_diff(onChanged: seen.add, interactive: false));
      await tester.pumpAndSettle();

      final origin = tester.getTopLeft(find.byType(Diff));
      await tester.tapAt(origin + const Offset(100, 60), kind: .mouse);
      await tester.tapAt(origin + const Offset(100, 60));
      await tester.pumpAndSettle();

      expect(seen, isEmpty);
    });
  });

  group('Diff handle states', () {
    testWidgets('hover lifts the cast from sm to md', (tester) async {
      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();
      final rest = _discDecoration(tester).boxShadow!;

      final mouse = await tester.createGesture(kind: .mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(_strip));
      await tester.pumpAndSettle();
      final hover = _discDecoration(tester).boxShadow!;

      expect(hover, isNot(rest));
      expect(hover.first.blurRadius, greaterThan(rest.first.blurRadius));

      await mouse.moveTo(const Offset(1000, 1000));
      await tester.pumpAndSettle();
      expect(_discDecoration(tester).boxShadow, rest);
    });

    testWidgets('dragging shrinks the handle to 94% and tightens the cast', (
      tester,
    ) async {
      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();
      final rest = _discDecoration(tester).boxShadow!;

      final gesture = await tester.startGesture(
        tester.getCenter(_disc),
        kind: .mouse,
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(_disc).width, closeTo(_kHandleSize, 0.01));
      final scale = tester.widget<AnimatedScale>(
        find.ancestor(
          of: find.byType(FocusOutline),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(scale.scale, closeTo(0.94, 1e-9));
      final pressed = _discDecoration(tester).boxShadow!;
      expect(pressed.first.blurRadius, lessThan(rest.first.blurRadius));

      await gesture.up();
      await tester.pumpAndSettle();
      final released = tester.widget<AnimatedScale>(
        find.ancestor(
          of: find.byType(FocusOutline),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(released.scale, 1);
      // The mouse is still over the strip, so the cast settles on hover.
      expect(_discDecoration(tester).boxShadow, isNot(pressed));
    });

    testWidgets('the ring shows for the keyboard, not for the mouse', (
      tester,
    ) async {
      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();
      expect(_ringShown(tester), isFalse);

      final gesture = await tester.startGesture(
        tester.getCenter(_disc),
        kind: .mouse,
      );
      await gesture.moveBy(const Offset(20, 0));
      await tester.pumpAndSettle();
      expect(_ringShown(tester), isFalse);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_ringShown(tester), isFalse);

      // A key promotes the pointer's focus to keyboard focus.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(_ringShown(tester), isTrue);
    }, variant: desktop);

    testWidgets('Tab into the comparison shows the ring', (tester) async {
      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_ringShown(tester), isTrue);
    }, variant: desktop);

    testWidgets('a zero pressed scale turns the shrink off', (tester) async {
      await tester.pumpWidget(
        _diff(style: const CoreDiffStyle(handlePressedScale: 1)),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(_disc),
        kind: .mouse,
      );
      await tester.pumpAndSettle();
      final scale = tester.widget<AnimatedScale>(
        find.ancestor(
          of: find.byType(FocusOutline),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(scale.scale, 1);
      await gesture.up();
    });
  });

  group('Diff style', () {
    testWidgets('the handle follows handleSize and handleHitSize', (
      tester,
    ) async {
      await tester.pumpWidget(
        _diff(
          style: const CoreDiffStyle(handleSize: 56, handleHitSize: 72),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(_disc), const Size(56, 56));
      expect(tester.getSize(_strip).width, 72);
    });

    testWidgets('the handle fill and edge follow the style', (tester) async {
      await tester.pumpWidget(
        _diff(
          style: const CoreDiffStyle(
            handleColor: CoreColor.token(CoreColors.primary),
            handleBorderWidth: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final decoration = _discDecoration(tester);
      expect(decoration.color, isNotNull);
      expect((decoration.border! as Border).top.width, 2);
    });

    testWidgets('an empty cast draws no shadow on the handle', (tester) async {
      await tester.pumpWidget(
        _diff(style: const CoreDiffStyle(handleShadow: CoreShadow.none)),
      );
      await tester.pumpAndSettle();

      expect(_discDecoration(tester).boxShadow, isEmpty);
    });
  });

  group('Diff semantics', () {
    testWidgets('an interactive comparison is a slider with a value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_diff());
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(Diff)),
        matchesSemantics(
          isSlider: true,
          hasFocusAction: true,
          isFocusable: true,
          value: 'Split at 50%',
        ),
      );
      handle.dispose();
    });
  });
}
