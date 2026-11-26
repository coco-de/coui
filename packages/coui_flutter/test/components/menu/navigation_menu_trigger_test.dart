import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// What the redesign states of the trigger bar and the dropdown, read off the
/// rendered widgets rather than off the resolver: the trigger is 40 high; a
/// trigger that owns a dropdown is inset 12 at the start and 8 at the end
/// (where the chevron sits) while one without is 12 on both; the label and
/// the chevron are 4 apart and the triggers 2; the open trigger and the
/// hovered one wear `surface-container`; the chevron is `on-surface-variant`;
/// the dropdown is corner 12.
void main() {
  setUp(() {
    // `Button` reports hover only in the traditional highlight mode, which a
    // widget test does not start in.
    FocusManager.instance.highlightStrategy = .alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = .automatic;
  });

  const items = <CoreNavigationMenuItem<Widget>>[
    CoreNavigationMenuItem(label: 'Products', content: Text('Products body')),
    CoreNavigationMenuItem(label: 'Solutions', content: Text('Solutions body')),
    CoreNavigationMenuItem(label: 'Pricing'),
  ];

  Finder button(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(Button));

  Rect rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

  Rect chevronOf(WidgetTester tester, String label) => tester.getRect(
    find.descendant(of: button(label), matching: find.byType(Icon)),
  );

  Color fillOf(WidgetTester tester, String label) {
    final container = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: button(label),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

    return (container.decoration! as BoxDecoration).color!;
  }

  Color tokenColor(WidgetTester tester, CoreColorToken token) {
    final scheme = Theme.of(
      tester.element(find.byType(NavigationMenu)),
    ).colorScheme;

    return scheme.resolve(CoreColor.token(token)).toValue();
  }

  group('trigger metrics (#5967)', () {
    testWidgets('a trigger is 40 high and the bar spaces triggers 2 apart', (
      tester,
    ) async {
      await pumpTestApp(tester, const NavigationMenu(items: items));

      for (final label in ['Products', 'Solutions', 'Pricing']) {
        expect(rectOf(tester, button(label)).height, 40, reason: label);
      }
      expect(
        rectOf(tester, button('Solutions')).left -
            rectOf(tester, button('Products')).right,
        2,
      );
      expect(
        rectOf(tester, button('Pricing')).left -
            rectOf(tester, button('Solutions')).right,
        2,
      );
    });

    testWidgets('a trigger with a dropdown is inset 12 at the start, 8 at the '
        'end, and 4 between label and chevron', (tester) async {
      await pumpTestApp(tester, const NavigationMenu(items: items));

      final box = rectOf(tester, button('Products'));
      final label = rectOf(tester, find.text('Products'));
      final chevron = chevronOf(tester, 'Products');

      expect(label.left - box.left, 12);
      expect(chevron.left - label.right, 4);
      expect(box.right - chevron.right, 8);
      expect(chevron.width, 16);
    });

    testWidgets('a trigger without a dropdown is inset 12 on both sides', (
      tester,
    ) async {
      await pumpTestApp(tester, const NavigationMenu(items: items));

      final box = rectOf(tester, button('Pricing'));
      final label = rectOf(tester, find.text('Pricing'));

      expect(label.left - box.left, 12);
      expect(box.right - label.right, 12);
    });

    testWidgets('the start / end insets follow the reading direction', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const NavigationMenu(items: items),
        textDirection: .rtl,
      );

      final box = rectOf(tester, button('Products'));
      final label = rectOf(tester, find.text('Products'));
      final chevron = chevronOf(tester, 'Products');

      // Start is the right in a right-to-left locale: the label sits 12 from
      // the right edge and the chevron 8 from the left.
      expect(box.right - label.right, 12);
      expect(chevron.left - box.left, 8);
      expect(label.left - chevron.right, 4);
    });

    testWidgets('a stated triggerButtonStyle padding wins for every trigger', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const NavigationMenu(
          items: items,
          navigationMenuStyle: CoreNavigationMenuStyle(
            triggerButtonStyle: CoreButtonStyle(
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          ),
        ),
      );

      for (final label in ['Products', 'Pricing']) {
        final box = rectOf(tester, button(label));
        final text = rectOf(tester, find.text(label));
        expect(text.left - box.left, 24, reason: label);
      }
    });
  });

  group('trigger fills (#5967)', () {
    testWidgets('a resting trigger is transparent', (tester) async {
      await pumpTestApp(tester, const NavigationMenu(items: items));

      for (final label in ['Products', 'Solutions', 'Pricing']) {
        expect(fillOf(tester, label).a, 0, reason: label);
      }
    });

    testWidgets("the open trigger wears surface-container, not the variant's "
        'stronger selected step', (tester) async {
      await pumpTestApp(tester, const NavigationMenu(items: items));

      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      expect(
        fillOf(tester, 'Products'),
        tokenColor(tester, CoreColors.surfaceContainer),
      );
      expect(fillOf(tester, 'Solutions').a, 0);
    });

    testWidgets('a hovered trigger wears surface-container', (tester) async {
      await pumpTestApp(tester, const NavigationMenu(items: items));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Pricing')));
      await tester.pumpAndSettle();

      expect(
        fillOf(tester, 'Pricing'),
        tokenColor(tester, CoreColors.surfaceContainer),
      );
    });
  });

  group('chevron and dropdown (#5967)', () {
    testWidgets('the chevron is on-surface-variant', (tester) async {
      await pumpTestApp(tester, const NavigationMenu(items: items));

      final theme = Theme.of(tester.element(find.byType(NavigationMenu)));
      final resolved = resolveNavigationMenu(
        tester.element(find.byType(NavigationMenu)),
        variant: .standard,
      );
      final icon = tester.widget<Icon>(
        find.descendant(of: button('Products'), matching: find.byType(Icon)),
      );

      expect(
        resolved.chevronIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(icon.iconStyle, resolved.chevronIconStyle);
      expect(theme.colorScheme, isNotNull);
    });

    testWidgets('the dropdown is corner 12', (tester) async {
      await pumpTestApp(tester, const NavigationMenu(items: items));

      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      final panel = tester.widget<Popup>(find.byType(Popup));
      final resolved = resolveNavigationMenu(
        tester.element(find.byType(NavigationMenu)),
        variant: .standard,
      );

      expect(
        resolved.panelStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
      expect(panel.popupStyle, resolved.panelStyle);
    });
  });
}
