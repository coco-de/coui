import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// What the hover-card redesign states of the open panel (#5967): the panel
/// box is a composed `Popup` — corner 12 on a `surface-bright` fill with the
/// content inset 16 — and the card sits 4 off its trigger. Read off the
/// `Popup` the widget mounts, resolved the way `Popup` resolves itself, and
/// the offset the resolver feeds the overlay.
Future<Popup> _openPanel(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(find.text('Target')));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 1));

  return tester.widget<Popup>(find.byType(Popup));
}

ResolvedPopup _resolvePanel(WidgetTester tester, Popup popup) => resolvePopup(
  tester.element(find.byType(Popup)),
  popupStyle: popup.popupStyle,
);

void main() {
  group('HoverCard panel chrome', () {
    testWidgets('the open panel is a Popup, not a Card', (tester) async {
      await pumpTestApp(
        tester,
        const HoverCard(content: Text('Panel'), trigger: Text('Target')),
      );

      final popup = await _openPanel(tester);

      expect(find.byType(Card), findsNothing);
      expect(popup.children, hasLength(1));
      // The hover card states only its content-sized ceiling; every other
      // field is the Popup's own, so the panel follows Popup when it moves.
      expect(popup.popupStyle, CoreHoverCardStyle.defaultPanelStyle);
    });

    testWidgets('the open card is corner 12 on a surface-bright fill', (
      tester,
    ) async {
      late ThemeData theme;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const HoverCard(
              content: Text('Panel'),
              trigger: Text('Target'),
            );
          },
        ),
      );

      final popup = await _openPanel(tester);
      final resolved = _resolvePanel(tester, popup);

      expect(
        resolved.borderRadius,
        BorderRadius.circular(12 * theme.scaling),
      );
      expect(
        resolved.backgroundColor,
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.surfaceBright))
            .toValue(),
      );
      expect(resolved.padding, EdgeInsets.all(16 * theme.scaling));
    });

    testWidgets('a stated radius and fill win over the defaults', (
      tester,
    ) async {
      late ThemeData theme;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const HoverCard(
              content: Text('Panel'),
              trigger: Text('Target'),
              hoverCardStyle: CoreHoverCardStyle(
                panelStyle: CorePopupStyle(
                  borderRadius: CoreBorderRadius.all(20),
                  backgroundColor: CoreColor.token(CoreColors.surface),
                ),
              ),
            );
          },
        ),
      );

      final popup = await _openPanel(tester);
      final resolved = _resolvePanel(tester, popup);

      expect(
        resolved.borderRadius,
        BorderRadius.circular(20 * theme.scaling),
      );
      expect(
        resolved.backgroundColor,
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.surface))
            .toValue(),
      );
      // A stated corner and fill do not take the ceiling with them.
      expect(popup.popupStyle?.maxWidth, CoreSpace.space256);
    });

    testWidgets('the chain getters patch the panel slot', (tester) async {
      await pumpTestApp(
        tester,
        const HoverCard(
          content: Text('Panel'),
          trigger: Text('Target'),
        ).radius4.surface,
      );

      final popup = await _openPanel(tester);

      expect(
        popup.popupStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      expect(
        popup.popupStyle?.backgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
    });

    testWidgets('the card sits 4 off the trigger along the placement axis', (
      tester,
    ) async {
      late ResolvedHoverCard resolved;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveHoverCard(context, placement: .bottom);

            return const SizedBox.shrink();
          },
        ),
      );

      expect(resolved.panelOffset, const Offset(0, 4));
    });
  });
}
