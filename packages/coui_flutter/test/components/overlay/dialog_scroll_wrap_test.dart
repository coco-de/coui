import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _kBody = ValueKey<String>('dialog-scroll-body');
const _kAction1 = ValueKey<String>('dialog-wrap-action-1');
const _kAction2 = ValueKey<String>('dialog-wrap-action-2');
const _kAction3 = ValueKey<String>('dialog-wrap-action-3');

/// A body taller than any phone: forty lines of text in one column.
Widget _longBody() => material.Column(
  key: _kBody,
  crossAxisAlignment: .start,
  children: [
    for (var i = 0; i < 40; i++) material.Text('Line $i of the terms.'),
  ],
);

/// Fixed-size action boxes, so the measurements do not depend on a
/// `Button`'s own metrics.
List<Widget> _boxes(double width) => [
  for (final key in [_kAction1, _kAction2, _kAction3])
    material.SizedBox(key: key, width: width, height: 40),
];

/// Opens a `Dialog` through `showDialog` on a [width] × [height] screen at
/// [textScale] and leaves it settled.
Future<void> _openDialog(
  WidgetTester tester, {
  required Widget? content,
  List<Widget>? actions,
  double width = 360,
  double height = 640,
  double textScale = 1,
  CoreDialogStyle? dialogStyle,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, height);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Theme(
      data: const ThemeData(),
      child: material.MaterialApp(
        home: material.Builder(
          builder: (context) => material.MediaQuery(
            data: material.MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: material.Builder(
              builder: (context) => material.GestureDetector(
                onTap: () => unawaited(
                  showDialog<void>(
                    context: context,
                    builder: (_) => Dialog(
                      title: const material.Text('Terms'),
                      content: content,
                      actions: actions,
                      dialogStyle: dialogStyle,
                    ),
                  ),
                ),
                child: const material.Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The scroll position of the dialog body.
ScrollPosition _bodyPosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.ancestor(of: find.byKey(_kBody), matching: find.byType(Scrollable)),
    )
    .position;

Rect _viewport(WidgetTester tester) => tester.getRect(
  find.ancestor(of: find.byKey(_kBody), matching: find.byType(Scrollable)),
);

void main() {
  group('resolveDialog — body clip and wrapped actions', () {
    testWidgets('reads the Core defaults', (tester) async {
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
        resolved.actionRunSpacing,
        CoreDialogStyle.defaultActionRunSpacing,
      );
      expect(
        resolved.contentClipMargin,
        CoreDialogStyle.defaultContentClipMargin,
      );
    });

    testWidgets('a stated value reaches the resolved output', (tester) async {
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
                    actionRunSpacing: CoreSpace.space16,
                    contentClipMargin: CoreSpace.space8,
                  ),
                );
                return const material.SizedBox();
              },
            ),
          ),
        ),
      );

      expect(resolved.actionRunSpacing, CoreSpace.space16);
      expect(resolved.contentClipMargin, CoreSpace.space8);
    });
  });

  group('Dialog body taller than the screen', () {
    testWidgets('scrolls on its own; the title and the actions stay put', (
      tester,
    ) async {
      await _openDialog(tester, content: _longBody(), actions: _boxes(80));

      expect(tester.takeException(), isNull);
      final position = _bodyPosition(tester);
      expect(position.maxScrollExtent, greaterThan(0));

      final titleBefore = tester.getRect(find.text('Terms'));
      final actionBefore = tester.getRect(find.byKey(_kAction1));
      final lineBefore = tester.getRect(find.text('Line 0 of the terms.'));
      await tester.drag(
        find.text('Line 5 of the terms.'),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      expect(position.pixels, greaterThan(0));
      expect(tester.getRect(find.text('Terms')), titleBefore);
      expect(tester.getRect(find.byKey(_kAction1)), actionBefore);
      expect(
        tester.getRect(find.text('Line 0 of the terms.')).top,
        lessThan(lineBefore.top),
      );
    });

    testWidgets('the panel stops at the screen less the route room', (
      tester,
    ) async {
      await _openDialog(tester, content: _longBody(), actions: _boxes(80));

      final panel = tester.getRect(
        find
            .ancestor(
              of: find.text('Terms'),
              matching: find.byType(InsetShadow),
            )
            .first,
      );
      expect(panel.top, CoreDialogStyle.defaultRoutePadding);
      expect(panel.bottom, 640 - CoreDialogStyle.defaultRoutePadding);
      // The actions are inside the panel, not pushed past its bottom.
      expect(
        tester.getRect(find.byKey(_kAction1)).bottom,
        lessThan(panel.bottom),
      );
    });

    testWidgets('at text scale 2 on a 360 × 640 phone nothing overflows', (
      tester,
    ) async {
      await _openDialog(
        tester,
        content: _longBody(),
        actions: [
          Button(
            variant: .outline,
            onPressed: () {},
            child: const material.Text('Decline'),
          ),
          Button(onPressed: () {}, child: const material.Text('Accept terms')),
        ],
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(_bodyPosition(tester).maxScrollExtent, greaterThan(0));
      // Every part of the panel is on screen.
      for (final finder in [
        find.text('Terms'),
        find.text('Decline'),
        find.text('Accept terms'),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(640));
        expect(rect.right, lessThanOrEqualTo(360));
      }
    });
  });

  group('Dialog body that fits', () {
    testWidgets('does not scroll', (tester) async {
      await _openDialog(
        tester,
        content: const material.Text('Short body.', key: _kBody),
        actions: _boxes(80),
        width: 800,
        height: 900,
      );

      expect(_bodyPosition(tester).maxScrollExtent, 0);
    });

    testWidgets('keeps what it paints within contentClipMargin of its box', (
      tester,
    ) async {
      await _openDialog(
        tester,
        content: const material.Text('Short body.', key: _kBody),
        width: 800,
        height: 900,
      );

      final clip = tester.renderObject<RenderClipRect>(
        find
            .ancestor(
              of: find.byKey(_kBody),
              matching: find.byWidgetPredicate(
                (widget) => widget is ClipRect && widget.clipper != null,
              ),
            )
            .first,
      );
      final size = clip.size;
      expect(
        clip.clipper!.getClip(size),
        (Offset.zero & size).inflate(CoreDialogStyle.defaultContentClipMargin),
      );
      // The clip sits around the viewport itself.
      expect(clip.localToGlobal(Offset.zero) & size, _viewport(tester));
    });
  });

  group('Dialog actions', () {
    testWidgets('that fit sit on one line at the end, actionSpacing apart', (
      tester,
    ) async {
      await _openDialog(
        tester,
        content: const material.Text('Body', key: _kBody),
        actions: _boxes(60),
        width: 800,
        height: 900,
      );

      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      final a3 = tester.getRect(find.byKey(_kAction3));
      expect(a1.top, a2.top);
      expect(a2.top, a3.top);
      expect(a2.left - a1.right, CoreDialogStyle.defaultActionSpacing);
      expect(a3.left - a2.right, CoreDialogStyle.defaultActionSpacing);
      final body = tester.getRect(find.byKey(_kBody));
      // At the end: the last action's right edge is the body's right edge.
      expect(a3.right, closeTo(_viewport(tester).right, 0.01));
      expect(body.left, lessThan(a1.left));
    });

    testWidgets('that do not fit wrap onto rows actionRunSpacing apart, each '
        'at the end', (tester) async {
      // 360 screen − 2 × 16 route room − 2 × (24 padding + 1 border) = 278
      // of room: two 130 boxes fit with the 8 gap (268), a third does not.
      await _openDialog(
        tester,
        content: const material.Text('Body', key: _kBody),
        actions: _boxes(130),
      );

      expect(tester.takeException(), isNull);
      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      final a3 = tester.getRect(find.byKey(_kAction3));
      expect(a1.top, a2.top);
      expect(a3.top - a1.bottom, CoreDialogStyle.defaultActionRunSpacing);
      final end = _viewport(tester).right;
      expect(a2.right, closeTo(end, 0.01));
      expect(a3.right, closeTo(end, 0.01));
    });

    testWidgets('a stated actionRunSpacing moves only the gap between rows', (
      tester,
    ) async {
      await _openDialog(
        tester,
        content: const material.Text('Body', key: _kBody),
        actions: _boxes(130),
        dialogStyle: const CoreDialogStyle(actionRunSpacing: CoreSpace.space20),
      );

      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      final a3 = tester.getRect(find.byKey(_kAction3));
      expect(a2.left - a1.right, CoreDialogStyle.defaultActionSpacing);
      expect(a3.top - a1.bottom, CoreSpace.space20);
    });

    testWidgets(
      'a list that asks for flex distribution keeps its single line',
      (tester) async {
        await _openDialog(
          tester,
          content: const material.Text('Body', key: _kBody),
          actions: const [
            material.SizedBox(key: _kAction1, width: 60, height: 40),
            material.Spacer(),
            material.SizedBox(key: _kAction2, width: 60, height: 40),
          ],
          width: 800,
          height: 900,
        );

        expect(tester.takeException(), isNull);
        final a1 = tester.getRect(find.byKey(_kAction1));
        final a2 = tester.getRect(find.byKey(_kAction2));
        final body = _viewport(tester);
        expect(a1.top, a2.top);
        // The spacer took the room between them: one at each end.
        expect(a1.left, closeTo(body.left, 0.01));
        expect(a2.right, closeTo(body.right, 0.01));
      },
    );
  });

  group('Dialog(open:) closes its own route', () {
    Widget app(Widget home, GlobalKey<material.NavigatorState> navKey) => Theme(
      data: const ThemeData(),
      child: material.MaterialApp(navigatorKey: navKey, home: home),
    );

    testWidgets('open → false with another dialog on top closes this one', (
      tester,
    ) async {
      final navKey = GlobalKey<material.NavigatorState>();
      late material.StateSetter setOuter;
      var openA = true;
      await tester.pumpWidget(
        app(
          material.StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Dialog(
                open: openA,
                title: const material.Text('Dialog A'),
                onClose: () => setState(() => openA = false),
              );
            },
          ),
          navKey,
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        showDialog<void>(
          context: navKey.currentContext!,
          builder: (_) => const Dialog(title: material.Text('Dialog B')),
        ),
      );
      await tester.pumpAndSettle();

      setOuter(() => openA = false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dialog A'), findsNothing);
      expect(find.text('Dialog B'), findsOneWidget);
    });

    testWidgets('a host removed under a page opened over the dialog takes '
        'only the dialog with it', (tester) async {
      final navKey = GlobalKey<material.NavigatorState>();
      late material.StateSetter setOuter;
      var show = true;
      await tester.pumpWidget(
        app(
          material.StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return show
                  ? Dialog(
                      title: const material.Text('Dialog A'),
                      onClose: () {},
                    )
                  : const material.Text('host gone');
            },
          ),
          navKey,
        ),
      );
      await tester.pumpAndSettle();
      navKey.currentState!.push(
        material.MaterialPageRoute<void>(
          builder: (_) => const material.Text('page over the dialog'),
        ),
      );
      await tester.pumpAndSettle();

      setOuter(() => show = false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('page over the dialog'), findsOneWidget);
      expect(find.text('Dialog A', skipOffstage: false), findsNothing);
    });

    testWidgets('a host removed while its dialog is on top closes it', (
      tester,
    ) async {
      final navKey = GlobalKey<material.NavigatorState>();
      late material.StateSetter setOuter;
      var show = true;
      await tester.pumpWidget(
        app(
          material.StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return show
                  ? Dialog(
                      title: const material.Text('Dialog A'),
                      onClose: () {},
                    )
                  : const material.Text('host gone');
            },
          ),
          navKey,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dialog A'), findsOneWidget);

      setOuter(() => show = false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dialog A'), findsNothing);
      expect(find.text('host gone'), findsOneWidget);
    });
  });
}
