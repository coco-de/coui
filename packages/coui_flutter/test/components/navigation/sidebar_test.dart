import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Material(
      child: Align(alignment: .topLeft, child: child),
    ),
  ),
);

Color _token(WidgetTester tester, CoreColorToken token) {
  final context = tester.element(find.byType(Align).first);
  return Theme.of(
    context,
  ).colorScheme.resolve(CoreColor.token(token)).toValue();
}

TextStyle _labelStyle(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

BoxDecoration _itemFace(WidgetTester tester, Finder item) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: item,
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration!
        as BoxDecoration;

void main() {
  group('Sidebar', () {
    for (final (type, width) in [
      (CoreSidebarType.standard, CoreLayout.layout248),
      (CoreSidebarType.twoPane, CoreSize.size64 + CoreLayout.layout240),
      (CoreSidebarType.collapsed, CoreSize.size64),
    ]) {
      testWidgets('${type.name} is ${width.toInt()} wide', (tester) async {
        await tester.pumpWidget(
          _app(
            SizedBox(
              height: 600,
              child: Sidebar(
                type: type,
                railItems: [
                  SidebarRailItem(
                    icon: const Icon(LucideIcons.house),
                    label: '홈',
                    onPressed: () {},
                  ),
                ],
                children: [
                  SidebarItem(label: const Text('홈'), onPressed: () {}),
                ],
              ),
            ),
          ),
        );
        expect(tester.getSize(find.byType(Sidebar)).width, width);
      });
    }

    testWidgets('paints the chrome face with the end line', (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(height: 400, child: Sidebar(children: [Text('본문')])),
        ),
      );
      final panel = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Sidebar),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = panel.decoration! as BoxDecoration;
      expect(decoration.color, _token(tester, CoreColors.surfaceContainerLow));
      final border = decoration.border! as BorderDirectional;
      expect(border.end.color, _token(tester, CoreColors.outlineVariant));
      expect(border.end.width, CoreStrokeWidth.stroke1);
    });

    testWidgets('the arrows move focus between the rows', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 400,
            child: Sidebar(
              children: [
                SidebarItem(label: const Text('하나'), onPressed: () {}),
                SidebarItem(label: const Text('둘'), onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final first = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNot(first));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, first);
    });
  });

  group('SidebarItem', () {
    testWidgets('a resting row reads in onSurfaceSubtle on no face', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 216,
            child: SidebarItem(label: const Text('메뉴'), onPressed: () {}),
          ),
        ),
      );
      final item = find.byType(SidebarItem);
      expect(tester.getSize(item).height, CoreSize.size36);
      expect(
        _labelStyle(tester, '메뉴').color,
        _token(tester, CoreColors.onSurfaceSubtle),
      );
      expect(_itemFace(tester, item).color!.a, 0);
    });

    testWidgets('the current place raises its face and its label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 216,
            child: SidebarItem(
              label: const Text('메뉴'),
              selected: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      final style = _labelStyle(tester, '메뉴');
      expect(style.color, _token(tester, CoreColors.onSurface));
      expect(style.fontWeight, FontWeight.w600);
      expect(
        _itemFace(tester, find.byType(SidebarItem)).color,
        _token(tester, CoreColors.surfaceContainer),
      );
    });

    testWidgets('a nested row is 32 tall', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 188,
            child: SidebarItem(
              level: CoreSidebarItemLevel.nested,
              label: const Text('메뉴'),
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(SidebarItem)).height, CoreSize.size32);
    });

    testWidgets('a disabled row is never selected', (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 216,
            child: SidebarItem(label: Text('메뉴'), selected: true),
          ),
        ),
      );
      expect(
        _labelStyle(tester, '메뉴').color,
        _token(tester, CoreColors.disabledContent),
      );
      expect(_itemFace(tester, find.byType(SidebarItem)).color!.a, 0);
    });

    testWidgets('a disabled row dims its trailing glyph with the rest', (
      tester,
    ) async {
      Color trailingInk() =>
          IconTheme.of(tester.element(find.byType(Icon))).color!;

      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 216,
            child: SidebarItem(
              label: const Text('메뉴'),
              trailing: const Icon(LucideIcons.chevronRight),
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(trailingInk(), _token(tester, CoreColors.onSurfaceSubtle));

      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 216,
            child: SidebarItem(
              label: Text('메뉴'),
              trailing: Icon(LucideIcons.chevronRight),
            ),
          ),
        ),
      );
      expect(trailingInk(), _token(tester, CoreColors.disabledContent));
      expect(
        _labelStyle(tester, '메뉴').color,
        _token(tester, CoreColors.disabledContent),
      );
    });

    testWidgets('the label sits in the middle of the row', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 216,
            child: SidebarItem(label: const Text('메뉴'), onPressed: () {}),
          ),
        ),
      );
      final row = tester.getRect(find.byType(SidebarItem));
      final label = tester.getRect(find.text('메뉴'));
      expect(label.top - row.top, closeTo(row.bottom - label.bottom, 0.5));
    });
  });

  group('SidebarRailItem', () {
    testWidgets('a 40 square named by its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SidebarRailItem(
            icon: const Icon(LucideIcons.house),
            label: '홈',
            selected: true,
            onPressed: () {},
          ),
        ),
      );
      expect(
        tester.getSize(
          find.descendant(
            of: find.byType(SidebarRailItem),
            matching: find.byType(AnimatedContainer),
          ),
        ),
        const Size(CoreSize.size40, CoreSize.size40),
      );
      expect(find.bySemanticsLabel('홈'), findsWidgets);
      handle.dispose();
    });
  });

  group('SidebarSection', () {
    testWidgets('a quiet heading', (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(width: 216, child: SidebarSection(label: Text('구역'))),
        ),
      );
      expect(
        _labelStyle(tester, '구역').color,
        _token(tester, CoreColors.onSurfaceSubtle),
      );
    });
  });

  group('SidebarHeader', () {
    testWidgets('card draws a surface tile with a line', (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 216,
            child: SidebarHeader(
              variant: CoreSidebarHeaderVariant.card,
              title: Text('나음 병원'),
            ),
          ),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(SidebarHeader),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, _token(tester, CoreColors.surface));
      expect(decoration.border, isNotNull);
    });

    testWidgets('plain draws no line', (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(width: 216, child: SidebarHeader(title: Text('나음'))),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(SidebarHeader),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((box.decoration as BoxDecoration).border, isNull);
    });
  });

  group('SidebarSearch', () {
    testWidgets('a trigger with the shortcut drawn as a Kbd', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 216,
            child: SidebarSearch(
              placeholder: '검색',
              shortcut: const ['⌘', 'K'],
              onPressed: () => pressed++,
            ),
          ),
        ),
      );
      expect(find.byType(Kbd), findsOneWidget);
      expect(
        tester.getSize(find.byType(SidebarSearch)).height,
        CoreSize.size36,
      );
      await tester.tap(find.text('검색'));
      await tester.pumpAndSettle();
      expect(pressed, 1);
    });
  });

  group('SidebarGroup', () {
    testWidgets('the row opens and closes the nested rows', (tester) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 216,
            child: SidebarGroup(
              label: const Text('프로젝트'),
              onExpandedChanged: changes.add,
              children: [
                SidebarItem(
                  level: CoreSidebarItemLevel.nested,
                  label: const Text('하위'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('하위'), findsOneWidget);
      await tester.tap(find.text('프로젝트'));
      await tester.pumpAndSettle();
      expect(find.text('하위'), findsNothing);
      expect(changes, [false]);
      await tester.tap(find.text('프로젝트'));
      await tester.pumpAndSettle();
      expect(find.text('하위'), findsOneWidget);
      expect(changes, [false, true]);
    });

    testWidgets('a controlled group follows its caller', (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 216,
            child: SidebarGroup(
              label: Text('프로젝트'),
              expanded: false,
              children: [Text('하위')],
            ),
          ),
        ),
      );
      expect(find.text('하위'), findsNothing);
      await tester.tap(find.text('프로젝트'));
      await tester.pumpAndSettle();
      expect(find.text('하위'), findsNothing);
    });
  });
}
