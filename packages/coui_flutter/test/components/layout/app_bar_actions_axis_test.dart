import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// A bar whose actions stand in a column beside the content keeps only the
/// actions that may not leave its row, and a column handed the same lists
/// draws the rest — so the lists are written once and every action is
/// drawn once.
Widget _icon(IconName icon) => Button(
  variant: .ghost,
  shape: .square,
  onPressed: () {},
  child: Icon(icon),
);

Widget _edit() => BarAction(
  axisBehavior: .horizontalOnly,
  child: Button(variant: .ghost, onPressed: () {}, child: const Text('Edit')),
);

List<Widget> _leading() => [_icon(LucideIcons.chevronLeft)];

List<Widget> _trailing() => [_icon(LucideIcons.share), _edit()];

AppBar _bar({
  CoreAxis actionsAxis = CoreAppBarContract.defaultActionsAxis,
  List<Widget>? leading,
  List<Widget>? trailing,
}) => AppBar(
  title: const Text('Inbox'),
  actionsAxis: actionsAxis,
  leading: leading ?? _leading(),
  trailing: trailing ?? _trailing(),
);

Iterable<IconName?> _glyphs(WidgetTester tester, Finder of) => tester
    .widgetList<Icon>(find.descendant(of: of, matching: find.byType(Icon)))
    .map((icon) => icon.icon);

void main() {
  testWidgets('a bar draws every action in its own row by default', (
    tester,
  ) async {
    await pumpTestApp(tester, _bar());

    expect(_glyphs(tester, find.byType(AppBar)), [
      LucideIcons.chevronLeft,
      LucideIcons.share,
    ]);
    expect(find.text('Edit'), findsOneWidget);
  });

  for (final surfaceStyle in [
    CoreSurfaceStyleId.defaultId,
    CoreSurfaceStyleId.liquidGlass,
  ]) {
    group('with its actions in a column (${surfaceStyle.name})', () {
      testWidgets('the bar keeps the horizontal-only action alone', (
        tester,
      ) async {
        await pumpTestApp(
          tester,
          _bar(actionsAxis: .vertical),
          surfaceStyle: surfaceStyle,
        );

        expect(_glyphs(tester, find.byType(AppBar)), isEmpty);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Inbox'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the column draws the rest: each action exactly once', (
        tester,
      ) async {
        final leading = _leading();
        final trailing = _trailing();
        await pumpTestApp(
          tester,
          SizedBox(
            width: 600,
            child: Row(
              children: [
                Expanded(
                  child: _bar(
                    actionsAxis: .vertical,
                    leading: leading,
                    trailing: trailing,
                  ),
                ),
                ToolbarGroup(
                  ariaLabel: 'Page actions',
                  direction: .vertical,
                  children: [...leading, ...trailing],
                ),
              ],
            ),
          ),
          surfaceStyle: surfaceStyle,
        );

        expect(_glyphs(tester, find.byType(AppBar)), isEmpty);
        expect(_glyphs(tester, find.byType(ToolbarGroup)), [
          LucideIcons.chevronLeft,
          LucideIcons.share,
        ]);
        expect(find.text('Edit'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ToolbarGroup),
            matching: find.text('Edit'),
          ),
          findsNothing,
        );
        expect(find.byType(Button), findsNWidgets(3));
      });
    });
  }

  testWidgets('a bar left with no leading action starts with its title', (
    tester,
  ) async {
    await pumpTestApp(tester, _bar(leading: const []));
    final withoutLeading = tester.getTopLeft(find.text('Inbox')).dx;

    await tester.pumpWidget(const SizedBox());
    await pumpTestApp(tester, _bar(actionsAxis: .vertical));

    // The moved back button leaves no empty cluster behind it.
    expect(tester.getTopLeft(find.text('Inbox')).dx, withoutLeading);
  });

  testWidgets('a kept group keeps its own capsule under glass', (tester) async {
    await pumpTestApp(
      tester,
      _bar(
        actionsAxis: .vertical,
        trailing: [
          _icon(LucideIcons.share),
          BarAction(
            axisBehavior: .horizontalOnly,
            child: ToolbarGroup(
              ariaLabel: 'Edit',
              children: [_edit()],
            ),
          ),
        ],
      ),
      surfaceStyle: .liquidGlass,
    );

    // The marked group is one capsule of its own — not a capsule the bar
    // wrapped around a capsule.
    expect(find.byType(Popup), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(_glyphs(tester, find.byType(AppBar)), isEmpty);
  });

  testWidgets('a style chain keeps where the actions stand', (tester) async {
    final bar = _bar(actionsAxis: .vertical).surface;

    expect(bar.actionsAxis, CoreAxis.vertical);
  });
}
