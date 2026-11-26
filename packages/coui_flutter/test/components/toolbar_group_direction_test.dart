import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Widget _action(IconName icon, {VoidCallback? onPressed}) => Button(
  variant: .ghost,
  shape: .square,
  onPressed: onPressed ?? () {},
  child: Icon(icon),
);

ToolbarGroup _group({
  CoreAxis direction = CoreToolbarGroupContract.defaultDirection,
  CorePopupStyle? popupStyle,
  List<Widget>? children,
}) => ToolbarGroup(
  ariaLabel: 'Page actions',
  direction: direction,
  popupStyle: popupStyle,
  children:
      children ??
      [
        _action(LucideIcons.chevronLeft),
        _action(LucideIcons.share),
        _action(LucideIcons.ellipsis),
      ],
);

void main() {
  group('a glass column', () {
    testWidgets('is one capsule 48 across, a 48 seat per control', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        _group(direction: .vertical),
        surfaceStyle: .liquidGlass,
      );

      final capsule = find.byType(Popup);
      expect(capsule, findsOneWidget);
      // One material pass for the whole group — not one per control.
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(tester.getSize(capsule), const Size(48, 144));

      final buttons = find.byType(Button);
      expect(buttons, findsNWidgets(3));
      for (var index = 0; index < 3; index++) {
        expect(
          tester.getRect(buttons.at(index)),
          Rect.fromLTWH(
            tester.getTopLeft(capsule).dx,
            tester.getTopLeft(capsule).dy + index * 48,
            48,
            48,
          ),
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('is a pill at both ends', (tester) async {
      await pumpTestApp(
        tester,
        _group(direction: .vertical),
        surfaceStyle: .liquidGlass,
      );
      final context = tester.element(find.byType(Popup));
      final resolved = resolvePopup(
        context,
        popupStyle: tester.widget<Popup>(find.byType(Popup)).popupStyle,
      );
      // The full radius on a 48-wide box: the ends are half-circles.
      expect(
        resolved.borderRadius.topLeft.x,
        greaterThanOrEqualTo(24),
      );
      expect(resolved.padding, EdgeInsets.zero);
    });

    testWidgets('a group stated on a group alone takes the same seats', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        _group(
          direction: .vertical,
          popupStyle: const CorePopupStyle(surfaceStyle: .liquidGlass),
        ),
      );
      expect(tester.getSize(find.byType(Popup)), const Size(48, 144));
    });

    testWidgets('each control still acts on its own', (tester) async {
      final pressed = <String>[];
      await pumpTestApp(
        tester,
        _group(
          direction: .vertical,
          children: [
            _action(LucideIcons.chevronLeft, onPressed: () => pressed.add('b')),
            _action(LucideIcons.share, onPressed: () => pressed.add('s')),
          ],
        ),
        surfaceStyle: .liquidGlass,
      );
      // The whole 48 seat is the control: a tap at its edge reaches it.
      final second = tester.getRect(find.byType(Button).last);
      await tester.tapAt(second.topLeft + const Offset(2, 2));
      await tester.tap(find.byType(Button).first);
      expect(pressed, ['s', 'b']);
    });

    testWidgets('an authored button size still wins', (tester) async {
      await pumpTestApp(
        tester,
        _group(direction: .vertical),
        surfaceStyle: .liquidGlass,
        componentTheme: const CoreComponentTheme(
          button: CoreButtonTheme(style: CoreButtonStyle(height: 56)),
        ),
      );
      expect(tester.getSize(find.byType(Button).first).height, 56);
    });
  });

  group('the glyph', () {
    Size glyph(WidgetTester tester) => tester.getSize(find.byType(Icon).first);

    testWidgets("a glass column draws the glass rail's 24", (tester) async {
      await pumpTestApp(
        tester,
        _group(direction: .vertical),
        surfaceStyle: .liquidGlass,
      );
      final icons = find.byType(Icon);
      expect(icons, findsNWidgets(3));
      for (var index = 0; index < 3; index++) {
        expect(tester.getSize(icons.at(index)), const Size.square(24));
      }
      // The same glyph the rail in the same strip draws.
      expect(
        glyph(tester).width,
        CoreNavigationBarStyle.defaultIconStyle.size,
      );
      // The seat does not grow for it.
      expect(tester.getSize(find.byType(Popup)), const Size(48, 144));
    });

    testWidgets('a button with a label beside its glyph takes it too', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        _group(
          direction: .vertical,
          children: [
            Button(
              variant: .ghost,
              onPressed: () {},
              leading: const Icon(LucideIcons.share),
              child: const Text('Share'),
            ),
          ],
        ),
        surfaceStyle: .liquidGlass,
      );
      // The slot beside a label is as tall as the row; the glyph it is
      // handed is the size that counts.
      expect(
        IconTheme.of(tester.element(find.byType(Icon))).size,
        24,
      );
      expect(glyph(tester).width, 24);
    });

    testWidgets("a glass row and an opaque column keep the button's own", (
      tester,
    ) async {
      final own = CoreButtonStyle.iconSizeFor(
        size: .md,
        iconShaped: true,
        iconShapeOverride: null,
        leadingOverride: null,
        trailingOverride: null,
      );
      expect(own, lessThan(24));

      await pumpTestApp(tester, _group(), surfaceStyle: .liquidGlass);
      expect(glyph(tester), Size.square(own));

      await tester.pumpWidget(const SizedBox());
      await pumpTestApp(tester, _group(direction: .vertical));
      expect(glyph(tester), Size.square(own));
    });

    testWidgets('an authored glyph size still wins', (tester) async {
      await pumpTestApp(
        tester,
        _group(direction: .vertical),
        surfaceStyle: .liquidGlass,
        componentTheme: const CoreComponentTheme(
          button: CoreButtonTheme(
            style: CoreButtonStyle(
              iconShapeIconStyle: CoreIconStyle(size: CoreIconSize.size20),
            ),
          ),
        ),
      );
      expect(glyph(tester), const Size.square(20));
    });
  });

  group('the controls a column draws', () {
    Widget edit() => BarAction(
      axisBehavior: .horizontalOnly,
      child: Button(
        variant: .ghost,
        onPressed: () {},
        child: const Text('Edit'),
      ),
    );

    List<Widget> actions() => [
      _action(LucideIcons.chevronLeft),
      edit(),
      ToolbarGroup(
        ariaLabel: 'Share and more',
        children: [
          _action(LucideIcons.share),
          _action(LucideIcons.ellipsis),
        ],
      ),
    ];

    for (final surfaceStyle in [
      CoreSurfaceStyleId.defaultId,
      CoreSurfaceStyleId.liquidGlass,
    ]) {
      testWidgets(
        'leave out a horizontal-only action and take a group in '
        '(${surfaceStyle.name})',
        (tester) async {
          await pumpTestApp(
            tester,
            _group(direction: .vertical, children: actions()),
            surfaceStyle: surfaceStyle,
          );

          expect(find.text('Edit'), findsNothing);
          // The group gave the column its two controls: one capsule, three
          // controls, in the order they were given.
          expect(find.byType(Popup), findsOneWidget);
          final buttons = find.byType(Button);
          expect(buttons, findsNWidgets(3));
          final icons = tester
              .widgetList<Icon>(find.byType(Icon))
              .map((icon) => icon.icon);
          expect(icons, [
            LucideIcons.chevronLeft,
            LucideIcons.share,
            LucideIcons.ellipsis,
          ]);
          expect(
            tester.getTopLeft(buttons.at(1)).dy,
            tester.getBottomLeft(buttons.at(0)).dy,
          );
          expect(
            tester.getTopLeft(buttons.at(2)).dy,
            tester.getBottomLeft(buttons.at(1)).dy,
          );
        },
      );
    }

    testWidgets('a row draws every one, the group in its own capsule', (
      tester,
    ) async {
      await pumpTestApp(tester, _group(children: actions()));

      expect(find.text('Edit'), findsOneWidget);
      expect(find.byType(Button), findsNWidgets(4));
      expect(find.byType(Popup), findsNWidgets(2));
    });

    testWidgets('a column of horizontal-only actions draws nothing', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        _group(direction: .vertical, children: [edit()]),
        surfaceStyle: .liquidGlass,
      );

      expect(find.byType(Popup), findsNothing);
      expect(tester.getSize(find.byType(ToolbarGroup)), Size.zero);
    });

    testWidgets('a marker outside a bar draws its action and nothing else', (
      tester,
    ) async {
      await pumpTestApp(tester, edit());

      expect(
        tester.getSize(find.byType(BarAction)),
        tester.getSize(find.byType(Button)),
      );
    });
  });

  testWidgets('a glass row keeps its 44 seats', (tester) async {
    await pumpTestApp(tester, _group(), surfaceStyle: .liquidGlass);

    expect(tester.getSize(find.byType(Popup)), const Size(132, 44));
    final buttons = find.byType(Button);
    expect(
      tester.getTopLeft(buttons.at(1)).dx - tester.getTopLeft(buttons.at(0)).dx,
      44,
    );
    expect(
      tester.getTopLeft(buttons.at(1)).dy,
      tester.getTopLeft(buttons.at(0)).dy,
    );
  });

  group('the opaque capsule', () {
    testWidgets('stands its controls in a column inside its padding', (
      tester,
    ) async {
      await pumpTestApp(tester, _group(direction: .vertical));

      final capsule = tester.getRect(find.byType(Popup));
      final buttons = find.byType(Button);
      final first = tester.getRect(buttons.at(0));
      final second = tester.getRect(buttons.at(1));
      const padding = CoreToolbarGroupContract.defaultPopupStyle;

      expect(find.byType(BackdropFilter), findsNothing);
      // The controls keep their own size; the capsule's padding surrounds
      // them and they follow one another down.
      expect(first.left - capsule.left, padding.padding!.left);
      expect(first.top - capsule.top, padding.padding!.top);
      expect(second.top, first.bottom);
      expect(second.left, first.left);
      expect(
        capsule.width,
        first.width + padding.padding!.left + padding.padding!.right,
      );
      expect(
        capsule.height,
        first.height * 3 + padding.padding!.top + padding.padding!.bottom,
      );
    });

    testWidgets('a row is unchanged', (tester) async {
      await pumpTestApp(tester, _group());

      final buttons = find.byType(Button);
      expect(
        tester.getTopLeft(buttons.at(1)).dy,
        tester.getTopLeft(buttons.at(0)).dy,
      );
      expect(
        tester.getTopLeft(buttons.at(1)).dx,
        tester.getTopRight(buttons.at(0)).dx,
      );
    });
  });

  for (final direction in CoreAxis.values) {
    testWidgets('the group is one named group in a $direction', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTestApp(tester, _group(direction: direction));

      expect(find.bySemanticsLabel('Page actions'), findsOneWidget);
      handle.dispose();
    });
  }

  testWidgets('an empty column draws nothing', (tester) async {
    await pumpTestApp(
      tester,
      _group(direction: .vertical, children: const []),
      surfaceStyle: .liquidGlass,
    );
    expect(find.byType(Popup), findsNothing);
    expect(
      tester.getSize(find.byType(ToolbarGroup)),
      Size.zero,
    );
  });

  testWidgets('the column fits a strip no wider than the capsule', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_group(direction: .vertical)],
        ),
      ),
      surfaceStyle: .liquidGlass,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.renderObject<RenderBox>(find.byType(Popup)).size.width,
      48,
    );
  });
}
