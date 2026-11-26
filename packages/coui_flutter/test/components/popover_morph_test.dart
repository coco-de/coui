// Whether the morph actually reaches a panel.
//
// The axis field can be authored, folded into `ThemeData`, complete in
// `==`, and read by a widget — and still never carve anything, because the
// one arithmetic step between them is wrong or the wrapper never mounts.
// The CI guard proves a property access exists; these prove a panel is
// clipped.
import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';

const _kTriggerSize = Size(120, 40);

/// A page with one popover, opened by tapping its trigger.
Widget _app({
  required CoreSurfaceStyleId style,
  bool reduceMotion = false,
}) => CoUIApp(
  theme: applySurfaceStyle(
    ThemeData(colorScheme: const ResolvedColorScheme.tokenized()),
    surfaceStyle: style,
    highContrast: false,
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Center(
    child: Popover(
      placement: CorePopoverPlacement.bottom,
      trigger: SizedBox.fromSize(
        size: _kTriggerSize,
        child: const ColoredBox(color: Color(0xFF334455)),
      ),
      content: const SizedBox(
        width: 220,
        height: 140,
        child: ColoredBox(color: Color(0xFF112233)),
      ),
    ),
  ),
);

/// Opens the popover and pumps far enough for layout to report the panel.
Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(ColoredBox).first);
  await tester.pump();
  // One frame to lay the panel out, one to deliver the post-frame report,
  // one to rebuild on it.
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  group('the morph reaches the panel, or it does not exist', () {
    testWidgets('a liquid-glass popover is carved out of its trigger', (
      tester,
    ) async {
      // **This is the assertion that fails when the wiring is declared but
      // inert.** Every other test in this epic passes with the field read,
      // folded, equality-complete, and never reaching a widget.
      await tester.pumpWidget(_app(style: CoreSurfaceStyleId.liquidGlass));
      await _open(tester);

      expect(find.byType(LiquidMorphClip), findsOneWidget);
    });

    testWidgets('and the default style leaves overlays alone', (tester) async {
      await tester.pumpWidget(_app(style: CoreSurfaceStyleId.defaultStyle));
      await _open(tester);

      expect(find.byType(LiquidMorphClip), findsNothing);
    });
  });

  group('the trigger lands in the panel\'s coordinates', () {
    testWidgets('its body is the trigger\'s size, above the panel', (
      tester,
    ) async {
      // The load-bearing arithmetic: `_position` is an anchor *point* with
      // the alignment already baked in, so the rect has to be recovered by
      // undoing that alignment and then rebased onto the panel's origin. A
      // sign error here shows up only as a neck pointing at empty space, on
      // some placements.
      await tester.pumpWidget(_app(style: CoreSurfaceStyleId.liquidGlass));
      await _open(tester);

      final clip = tester.widget<LiquidMorphClip>(
        find.byType(LiquidMorphClip),
      );

      // The trigger keeps its measured size wherever it ended up.
      expect(clip.anchor.halfWidth * 2, closeTo(_kTriggerSize.width, 0.5));
      expect(clip.anchor.halfHeight * 2, closeTo(_kTriggerSize.height, 0.5));

      // Placed below its trigger, so the trigger sits above the panel's
      // own box — a negative centre in panel space.
      expect(
        clip.anchor.centerY,
        lessThan(0),
        reason: 'the trigger is not above a panel placed below it',
      );

      // Horizontally centred on the panel, because the placement is.
      expect(clip.anchor.centerX, closeTo(clip.panel.centerX, 1));
    });

    testWidgets('and the panel body is the panel\'s own box', (tester) async {
      await tester.pumpWidget(_app(style: CoreSurfaceStyleId.liquidGlass));
      await _open(tester);

      final clip = tester.widget<LiquidMorphClip>(
        find.byType(LiquidMorphClip),
      );

      // Centred on itself: the clip carves in the panel's own space, so
      // the panel body is always the box from (0,0) to its size.
      expect(clip.panel.centerX, closeTo(clip.panel.halfWidth, 0.01));
      expect(clip.panel.centerY, closeTo(clip.panel.halfHeight, 0.01));
      expect(clip.panel.halfWidth, greaterThan(0));
      expect(clip.panel.halfHeight, greaterThan(0));
    });
  });

  group('the two entrance animations do not stack', () {
    testWidgets('the scale is held flat while morphing', (tester) async {
      // The scale is applied above the child in both paint and hit test,
      // so a clip carved in unscaled panel coordinates would itself be
      // scaled 0.9 → 1.0 while the real trigger is not — and the neck is
      // made of exactly that distance. The symptom is a subtly wrong neck,
      // not anything obviously broken.
      await tester.pumpWidget(_app(style: CoreSurfaceStyleId.liquidGlass));
      await tester.tap(find.byType(ColoredBox).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      // Read off the layout widget's diagnostics, because the scale is
      // applied by the render object's paint transform rather than by a
      // `Transform` widget — a `find.byType(Transform)` version of this
      // test found unrelated transforms and passed against the unfixed
      // code.
      final scales = tester
          .widgetList(
            find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == '_PopoverLayout',
            ),
          )
          .map(
            (w) => w
                .toDiagnosticsNode()
                .getProperties()
                .firstWhere((p) => p.name == 'scale')
                .value,
          )
          .toList();

      expect(scales, isNotEmpty, reason: 'no popover layout to check');
      expect(
        scales.every((s) => s == 1.0),
        isTrue,
        reason: 'something is still scaling the panel: $scales',
      );
    });
  });

  group('the boundary is a decision, not an oversight', () {
    testWidgets('a tooltip does not morph, even under liquid glass', (
      tester,
    ) async {
      // Left out because the clip carves at a radius the engine has to
      // assume, and only `Popover`'s panel radius is verifiable. Recorded
      // here so the day someone flips the engine default, this says so.
      await tester.pumpWidget(
        CoUIApp(
          theme: applySurfaceStyle(
            ThemeData(colorScheme: const ResolvedColorScheme.tokenized()),
            surfaceStyle: CoreSurfaceStyleId.liquidGlass,
            highContrast: false,
          ),
          home: const Center(
            child: Tooltip(
              message: 'hint',
              child: SizedBox(width: 60, height: 24),
            ),
          ),
        ),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(Tooltip)));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 16));

      // A tooltip that never opened would satisfy the negative below while
      // asserting nothing at all.
      expect(
        find.text('hint'),
        findsOneWidget,
        reason: 'the tooltip never opened, so the negative proves nothing',
      );
      expect(find.byType(LiquidMorphClip), findsNothing);
    });
  });
}
