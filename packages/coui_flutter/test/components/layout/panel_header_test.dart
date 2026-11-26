import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/page_header/header_wrap_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// A fixed-size action, so the arithmetic of the row is exact.
const _actionBox = SizedBox(width: 60, height: 32);

Future<void> _pump(
  WidgetTester tester,
  Widget header, {
  double width = 400,
  TextDirection textDirection = .ltr,
}) => pumpTestApp(
  tester,
  SizedBox(width: width, child: header),
  textDirection: textDirection,
);

PanelHeader _header({
  Widget? action = _actionBox,
  int headingLevel = CorePanelHeaderContract.defaultHeadingLevel,
  CorePanelHeaderStyle? style,
}) => PanelHeader(
  title: const Text('Recent'),
  action: action,
  headingLevel: headingLevel,
  panelHeaderStyle: style,
);

Rect _title(WidgetTester tester) => tester.getRect(find.text('Recent'));

Rect _action(WidgetTester tester) => tester.getRect(find.byWidget(_actionBox));

void main() {
  group('PanelHeader', () {
    testWidgets('the title takes titleMedium in onSurface', (tester) async {
      await _pump(tester, _header());

      final style = tester
          .widget<DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('Recent'),
                  matching: find.byType(DefaultTextStyle),
                )
                .first,
          )
          .style;
      expect(style.fontSize, 18);
      expect(style.fontWeight, FontWeight.w600);
      expect(
        style.color,
        Theme.of(tester.element(find.byType(PanelHeader))).colorScheme
            .resolve(const CoreColor.token(CoreColors.onSurface))
            .toValue(),
      );
    });

    testWidgets('a row: the action at the end, centred on the title, space8 '
        'under it', (tester) async {
      await _pump(tester, _header());

      final title = _title(tester);
      final action = _action(tester);
      final header = tester.getRect(find.byType(PanelHeader));
      expect(action.right, header.right);
      expect(action.center.dy, title.center.dy);
      expect(header.bottom - action.bottom, CoreSpace.space8);
      expect(title.left, header.left);
    });

    testWidgets('the threshold is the narrowest title width', (tester) async {
      // 128 + 8 + 60 = 196: still one row.
      await _pump(tester, _header(), width: 196);
      expect(_action(tester).center.dy, _title(tester).center.dy);
    });

    testWidgets('one pixel short moves the action under the title', (
      tester,
    ) async {
      await _pump(tester, _header(), width: 195);

      final title = _title(tester);
      final action = _action(tester);
      final header = tester.getRect(find.byType(PanelHeader));
      expect(action.left, header.left);
      expect(action.top - title.bottom, greaterThanOrEqualTo(8));
      expect(tester.takeException(), isNull);
    });

    testWidgets('right to left puts the action at the left', (tester) async {
      await _pump(tester, _header(), textDirection: .rtl);

      final header = tester.getRect(find.byType(PanelHeader));
      expect(_action(tester).left, header.left);
    });

    testWidgets('no action: no wrap layout', (tester) async {
      await _pump(tester, _header(action: null));

      expect(find.byType(HeaderWrapLayout), findsNothing);
    });

    testWidgets('the title is a heading of level 2 by default', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _header());

      expect(
        tester
            .getSemantics(find.text('Recent'))
            .getSemanticsData()
            .headingLevel,
        2,
      );
      semantics.dispose();
    });

    testWidgets('withStyle merges into the slot', (tester) async {
      // A wider title floor than the row leaves: the action wraps at 400.
      await _pump(
        tester,
        _header().withStyle(
          const CorePanelHeaderStyle(
            minTitleWidth: 360,
            padding: CoreEdgeInsets.zero,
          ),
        ),
      );

      final header = tester.getRect(find.byType(PanelHeader));
      expect(_action(tester).left, header.left);
      expect(header.bottom, _action(tester).bottom);
    });
  });
}
