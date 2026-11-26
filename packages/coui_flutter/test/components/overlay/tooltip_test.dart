import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kChildText = 'tooltip child';
const _kTooltipText = 'tooltip content';

/// Colour a caller states directly on its own tooltip content.
const _kExplicitColor = Color(0xFFFF0000);

/// Hovers the trigger until the bubble is up, then reads what actually
/// reached the screen: the paragraph's painted foreground and the bubble's
/// fill.
///
/// Runs under a real [CoUIApp] on purpose. The app root installs an ambient
/// `DefaultTextStyle` coloured `colorScheme.onSurface` — the same token that
/// fills the tooltip panel — so unstyled content that falls through to it
/// lands at 1.00:1 contrast. A lighter harness would not have that ambient
/// style and would hide the regression this probe exists to catch.
Future<({Color? foreground, Color? background})> _hoverAndProbe(
  WidgetTester tester, {
  required Widget tooltip,
  required String contentText,
}) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Center(child: tooltip),
    ),
  );

  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  await gesture.moveTo(tester.getCenter(find.text(_kChildText)));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  final paragraph = tester.renderObject<RenderParagraph>(
    find.text(contentText),
  );
  // Nearest enclosing `Container` is the bubble — the one carrying the
  // panel fill the content has to read against.
  final bubble = tester.widget<Container>(
    find
        .ancestor(of: find.text(contentText), matching: find.byType(Container))
        .first,
  );

  final probe = (
    foreground: paragraph.text.style?.color,
    background: (bubble.decoration! as BoxDecoration).color,
  );

  // Retire this pointer and let the bubble finish closing. The mouse
  // tracker asserts that every added pointer is removed before another
  // arrives on the same device, so a test that probes twice needs the
  // first probe to clean up after itself rather than at tear-down.
  await gesture.removePointer();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  return probe;
}

void main() {
  group('Tooltip', () {
    testWidgets('renders child widget with overlay manager', (tester) async {
      // Tooltip is engine-direct (shared PopoverOverlayHandler) — it needs only
      // a root Overlay, which `pumpTestApp` provides.
      await pumpTestApp(
        tester,
        const Tooltip(
          tooltipChild: Text(_kTooltipText),
          child: Text(_kChildText),
        ),
      );

      expect(find.text(_kChildText), findsOneWidget);
    });

    testWidgets('tooltip content not visible before hover', (tester) async {
      await pumpTestApp(
        tester,
        const Tooltip(
          tooltipChild: Text(_kTooltipText),
          child: Text(_kChildText),
        ),
      );

      // Tooltip content should not be visible before hover.
      expect(find.text(_kTooltipText), findsNothing);
    });

    testWidgets('creates with custom position', (tester) async {
      await pumpTestApp(
        tester,
        const Tooltip(
          tooltipChild: Text(_kTooltipText),
          position: .bottom,
          child: Text(_kChildText),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets(
      'exposes the plain message as a semantics tooltip hint',
      (tester) async {
        await pumpTestApp(
          tester,
          const Tooltip(message: _kTooltipText, child: Text(_kChildText)),
        );

        final data = tester
            .getSemantics(find.text(_kChildText))
            .getSemanticsData();
        expect(data.tooltip, _kTooltipText);
      },
    );

    testWidgets(
      'omits the semantics tooltip hint when a custom tooltipChild is used',
      (tester) async {
        await pumpTestApp(
          tester,
          const Tooltip(
            tooltipChild: Text(_kTooltipText),
            child: Text(_kChildText),
          ),
        );

        final data = tester
            .getSemantics(find.text(_kChildText))
            .getSemanticsData();
        expect(data.tooltip, isEmpty);
      },
    );
  });

  group('Tooltip label styling', () {
    testWidgets('message content is legible against the panel fill', (
      tester,
    ) async {
      final probe = await _hoverAndProbe(
        tester,
        tooltip: const Tooltip(
          message: _kTooltipText,
          child: Text(_kChildText),
        ),
        contentText: _kTooltipText,
      );

      expect(probe.foreground, isNotNull);
      expect(probe.foreground, isNot(probe.background));
    });

    testWidgets('unstyled tooltipChild is legible against the panel fill', (
      tester,
    ) async {
      final probe = await _hoverAndProbe(
        tester,
        tooltip: const Tooltip(
          tooltipChild: Text(_kTooltipText),
          child: Text(_kChildText),
        ),
        contentText: _kTooltipText,
      );

      expect(probe.foreground, isNotNull);
      // Before the fix this content inherited the app root's `onSurface`
      // text colour — the very token filling the panel — so it rendered
      // invisible at 1.00:1 rather than merely low-contrast.
      expect(probe.foreground, isNot(probe.background));
    });

    testWidgets('unstyled tooltipChild matches the message path exactly', (
      tester,
    ) async {
      final viaMessage = await _hoverAndProbe(
        tester,
        tooltip: const Tooltip(
          message: _kTooltipText,
          child: Text(_kChildText),
        ),
        contentText: _kTooltipText,
      );
      final viaChild = await _hoverAndProbe(
        tester,
        tooltip: const Tooltip(
          tooltipChild: Text(_kTooltipText),
          child: Text(_kChildText),
        ),
        contentText: _kTooltipText,
      );

      // The sharper statement of the rule: the two paths are not merely
      // both readable, they are the same. A "not equal to the background"
      // assertion alone would still pass if the child drifted to some
      // other arbitrary colour or size.
      expect(viaChild.foreground, equals(viaMessage.foreground));
    });

    testWidgets('tooltipChild keeps a colour it states itself', (tester) async {
      final probe = await _hoverAndProbe(
        tester,
        tooltip: const Tooltip(
          tooltipChild: Text(
            _kTooltipText,
            style: TextStyle(color: _kExplicitColor),
          ),
          child: Text(_kChildText),
        ),
        contentText: _kTooltipText,
      );

      // The cross-platform contract — a `tooltipChild` owns its own
      // typography — survives the default. `DefaultTextStyle.merge` only
      // supplies what the child left unsaid.
      expect(probe.foreground, equals(_kExplicitColor));
    });
  });
  group('Tooltip redesign (#5967)', () {
    testWidgets('the label is 12 Medium — the labelSmall role, no SemiBold', (
      tester,
    ) async {
      late ResolvedTooltip resolved;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Builder(
            builder: (context) {
              resolved = resolveTooltip(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.labelTextStyle.fontSize, 12);
      expect(resolved.labelTextStyle.fontWeight, FontWeight.w500);
    });
  });
}
