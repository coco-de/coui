import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kActions = ValueKey<String>('dialog-layout-actions');
const _kActionsHeight = 40.0;

/// Opens a `Dialog` through `showDialog` on a [width]-wide screen and leaves
/// it settled. The actions are a keyed fixed-height box so the measurements do
/// not depend on a `Button`'s own metrics.
Future<void> _openDialog(
  WidgetTester tester, {
  required double width,
  bool withContent = true,
  CoreDialogStyle? dialogStyle,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Theme(
      data: const ThemeData(),
      child: material.MaterialApp(
        home: material.Builder(
          builder: (context) => material.GestureDetector(
            onTap: () => unawaited(
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  title: const material.Text('Title'),
                  content: withContent ? const material.Text('Body') : null,
                  actions: const [
                    material.SizedBox(
                      key: _kActions,
                      width: 80,
                      height: _kActionsHeight,
                    ),
                  ],
                  dialogStyle: dialogStyle,
                ),
              ),
            ),
            child: const material.Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder get _panel => find
    .ancestor(of: find.text('Title'), matching: find.byType(InsetShadow))
    .first;

void main() {
  group('resolveDialog panel layout', () {
    testWidgets('reads the Core panel defaults', (tester) async {
      late ResolvedDialog resolved;
      await tester.pumpWidget(
        Theme(
          data: const ThemeData(),
          child: material.MaterialApp(
            home: material.Builder(
              builder: (context) {
                resolved = resolveDialog(context);
                return const material.SizedBox();
              },
            ),
          ),
        ),
      );

      expect(
        resolved.panelPadding,
        const EdgeInsets.fromLTRB(
          CoreSpace.space24,
          CoreSpace.space24,
          CoreSpace.space24,
          CoreSpace.space20,
        ),
      );
      expect(resolved.panelMinWidth, CoreLayout.layout280);
      expect(resolved.panelMaxWidth, CoreLayout.layout560);
      expect(resolved.sectionGapStyle.size, CoreSpace.space14);
      expect(resolved.actionsGapStyle.size, CoreSpace.space20);
    });

    testWidgets('a stated actionsGapStyle reaches the resolved slot', (
      tester,
    ) async {
      late ResolvedDialog resolved;
      await tester.pumpWidget(
        Theme(
          data: const ThemeData(),
          child: material.MaterialApp(
            home: material.Builder(
              builder: (context) {
                resolved = resolveDialog(
                  context,
                  dialogStyle: const CoreDialogStyle(
                    actionsGapStyle: CoreGapStyle(size: CoreSpace.space32),
                  ),
                );
                return const material.SizedBox();
              },
            ),
          ),
        ),
      );

      expect(resolved.actionsGapStyle.size, CoreSpace.space32);
      expect(resolved.sectionGapStyle.size, CoreSpace.space14);
    });
  });

  group('Dialog panel layout, as rendered', () {
    testWidgets('the header sits 14 above the body and the body 20 above the '
        'actions', (tester) async {
      await _openDialog(tester, width: 800);

      final titleBottom = tester.getBottomLeft(find.text('Title')).dy;
      final bodyTop = tester.getTopLeft(find.text('Body')).dy;
      final bodyBottom = tester.getBottomLeft(find.text('Body')).dy;
      final actionsTop = tester.getTopLeft(find.byKey(_kActions)).dy;

      expect(bodyTop - titleBottom, CoreSpace.space14);
      expect(actionsTop - bodyBottom, CoreSpace.space20);
    });

    testWidgets('without content the header sits 20 above the actions', (
      tester,
    ) async {
      await _openDialog(tester, width: 800, withContent: false);

      final titleBottom = tester.getBottomLeft(find.text('Title')).dy;
      final actionsTop = tester.getTopLeft(find.byKey(_kActions)).dy;

      expect(actionsTop - titleBottom, CoreSpace.space20);
    });

    testWidgets('a stated actionsGapStyle moves only the actions gap', (
      tester,
    ) async {
      await _openDialog(
        tester,
        width: 800,
        dialogStyle: const CoreDialogStyle(
          actionsGapStyle: CoreGapStyle(size: CoreSpace.space32),
        ),
      );

      final titleBottom = tester.getBottomLeft(find.text('Title')).dy;
      final bodyTop = tester.getTopLeft(find.text('Body')).dy;
      final bodyBottom = tester.getBottomLeft(find.text('Body')).dy;
      final actionsTop = tester.getTopLeft(find.byKey(_kActions)).dy;

      expect(bodyTop - titleBottom, CoreSpace.space14);
      expect(actionsTop - bodyBottom, CoreSpace.space32);
    });

    testWidgets('the panel pads 24 above and on both sides and 20 below', (
      tester,
    ) async {
      await _openDialog(tester, width: 800);

      final panel = tester.getRect(_panel);
      final title = tester.getRect(find.text('Title'));
      final actions = tester.getRect(find.byKey(_kActions));
      // The 1px border sits inside the panel box, ahead of the padding.
      const border = CoreStrokeWidth.stroke1;

      expect(title.top - panel.top, CoreSpace.space24 + border);
      expect(title.left - panel.left, CoreSpace.space24 + border);
      expect(panel.bottom - actions.bottom, CoreSpace.space20 + border);
    });

    testWidgets('the panel stops at 560 on a wide screen', (tester) async {
      await _openDialog(tester, width: 1200);

      expect(tester.getSize(_panel).width, CoreLayout.layout560);
    });

    testWidgets('the panel holds 280 on a 312 screen', (tester) async {
      await _openDialog(tester, width: 312);

      expect(tester.getSize(_panel).width, CoreLayout.layout280);
    });

    testWidgets('a screen narrower than the floor narrows the panel', (
      tester,
    ) async {
      await _openDialog(tester, width: 280);

      expect(
        tester.getSize(_panel).width,
        280 - 2 * CoreDialogStyle.defaultRoutePadding,
      );
    });

    testWidgets('the panel fills a phone less the route room', (tester) async {
      await _openDialog(tester, width: 390);

      expect(
        tester.getSize(_panel).width,
        390 - 2 * CoreDialogStyle.defaultRoutePadding,
      );
    });
  });
}
