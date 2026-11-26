// The Dialog actions row under CoreDialogActionsLayout: `end` keeps the
// wrapping row at the panel's end, `stretch` gives every action an equal
// share of the width. Where a stretched action lands is pinned by the vector
// table coui_core shares with the Web footer probe, so a fix that lands on
// one platform fails the other.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/overlay/dialog/dialog_actions_stretch_layout.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The vector table shared with the Core placement test and the Chrome
/// footer probe (cwd is `packages/coui_flutter` under `flutter test`).
const String _kVectorsPath =
    '../coui_core/test/fixtures/dialog_actions_stretch_vectors.json';

const _kBody = ValueKey<String>('dialog-actions-body');
const _kAction1 = ValueKey<String>('dialog-actions-1');
const _kAction2 = ValueKey<String>('dialog-actions-2');
const _kAction3 = ValueKey<String>('dialog-actions-3');

const CoreDialogStyle _kStretch = CoreDialogStyle(actionsLayout: .stretch);

/// Opens a `Dialog` through `showDialog` on a [width] × [height] screen at
/// [textScale] and leaves it settled.
Future<void> _openDialog(
  WidgetTester tester, {
  required List<Widget> actions,
  double width = 360,
  double height = 640,
  double textScale = 1,
  TextDirection textDirection = .ltr,
  CoreDialogStyle? dialogStyle,
  ThemeData theme = const ThemeData(),
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, height);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Theme(
      data: theme,
      child: material.MaterialApp(
        // Above the navigator, so the route the dialog pushes reads both.
        builder: (context, child) => material.MediaQuery(
          data: material.MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: material.Directionality(
            textDirection: textDirection,
            child: child!,
          ),
        ),
        home: material.Builder(
          builder: (context) => material.GestureDetector(
            onTap: () => unawaited(
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  title: const material.Text('Confirm'),
                  content: const material.Text('Body', key: _kBody),
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
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The body column the actions row shares its width with — the body's
/// scroll viewport, stretched across the panel's content box.
Rect _contentBox(WidgetTester tester) => tester.getRect(
  find.ancestor(of: find.byKey(_kBody), matching: find.byType(Scrollable)),
);

Widget _button(
  Key key,
  String label, {
  CoreButtonVariant? variant,
  Widget? leading,
}) => Button(
  key: key,
  variant: variant ?? CoreButtonVariant.primary,
  onPressed: () {},
  leading: leading,
  child: material.Text(label),
);

/// The actions `Wrap` of the open dialog — the parent of the first action.
Wrap _actionsWrap(WidgetTester tester) => tester.widget<Wrap>(
  find.ancestor(of: find.byKey(_kAction1), matching: find.byType(Wrap)).first,
);

void main() {
  group('resolveDialog — actionsLayout', () {
    Future<ResolvedDialog> resolve(
      WidgetTester tester, {
      ThemeData theme = const ThemeData(),
      CoreDialogStyle? dialogStyle,
    }) async {
      late ResolvedDialog resolved;
      await tester.pumpWidget(
        Theme(
          data: theme,
          child: material.MaterialApp(
            home: material.Builder(
              builder: (context) {
                resolved = resolveDialog(context, dialogStyle: dialogStyle);
                return const material.SizedBox();
              },
            ),
          ),
        ),
      );
      return resolved;
    }

    testWidgets('reads the Core default', (tester) async {
      final resolved = await resolve(tester);
      expect(resolved.actionsLayout, CoreDialogStyle.defaultActionsLayout);
      expect(resolved.actionsLayout, CoreDialogActionsLayout.end);
    });

    testWidgets('a stated value reaches the resolved output', (tester) async {
      final resolved = await resolve(tester, dialogStyle: _kStretch);
      expect(resolved.actionsLayout, CoreDialogActionsLayout.stretch);
    });

    testWidgets('the theme style reaches it, and the instance wins', (
      tester,
    ) async {
      const themed = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          dialog: CoreDialogTheme(style: _kStretch),
        ),
      );
      expect(
        (await resolve(tester, theme: themed)).actionsLayout,
        CoreDialogActionsLayout.stretch,
      );
      expect(
        (await resolve(
          tester,
          theme: themed,
          dialogStyle: const CoreDialogStyle(actionsLayout: .end),
        )).actionsLayout,
        CoreDialogActionsLayout.end,
      );
    });
  });

  group('DialogActionsStretchLayout against the shared vectors', () {
    final doc =
        jsonDecode(File(_kVectorsPath).readAsStringSync())
            as Map<String, Object?>;
    final spacing = (doc['spacing']! as num).toDouble();
    final runSpacing = (doc['runSpacing']! as num).toDouble();
    final partHeight = (doc['partHeight']! as num).toDouble();
    final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

    List<Map<String, Object?>> actionsOf(Map<String, Object?> c) =>
        (c['actions']! as List).cast<Map<String, Object?>>();
    // An action states its own part height, or takes the table's.
    double heightOf(Map<String, Object?> action) =>
        (action['partHeight'] as num?)?.toDouble() ?? partHeight;
    // What Flutter draws: `flutterCells` where the case states them (no
    // action is laid out wider than its row), the shared `cells` otherwise.
    List<Map<String, Object?>> cellsOf(Map<String, Object?> c) =>
        ((c['flutterCells'] ?? c['cells'])! as List)
            .cast<Map<String, Object?>>();
    List<double> partsOf(Map<String, Object?> action) => [
      for (final part in (action['parts']! as List).cast<num>())
        part.toDouble(),
    ];
    // How many rows an action's parts wrap onto at [width]: a part starts
    // the next row when the row holding others has no room left for it.
    int partRowsAt(List<double> parts, double width) {
      var rows = 1;
      var used = 0.0;
      for (final part in parts) {
        if (used > 0 && used + part > width + 1e-3) {
          rows += 1;
          used = 0;
        }
        used += part;
      }
      return rows;
    }

    test('the table is spaced the way the Dialog spaces its actions', () {
      expect(cases, isNotEmpty);
      expect(spacing, CoreDialogStyle.defaultActionSpacing);
      expect(runSpacing, CoreDialogStyle.defaultActionRunSpacing);
    });

    // Without one, the centring each case checks below holds for a
    // top-aligned line as well.
    test('the table holds a line whose actions differ in height', () {
      final mixed = cases.where((c) {
        final actions = actionsOf(c);
        final cells = cellsOf(c);
        for (var i = 0; i < actions.length; i++) {
          for (var j = i + 1; j < actions.length; j++) {
            if (cells[i]['line'] == cells[j]['line'] &&
                heightOf(actions[i]) != heightOf(actions[j])) {
              return true;
            }
          }
        }
        return false;
      });
      expect(mixed, isNotEmpty);
    });

    for (final c in cases) {
      for (final direction in TextDirection.values) {
        testWidgets('${c['name']} (${direction.name})', (tester) async {
          tester.view
            ..devicePixelRatio = 1
            ..physicalSize = const Size(800, 600);
          addTearDown(tester.view.reset);

          final width = (c['width']! as num).toDouble();
          final actions = actionsOf(c);
          final keys = [
            for (var i = 0; i < actions.length; i++) ValueKey<int>(i),
          ];
          // An action is a row of fixed parts that wraps between them: no
          // gap, so its narrowest width is its widest part and its natural
          // width the sum of its parts — the table's definition. Every part
          // is the action's part height tall.
          await tester.pumpWidget(
            material.Directionality(
              textDirection: direction,
              child: material.Center(
                child: material.SizedBox(
                  width: width,
                  child: DialogActionsStretchLayout(
                    spacing: spacing,
                    runSpacing: runSpacing,
                    children: [
                      for (var i = 0; i < actions.length; i++)
                        Wrap(
                          key: keys[i],
                          children: [
                            for (final part in partsOf(actions[i]))
                              material.SizedBox(
                                width: part,
                                height: heightOf(actions[i]),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          final row = tester.getRect(find.byType(DialogActionsStretchLayout));
          expect(row.width, width);
          final expected = cellsOf(c);
          expect(expected, hasLength(actions.length));
          final rects = [
            for (final key in keys) tester.getRect(find.byKey(key)),
          ];
          for (var i = 0; i < rects.length; i++) {
            final start = (expected[i]['start']! as num).toDouble();
            final cellWidth = (expected[i]['width']! as num).toDouble();
            final left = direction == .rtl ? width - start - cellWidth : start;
            expect(
              rects[i].left - row.left,
              closeTo(left, 1e-3),
              reason: 'action $i left',
            );
            expect(
              rects[i].width,
              closeTo(cellWidth, 1e-3),
              reason: 'action $i width',
            );
            // Each action keeps its own height — a line is not stretched
            // to its tallest.
            expect(
              rects[i].height,
              closeTo(
                partRowsAt(partsOf(actions[i]), cellWidth) *
                    heightOf(actions[i]),
                1e-3,
              ),
              reason: 'action $i height',
            );
          }

          // Lines: every action of a line centred on one line, the lines
          // `runSpacing` apart, the first at the row's top.
          final lines = <int, List<Rect>>{};
          for (var i = 0; i < rects.length; i++) {
            (lines[expected[i]['line']! as int] ??= []).add(rects[i]);
          }
          final lineIndices = lines.keys.toList()..sort();
          expect(lineIndices, [for (var k = 0; k < lines.length; k++) k]);
          double top(List<Rect> line) =>
              line.map((r) => r.top).reduce((a, b) => a < b ? a : b);
          double bottom(List<Rect> line) =>
              line.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
          expect(top(lines[0]!), closeTo(row.top, 1e-3));
          for (final k in lineIndices) {
            final line = lines[k]!;
            for (final rect in line) {
              expect(
                rect.center.dy,
                closeTo(line.first.center.dy, 1e-3),
                reason: 'line $k shares one centre',
              );
            }
            if (k > 0) {
              expect(
                top(line) - bottom(lines[k - 1]!),
                closeTo(runSpacing, 1e-3),
                reason: 'line $k sits runSpacing under line ${k - 1}',
              );
            }
          }
          expect(bottom(lines[lineIndices.last]!), closeTo(row.bottom, 1e-3));
        });
      }
    }
  });

  group('Dialog actionsLayout: stretch', () {
    testWidgets('one action fills the actions row', (tester) async {
      await _openDialog(
        tester,
        actions: [_button(_kAction1, 'OK')],
        dialogStyle: _kStretch,
      );

      expect(tester.takeException(), isNull);
      final box = _contentBox(tester);
      final a1 = tester.getRect(find.byKey(_kAction1));
      expect(a1.left, closeTo(box.left, 0.01));
      expect(a1.right, closeTo(box.right, 0.01));
    });

    testWidgets('two short actions split the row in half, in order', (
      tester,
    ) async {
      await _openDialog(
        tester,
        actions: [
          _button(_kAction1, 'No', variant: .outline),
          _button(_kAction2, 'Yes'),
        ],
        dialogStyle: _kStretch,
      );

      final box = _contentBox(tester);
      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      final half = (box.width - CoreDialogStyle.defaultActionSpacing) / 2;
      expect(a1.width, closeTo(half, 0.01));
      expect(a2.width, closeTo(half, 0.01));
      expect(a1.top, a2.top);
      expect(a1.left, closeTo(box.left, 0.01));
      expect(
        a2.left - a1.right,
        closeTo(CoreDialogStyle.defaultActionSpacing, 0.01),
      );
      expect(a2.right, closeTo(box.right, 0.01));
    });

    testWidgets('right to left the first action sits at the right', (
      tester,
    ) async {
      await _openDialog(
        tester,
        actions: [
          _button(_kAction1, 'No', variant: .outline),
          _button(_kAction2, 'Yes'),
        ],
        dialogStyle: _kStretch,
        textDirection: .rtl,
      );

      final box = _contentBox(tester);
      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      expect(a1.right, closeTo(box.right, 0.01));
      expect(a2.left, closeTo(box.left, 0.01));
      expect(
        a1.left - a2.right,
        closeTo(CoreDialogStyle.defaultActionSpacing, 0.01),
      );
    });

    testWidgets('an action too wide for its half stacks both, each the full '
        'width, in order', (tester) async {
      await _openDialog(
        tester,
        actions: [
          _button(_kAction1, 'Cancel', variant: .outline),
          _button(_kAction2, 'Delete this item forever'),
        ],
        dialogStyle: _kStretch,
      );

      expect(tester.takeException(), isNull);
      final box = _contentBox(tester);
      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      for (final rect in [a1, a2]) {
        expect(rect.left, closeTo(box.left, 0.01));
        expect(rect.right, closeTo(box.right, 0.01));
      }
      // The first action handed in stays on top.
      expect(
        a2.top - a1.bottom,
        closeTo(CoreDialogStyle.defaultActionRunSpacing, 0.01),
      );
    });

    testWidgets('a stated actionSpacing and actionRunSpacing reach the row', (
      tester,
    ) async {
      await _openDialog(
        tester,
        actions: [
          _button(_kAction1, 'No', variant: .outline),
          _button(_kAction2, 'Yes'),
          _button(_kAction3, 'Delete this item forever'),
        ],
        dialogStyle: const CoreDialogStyle(
          actionsLayout: .stretch,
          actionSpacing: CoreSpace.space16,
          actionRunSpacing: CoreSpace.space20,
        ),
      );

      final box = _contentBox(tester);
      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      final a3 = tester.getRect(find.byKey(_kAction3));
      expect(a2.left - a1.right, closeTo(CoreSpace.space16, 0.01));
      expect(a1.width, closeTo((box.width - CoreSpace.space16) / 2, 0.01));
      expect(a3.top - a1.bottom, closeTo(CoreSpace.space20, 0.01));
      expect(a3.width, closeTo(box.width, 0.01));
    });

    testWidgets('a project-wide CoreDialogTheme reaches the dialog', (
      tester,
    ) async {
      await _openDialog(
        tester,
        actions: [_button(_kAction1, 'OK')],
        theme: const ThemeData(
          coreComponentTheme: CoreComponentTheme(
            dialog: CoreDialogTheme(style: _kStretch),
          ),
        ),
      );

      expect(find.byType(DialogActionsStretchLayout), findsOneWidget);
      final box = _contentBox(tester);
      final a1 = tester.getRect(find.byKey(_kAction1));
      expect(a1.width, closeTo(box.width, 0.01));
    });

    testWidgets('a list that asks for flex distribution keeps its Row', (
      tester,
    ) async {
      await _openDialog(
        tester,
        actions: const [
          material.SizedBox(key: _kAction1, width: 60, height: 40),
          material.Spacer(),
          material.SizedBox(key: _kAction2, width: 60, height: 40),
        ],
        dialogStyle: _kStretch,
        width: 800,
        height: 900,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(DialogActionsStretchLayout), findsNothing);
      final row = tester.widget<Row>(
        find
            .ancestor(of: find.byKey(_kAction1), matching: find.byType(Row))
            .first,
      );
      expect(row.mainAxisAlignment, MainAxisAlignment.end);
      expect(row.spacing, CoreDialogStyle.defaultActionSpacing);
      final box = _contentBox(tester);
      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      expect(a1.width, 60);
      expect(a1.left, closeTo(box.left, 0.01));
      expect(a2.right, closeTo(box.right, 0.01));
    });
  });

  group('Dialog actions at text scale 2', () {
    // A `Button` with a leading slot measures its one-line width as its
    // narrowest (`IntrinsicWidth`), yet wraps its label when given less. At
    // this scale that width is wider than the row, and both layouts keep the
    // action inside the panel: the `Wrap` lays it out under the row's width,
    // the stretched row squeezes it to the row.
    for (final layout in CoreDialogActionsLayout.values) {
      testWidgets('on a 360 × 640 phone nothing overflows '
          '(${layout.name})', (tester) async {
        await _openDialog(
          tester,
          actions: [
            _button(_kAction1, 'Decline', variant: .outline),
            _button(
              _kAction2,
              'Accept terms',
              leading: const Icon(LucideIcons.check),
            ),
          ],
          dialogStyle: CoreDialogStyle(actionsLayout: layout),
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byType(DialogActionsStretchLayout),
          layout == .stretch ? findsOneWidget : findsNothing,
        );
        // The route the dialog pushes reads the scale, and its text draws
        // at it.
        expect(
          material.MediaQuery.textScalerOf(tester.element(find.byKey(_kBody))),
          const TextScaler.linear(2),
        );
        expect(
          tester
              .widget<RichText>(
                find.descendant(
                  of: find.text('Confirm'),
                  matching: find.byType(RichText),
                ),
              )
              .textScaler,
          const TextScaler.linear(2),
        );
        final box = _contentBox(tester);
        for (final key in [_kAction1, _kAction2]) {
          final rect = tester.getRect(find.byKey(key));
          expect(
            rect.left,
            greaterThanOrEqualTo(box.left - 0.01),
            reason: '$key left',
          );
          expect(
            rect.right,
            lessThanOrEqualTo(box.right + 0.01),
            reason: '$key right',
          );
        }
        for (final finder in [
          find.text('Confirm'),
          find.byKey(_kAction1),
          find.byKey(_kAction2),
          find.text('Decline'),
          find.text('Accept terms'),
        ]) {
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(360));
          expect(rect.bottom, lessThanOrEqualTo(640));
        }
      });
    }
  });

  group('Dialog actionsLayout: end', () {
    for (final style in <CoreDialogStyle?>[
      null,
      const CoreDialogStyle(actionsLayout: .end),
    ]) {
      testWidgets(
        'keeps the wrapping row at the end '
        '(${style == null ? 'not stated' : 'stated'})',
        (tester) async {
          final actions = [
            for (final key in [_kAction1, _kAction2])
              material.SizedBox(key: key, width: 60, height: 40),
          ];
          await _openDialog(tester, actions: actions, dialogStyle: style);

          expect(find.byType(DialogActionsStretchLayout), findsNothing);
          final wrap = _actionsWrap(tester);
          expect(wrap.alignment, WrapAlignment.end);
          expect(wrap.spacing, CoreDialogStyle.defaultActionSpacing);
          expect(wrap.runSpacing, CoreDialogStyle.defaultActionRunSpacing);
          expect(wrap.crossAxisAlignment, WrapCrossAlignment.center);
          expect(wrap.direction, Axis.horizontal);
          expect(wrap.runAlignment, WrapAlignment.start);
          expect(wrap.textDirection, isNull);
          expect(wrap.clipBehavior, Clip.none);
          expect(wrap.children, actions);
          // Each action its own width, the last at the end.
          final box = _contentBox(tester);
          expect(tester.getRect(find.byKey(_kAction1)).width, 60);
          expect(
            tester.getRect(find.byKey(_kAction2)).right,
            closeTo(box.right, 0.01),
          );
        },
      );
    }

    testWidgets('a stated actionSpacing and actionRunSpacing reach the Wrap', (
      tester,
    ) async {
      await _openDialog(
        tester,
        actions: const [
          material.SizedBox(key: _kAction1, width: 60, height: 40),
        ],
        dialogStyle: const CoreDialogStyle(
          actionSpacing: CoreSpace.space16,
          actionRunSpacing: CoreSpace.space20,
        ),
      );

      final wrap = _actionsWrap(tester);
      expect(wrap.spacing, CoreSpace.space16);
      expect(wrap.runSpacing, CoreSpace.space20);
    });
  });

  group('DialogActionsStretchLayout lines', () {
    // The centring the table's mixed-height case pins, with the offsets
    // stated outright.
    testWidgets('actions of different heights share one centre down the '
        'line', (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          material.Directionality(
            textDirection: direction,
            child: const material.Center(
              child: material.SizedBox(
                width: 294,
                child: DialogActionsStretchLayout(
                  spacing: CoreSpace.space8,
                  runSpacing: CoreSpace.space8,
                  children: [
                    material.SizedBox(key: _kAction1, width: 60, height: 40),
                    material.SizedBox(key: _kAction2, width: 60, height: 64),
                  ],
                ),
              ),
            ),
          ),
        );

        final row = tester.getRect(find.byType(DialogActionsStretchLayout));
        final a1 = tester.getRect(find.byKey(_kAction1));
        final a2 = tester.getRect(find.byKey(_kAction2));
        expect(row.height, 64, reason: direction.name);
        expect(a2.top, row.top, reason: direction.name);
        expect(a1.center.dy, a2.center.dy, reason: direction.name);
        expect(a1.top - row.top, 12, reason: direction.name);
      }
    });

    testWidgets('an unbounded row is as wide as every action at the widest '
        'natural width', (tester) async {
      await tester.pumpWidget(
        const material.Directionality(
          textDirection: .ltr,
          child: material.Center(
            child: material.UnconstrainedBox(
              child: DialogActionsStretchLayout(
                spacing: CoreSpace.space8,
                runSpacing: CoreSpace.space8,
                children: [
                  material.SizedBox(key: _kAction1, width: 60, height: 40),
                  material.SizedBox(key: _kAction2, width: 100, height: 40),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byType(DialogActionsStretchLayout));
      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      expect(row.width, 100 * 2 + CoreSpace.space8);
      expect(a1.width, 100);
      expect(a2.width, 100);
      expect(a1.top, a2.top);
      expect(a2.left - a1.right, CoreSpace.space8);
    });
  });

  group('DialogActionsStretchLayout updates', () {
    // Three actions on a 300 row: the first two share a line, the third
    // takes the next — so the spacing, the run spacing and the start side
    // each move a rect.
    Widget row({
      required double spacing,
      required double runSpacing,
      TextDirection? textDirection,
    }) => material.Directionality(
      textDirection: .ltr,
      child: material.Center(
        child: material.SizedBox(
          width: 300,
          child: DialogActionsStretchLayout(
            spacing: spacing,
            runSpacing: runSpacing,
            textDirection: textDirection,
            children: const [
              material.SizedBox(key: _kAction1, width: 100, height: 40),
              material.SizedBox(key: _kAction2, width: 100, height: 40),
              material.SizedBox(key: _kAction3, width: 200, height: 40),
            ],
          ),
        ),
      ),
    );

    testWidgets('the same row re-pumped takes the new spacing, run spacing '
        'and direction', (tester) async {
      Rect at(Key key) {
        final origin = tester
            .getRect(find.byType(DialogActionsStretchLayout))
            .topLeft;
        return tester.getRect(find.byKey(key)).shift(-origin);
      }

      await tester.pumpWidget(row(spacing: 8, runSpacing: 8));
      final render = tester.renderObject(
        find.byType(DialogActionsStretchLayout),
      );
      // Share (300 − 16) / 3; the line's free width splits 146 / 146.
      expect(at(_kAction1), const Rect.fromLTWH(0, 0, 146, 40));
      expect(at(_kAction2), const Rect.fromLTWH(154, 0, 146, 40));
      expect(at(_kAction3), const Rect.fromLTWH(0, 48, 300, 40));

      await tester.pumpWidget(
        row(spacing: 16, runSpacing: 20, textDirection: .rtl),
      );
      expect(
        tester.renderObject(find.byType(DialogActionsStretchLayout)),
        same(render),
      );
      // Share (300 − 32) / 3; the line splits 142 / 142, from the right.
      expect(at(_kAction1), const Rect.fromLTWH(158, 0, 142, 40));
      expect(at(_kAction2), const Rect.fromLTWH(0, 0, 142, 40));
      expect(at(_kAction3), const Rect.fromLTWH(0, 60, 300, 40));

      // No direction stated: the ambient one.
      await tester.pumpWidget(row(spacing: 16, runSpacing: 20));
      expect(at(_kAction1), const Rect.fromLTWH(0, 0, 142, 40));
      expect(at(_kAction2), const Rect.fromLTWH(158, 0, 142, 40));
    });
  });

  group('DialogActionsStretchLayout intrinsic sizes', () {
    Future<void> pumpActions(
      WidgetTester tester,
      Widget Function(Widget actions) wrap,
    ) async {
      await tester.pumpWidget(
        Theme(
          data: const ThemeData(),
          child: material.MaterialApp(
            home: material.Center(
              child: wrap(
                DialogActionsStretchLayout(
                  spacing: CoreDialogStyle.defaultActionSpacing,
                  runSpacing: CoreDialogStyle.defaultActionRunSpacing,
                  children: [
                    _button(_kAction1, 'No', variant: .outline),
                    _button(_kAction2, 'Delete'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('IntrinsicWidth shares one line, each the widest natural '
        'width', (tester) async {
      await pumpActions(tester, (actions) => IntrinsicWidth(child: actions));

      expect(tester.takeException(), isNull);
      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      expect(a1.top, a2.top);
      expect(a1.width, closeTo(a2.width, 0.01));
      final render = tester.renderObject<RenderBox>(find.byKey(_kAction2));
      expect(
        a2.width,
        closeTo(render.getMaxIntrinsicWidth(double.infinity), 0.01),
      );
    });

    testWidgets('IntrinsicHeight and the intrinsic queries answer', (
      tester,
    ) async {
      await pumpActions(
        tester,
        (actions) => material.SizedBox(
          width: 200,
          child: IntrinsicHeight(child: actions),
        ),
      );

      expect(tester.takeException(), isNull);
      final render = tester.renderObject<RenderDialogActionsStretchLayout>(
        find.byType(DialogActionsStretchLayout),
      );
      // Stacked at 200 (`Delete` is wider than its half): two lines,
      // runSpacing apart.
      final a1 = tester.getRect(find.byKey(_kAction1));
      final a2 = tester.getRect(find.byKey(_kAction2));
      expect(
        a2.top - a1.bottom,
        closeTo(CoreDialogStyle.defaultActionRunSpacing, 0.01),
      );
      expect(render.getMinIntrinsicHeight(200), render.size.height);
      expect(render.getMaxIntrinsicHeight(200), render.size.height);
      expect(
        render.getDryLayout(const BoxConstraints.tightFor(width: 200)),
        render.size,
      );
      expect(
        render.getMinIntrinsicWidth(double.infinity),
        greaterThan(0),
      );
      expect(
        render.getMaxIntrinsicWidth(double.infinity),
        greaterThan(render.getMinIntrinsicWidth(double.infinity)),
      );
      expect(
        render.getDryLayout(const BoxConstraints()).width,
        render.getMaxIntrinsicWidth(double.infinity),
      );
    });

    testWidgets("the min intrinsic width is the widest action's narrowest "
        'width', (tester) async {
      // Narrowest / natural: 50 / 100, 70 / 70, 30 / 60 — the widest
      // narrowest (70) is neither the widest natural (100) nor the sum.
      await tester.pumpWidget(
        material.Directionality(
          textDirection: .ltr,
          child: material.Center(
            child: material.SizedBox(
              width: 300,
              child: DialogActionsStretchLayout(
                spacing: CoreSpace.space8,
                runSpacing: CoreSpace.space8,
                children: [
                  Wrap(
                    children: [
                      for (final part in [50.0, 50.0])
                        material.SizedBox(width: part, height: 40),
                    ],
                  ),
                  const material.SizedBox(width: 70, height: 40),
                  Wrap(
                    children: [
                      for (final part in [30.0, 30.0])
                        material.SizedBox(width: part, height: 40),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final render = tester.renderObject<RenderDialogActionsStretchLayout>(
        find.byType(DialogActionsStretchLayout),
      );
      expect(render.getMinIntrinsicWidth(double.infinity), 70);
      expect(
        render.getMaxIntrinsicWidth(double.infinity),
        100 * 3 + CoreSpace.space8 * 2,
      );
    });

    // Lines of text in two sizes: one shared line at 400, stacked at 200.
    // The laid-out baseline is read the way a parent reads it — a
    // `Baseline` puts the row's baseline 100 below its own top.
    for (final width in [400.0, 200.0]) {
      testWidgets('the dry baseline is the laid-out baseline at $width', (
        tester,
      ) async {
        const kBaseline = ValueKey<String>('baseline');
        await tester.pumpWidget(
          material.Directionality(
            textDirection: .ltr,
            child: material.Center(
              child: material.SizedBox(
                width: width,
                child: const material.Baseline(
                  key: kBaseline,
                  baseline: 100,
                  baselineType: .alphabetic,
                  child: DialogActionsStretchLayout(
                    spacing: CoreSpace.space8,
                    runSpacing: CoreSpace.space8,
                    children: [
                      material.Text('No', style: TextStyle(fontSize: 14)),
                      material.Text('Delete', style: TextStyle(fontSize: 28)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final render = tester.renderObject<RenderDialogActionsStretchLayout>(
          find.byType(DialogActionsStretchLayout),
        );
        final rowTop = tester
            .getRect(find.byType(DialogActionsStretchLayout))
            .top;
        final laid = 100 - (rowTop - tester.getRect(find.byKey(kBaseline)).top);
        // `No` (14 tall, its baseline 10.5 down in the test font) is the
        // highest baseline: centred down the 28 line it shares with
        // `Delete` at 400, alone on the first line at 200.
        expect(laid, width == 400 ? 7 + 10.5 : 10.5);
        expect(
          render.getDryBaseline(render.constraints, .alphabetic),
          closeTo(laid, 1e-6),
        );
      });
    }

    testWidgets('a row narrower than an action squeezes it to the row, and '
        'the intrinsic and dry queries agree', (tester) async {
      await tester.pumpWidget(
        Theme(
          data: const ThemeData(),
          child: material.MaterialApp(
            home: material.Center(
              child: material.SizedBox(
                width: 120,
                child: IntrinsicHeight(
                  child: DialogActionsStretchLayout(
                    spacing: CoreDialogStyle.defaultActionSpacing,
                    runSpacing: CoreDialogStyle.defaultActionRunSpacing,
                    children: [
                      _button(
                        _kAction1,
                        'Accept terms',
                        leading: const Icon(LucideIcons.check),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final action = tester.renderObject<RenderBox>(find.byKey(_kAction1));
      // `IntrinsicWidth` reports the one-line width as the narrowest.
      expect(action.getMinIntrinsicWidth(double.infinity), greaterThan(120));
      final render = tester.renderObject<RenderDialogActionsStretchLayout>(
        find.byType(DialogActionsStretchLayout),
      );
      final row = tester.getRect(find.byType(DialogActionsStretchLayout));
      final a1 = tester.getRect(find.byKey(_kAction1));
      expect(a1.left, row.left);
      expect(a1.width, 120);
      expect(render.getMinIntrinsicHeight(120), render.size.height);
      expect(render.getMaxIntrinsicHeight(120), render.size.height);
      expect(
        render.getDryLayout(const BoxConstraints.tightFor(width: 120)),
        render.size,
      );
    });
  });
}
