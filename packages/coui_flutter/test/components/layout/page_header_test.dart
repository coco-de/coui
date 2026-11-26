import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/page_header/header_wrap_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// A fixed-size action, so the arithmetic of the row is exact.
const _action = SizedBox(width: 80, height: 40);

/// The two actions' group: 80 + 8 + 80.
const _actionsWidth = 168.0;

Future<void> _pump(
  WidgetTester tester,
  Widget header, {
  double width = 600,
  TextDirection textDirection = .ltr,
  CoreComponentTheme? componentTheme,
}) => pumpTestApp(
  tester,
  SizedBox(width: width, child: header),
  textDirection: textDirection,
  componentTheme: componentTheme,
);

PageHeader _header({
  List<Widget> actions = const [_action, _action],
  int headingLevel = CorePageHeaderContract.defaultHeadingLevel,
  CorePageHeaderStyle? style,
}) => PageHeader(
  eyebrow: const Text('Workspace'),
  title: const Text('Settings'),
  description: const Text('Everything about this workspace.'),
  actions: actions,
  headingLevel: headingLevel,
  pageHeaderStyle: style,
);

/// The title's line — the title and the actions it shares its line with.
Rect _row(WidgetTester tester) => tester.getRect(find.byType(HeaderWrapLayout));

Rect _title(WidgetTester tester) => tester.getRect(find.text('Settings'));

Rect _actions(WidgetTester tester) => tester.getRect(find.byType(Wrap));

TextStyle _ambient(WidgetTester tester, String text) => tester
    .widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    )
    .style;

Color _color(WidgetTester tester, CoreColor color) => Theme.of(
  tester.element(find.byType(PageHeader)),
).colorScheme.resolve(color).toValue();

void main() {
  group('PageHeader', () {
    testWidgets('the text lines take the header roles', (tester) async {
      await _pump(tester, _header());

      final eyebrow = _ambient(tester, 'Workspace');
      final title = _ambient(tester, 'Settings');
      final description = _ambient(tester, 'Everything about this workspace.');
      expect(eyebrow.fontSize, 15);
      expect(eyebrow.fontWeight, FontWeight.w500);
      expect(
        eyebrow.color,
        _color(tester, const CoreColor.token(CoreColors.onSurfaceVariant)),
      );
      expect(title.fontSize, 28);
      expect(title.fontWeight, FontWeight.w700);
      expect(
        title.color,
        _color(tester, const CoreColor.token(CoreColors.onSurface)),
      );
      expect(description.fontSize, 14);
      expect(
        description.color,
        _color(tester, const CoreColor.token(CoreColors.onSurfaceVariant)),
      );
    });

    testWidgets('the lines sit textSpacing apart', (tester) async {
      await _pump(tester, _header());

      final eyebrow = tester.getRect(find.text('Workspace'));
      final row = _row(tester);
      final description = tester.getRect(
        find.text('Everything about this workspace.'),
      );
      expect(row.top - eyebrow.bottom, CorePageHeaderStyle.defaultTextSpacing);
      expect(
        description.top - row.bottom,
        CorePageHeaderStyle.defaultTextSpacing,
      );
    });

    testWidgets('wide: the actions share the title line at the end, centred '
        'on it', (tester) async {
      await _pump(tester, _header());

      final title = _title(tester);
      final actions = _actions(tester);
      final header = tester.getRect(find.byType(PageHeader));
      expect(actions.width, _actionsWidth);
      expect(actions.right, header.right);
      expect(actions.center.dy, moreOrLessEquals(title.center.dy));
      expect(title.left, header.left);
      expect(title.width, 600 - _actionsWidth - 16);
      // The description sits under the line, at the header's full width.
      final description = tester.getRect(
        find.text('Everything about this workspace.'),
      );
      expect(description.left, header.left);
      expect(description.top, greaterThan(actions.bottom));
    });

    testWidgets('narrow: the actions move under the title, start aligned', (
      tester,
    ) async {
      // 300 − 168 − 16 = 116, under the 160 the title keeps.
      await _pump(tester, _header(), width: 300);

      final title = _title(tester);
      final actions = _actions(tester);
      final header = tester.getRect(find.byType(PageHeader));
      expect(title.width, 300);
      expect(actions.left, header.left);
      expect(actions.top - title.bottom, 16);
      final description = tester.getRect(
        find.text('Everything about this workspace.'),
      );
      expect(description.top, greaterThan(actions.bottom));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the threshold is the narrowest title width', (tester) async {
      // Exactly 160 left for the title: still one line.
      await _pump(tester, _header(), width: 160 + 16 + _actionsWidth);
      expect(
        _actions(tester).center.dy,
        moreOrLessEquals(_title(tester).center.dy),
      );
      expect(_title(tester).width, 160);
    });

    testWidgets('one pixel short wraps', (tester) async {
      await _pump(tester, _header(), width: 160 + 16 + _actionsWidth - 1);
      expect(_actions(tester).top, greaterThan(_title(tester).bottom));
    });

    testWidgets('very narrow: the actions wrap among themselves', (
      tester,
    ) async {
      await _pump(tester, _header(), width: 120);

      final actions = _actions(tester);
      expect(actions.width, lessThanOrEqualTo(120));
      // Two runs: 40 + 8 + 40.
      expect(actions.height, 88);
      expect(tester.takeException(), isNull);
    });

    testWidgets('right to left mirrors both arrangements', (tester) async {
      await _pump(tester, _header(), textDirection: .rtl);
      final header = tester.getRect(find.byType(PageHeader));
      expect(_actions(tester).left, header.left);
      expect(_title(tester).right, header.right);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester, _header(), width: 300, textDirection: .rtl);
      final narrow = tester.getRect(find.byType(PageHeader));
      expect(_actions(tester).right, narrow.right);
    });

    testWidgets('no actions: no wrap layout, just the lines', (tester) async {
      await _pump(tester, _header(actions: const []));

      expect(find.byType(HeaderWrapLayout), findsNothing);
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('real buttons fit the narrow row without overflow', (
      tester,
    ) async {
      await _pump(
        tester,
        _header(
          actions: [
            Button(
              variant: .secondary,
              onPressed: () {},
              child: const Text('Cancel'),
            ),
            Button(onPressed: () {}, child: const Text('Save changes')),
          ],
        ),
        width: 200,
      );
      expect(tester.takeException(), isNull);
      expect(_actions(tester).top, greaterThan(_title(tester).bottom));
    });

    testWidgets('the title is a heading of headingLevel', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _header(headingLevel: 3));

      expect(
        tester
            .getSemantics(find.text('Settings'))
            .getSemanticsData()
            .headingLevel,
        3,
      );
      semantics.dispose();
    });

    testWidgets('the default heading level is 1', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _header());

      expect(
        tester
            .getSemantics(find.text('Settings'))
            .getSemanticsData()
            .headingLevel,
        1,
      );
      semantics.dispose();
    });

    testWidgets('the project theme and the instance style both reach', (
      tester,
    ) async {
      await _pump(
        tester,
        _header(
          style: const CorePageHeaderStyle(actionSpacing: CoreSpace.space16),
        ),
        componentTheme: const CoreComponentTheme(
          pageHeader: CorePageHeaderTheme(
            style: CorePageHeaderStyle(
              textSpacing: CoreSpace.space12,
              titleTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.medium),
            ),
          ),
        ),
      );

      final eyebrow = tester.getRect(find.text('Workspace'));
      expect(_row(tester).top - eyebrow.bottom, CoreSpace.space12);
      expect(_ambient(tester, 'Settings').fontWeight, FontWeight.w500);
      expect(_ambient(tester, 'Settings').fontSize, 28);
      expect(_actions(tester).width, 80 + CoreSpace.space16 + 80);
    });

    testWidgets('withStyle merges into the slot', (tester) async {
      // A wider title floor than the line leaves: the actions wrap at 600.
      await _pump(
        tester,
        _header().withStyle(const CorePageHeaderStyle(minTextWidth: 500)),
      );

      expect(_actions(tester).top, greaterThan(_title(tester).bottom));
    });

    testWidgets('unbounded width: the title is measured by its content', (
      tester,
    ) async {
      // What a content-sized flex row does on Web: with no width to fill,
      // the line is the title's content width plus the actions, so a title
      // narrower than the floor puts the actions under it…
      Rect titleOf(String title) => tester.getRect(find.text(title));
      await pumpTestApp(
        tester,
        const UnconstrainedBox(
          child: PageHeader(title: Text('Hi'), actions: [_action, _action]),
        ),
      );
      expect(_actions(tester).top, greaterThan(titleOf('Hi').bottom));
      expect(tester.takeException(), isNull);

      // …and a title wider than the floor keeps them beside it.
      const long = 'A wider page title';
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpTestApp(
        tester,
        const UnconstrainedBox(
          child: PageHeader(title: Text(long), actions: [_action, _action]),
        ),
      );
      expect(
        _actions(tester).center.dy,
        moreOrLessEquals(titleOf(long).center.dy),
      );
      expect(_actions(tester).left, greaterThan(titleOf(long).right));
    });

    testWidgets('it answers intrinsic-size queries', (tester) async {
      await pumpTestApp(tester, IntrinsicWidth(child: _header()));

      final header = tester.getRect(find.byType(PageHeader));
      final row = tester
          .renderObject<RenderBox>(find.byType(HeaderWrapLayout))
          .getMaxIntrinsicWidth(double.infinity);
      final description = tester
          .renderObject<RenderBox>(
            find.text('Everything about this workspace.'),
          )
          .getMaxIntrinsicWidth(double.infinity);
      expect(
        header.width,
        moreOrLessEquals(row > description ? row : description),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
