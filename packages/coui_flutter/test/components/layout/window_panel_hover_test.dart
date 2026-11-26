import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderDecoratedBox;
import 'package:flutter_test/flutter_test.dart';

const _kPanelWidth = 320.0;
const _kFramePump = Duration(milliseconds: 16);

/// Drains `pumpAndSettle`'s frame-count return in one place.
Future<void> _settle(WidgetTester tester) async {
  final _ = await tester.pumpAndSettle();
}

/// The hover wash colour of the chrome `AnimatedContainer` inside the
/// maximize control button (null = no wash painted).
Color? _maximizeWash(WidgetTester tester) {
  final buttons = find.byType(Button);
  // Controls render in order: minimize, maximize, close.
  final maximize = buttons.at(1);
  final container = tester.widget<AnimatedContainer>(
    find.descendant(of: maximize, matching: find.byType(AnimatedContainer)),
  );
  final decoration = container.decoration;
  if (decoration is! BoxDecoration) return null;
  return decoration.color;
}

void main() {
  testWidgets(
    'control button hover wash establishes and SURVIVES pointer movement '
    'inside the button (standalone WindowPanel — no navigator around it)',
    (tester) async {
      // The test binding defaults to the touch highlight mode (mobile
      // platform), which suppresses `onShowHoverHighlight` — force the
      // desktop/mouse behaviour the report is about.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      final _ = await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: Center(
              child: SizedBox(
                width: _kPanelWidth,
                child: WindowPanel(
                  title: const material.Text('T'),
                  onClose: () {},
                  onMinimize: () {},
                  onMaximize: () {},
                  minimizable: true,
                  maximizable: true,
                  child: const SizedBox(height: 80),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      final center = tester.getCenter(find.byType(Button).at(1));
      await gesture.moveTo(center);
      await _settle(tester);

      final hoverWash = _maximizeWash(tester);
      expect(
        hoverWash,
        isNotNull,
        reason: 'hovering the maximize button must paint the hover wash',
      );
      expect(hoverWash!.a, greaterThan(0));

      // Wiggle INSIDE the button — the wash must stay on every frame.
      final washes = <Color?>[];
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(i.isEven ? 2 : -2, i % 3 == 0 ? 1 : -1));
        await tester.pump(_kFramePump);
        washes.add(_maximizeWash(tester));
      }
      expect(
        washes,
        everyElement(equals(hoverWash)),
        reason:
            'pointer movement inside the button must not blink the wash '
            '(frames: $washes)',
      );

      await gesture.removePointer();
      await _settle(tester);
    },
  );

  testWidgets(
    'control button fires IMMEDIATELY even when the title bar has a '
    'double-tap handler (no 300ms double-tap-arena hold)',
    (tester) async {
      var minimized = 0;
      var maximizedByDoubleTap = 0;
      final _ = await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: Center(
              child: SizedBox(
                width: _kPanelWidth,
                child: WindowPanel(
                  title: const material.Text('T'),
                  onClose: () {},
                  onMinimize: () => minimized++,
                  onMaximize: () {},
                  onTitleBarDoubleTap: () => maximizedByDoubleTap++,
                  minimizable: true,
                  maximizable: true,
                  child: const SizedBox(height: 80),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      // Single tap on the minimize button must resolve on the very next
      // frame — a DoubleTapGestureRecognizer ancestor held it in the
      // gesture arena for kDoubleTapTimeout (~300ms) instead.
      await tester.tap(find.byType(Button).first);
      await tester.pump();
      expect(
        minimized,
        1,
        reason: 'button tap must not wait out the double-tap timeout',
      );

      // A quick second press on the button toggles again — it must NOT
      // read as a title-bar double-tap (maximize).
      await tester.tap(find.byType(Button).first);
      await tester.pump();
      expect(minimized, 2);
      expect(maximizedByDoubleTap, 0);

      // A genuine double-tap on the empty title-bar area still fires.
      final title =
          tester.getTopLeft(find.byType(WindowPanel)) + const Offset(40, 16);
      await tester.tapAt(title);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(title);
      await tester.pump();
      expect(maximizedByDoubleTap, 1);
      await _settle(tester);
    },
  );

  testWidgets(
    'hover wash fades WITHOUT a dark mid-frame (transparent-black lerp '
    'flash)',
    (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      final _ = await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: Center(
              child: SizedBox(
                width: _kPanelWidth,
                child: WindowPanel(
                  title: const material.Text('T'),
                  onClose: () {},
                  onMinimize: () {},
                  onMaximize: () {},
                  minimizable: true,
                  maximizable: true,
                  child: const SizedBox(height: 80),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      final maximize = find.byType(Button).at(1);
      await gesture.moveTo(tester.getCenter(maximize));
      // Capture the LIVE animated decoration mid-fade: the settled hover
      // wash is a light opaque grey; a straight lerp from
      // transparent-BLACK passes through a dark translucent grey that
      // reads as a blink on the light title bar.
      await tester.pump(); // start the implicit animation
      await tester.pump(const Duration(milliseconds: 75)); // ~t = 0.5
      final box = tester.renderObject<RenderBox>(
        find.descendant(
          of: maximize,
          matching: find.byType(AnimatedContainer),
        ),
      );
      RenderDecoratedBox? decorated;
      void visit(RenderObject child) {
        if (decorated != null) return;
        if (child is RenderDecoratedBox) {
          decorated = child;
          return;
        }
        child.visitChildren(visit);
      }

      visit(box);
      final midColor =
          (decorated!.decoration as BoxDecoration).color ??
          const Color(0x00000000);
      await _settle(tester);
      final settled = _maximizeWash(tester)!;

      // Mid-fade RGB must already match the settled wash RGB (alpha-only
      // fade) — a darker RGB mid-frame is the blink.
      expect(
        (midColor.r - settled.r).abs() < 0.02 &&
            (midColor.g - settled.g).abs() < 0.02 &&
            (midColor.b - settled.b).abs() < 0.02,
        isTrue,
        reason:
            'hover fade must interpolate alpha only — mid-frame '
            '$midColor vs settled $settled drifts through a dark flash',
      );

      await gesture.removePointer();
      await _settle(tester);
    },
  );
}
