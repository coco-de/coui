import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kItemCount = 3;
const _kSizedBoxWidth = 300.0;
const _kSizedBoxHeight = 400.0;

Widget _buildApp(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kSizedBoxWidth,
      height: _kSizedBoxHeight,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

Widget _item(
  BuildContext context,
  int index,
  Widget dragHandle,
  Widget? removeButton,
) {
  return material.ListTile(
    title: material.Text('Item $index'),
    trailing: dragHandle,
  );
}

/// Background colour of the row shell that owns [text].
material.Color? _rowColorOf(WidgetTester tester, String text) {
  final container = tester.widget<material.AnimatedContainer>(
    find
        .ancestor(
          of: find.text(text),
          matching: find.byType(material.AnimatedContainer),
        )
        .first,
  );
  final decoration = container.decoration;

  return decoration is material.BoxDecoration ? decoration.color : null;
}

/// Item content that hugs its own width, mirroring the docs example. What
/// the caller hands back must not be what decides the row width.
Widget _narrowItem(
  BuildContext context,
  int index,
  Widget dragHandle,
  Widget? removeButton,
) {
  return material.Row(
    mainAxisSize: material.MainAxisSize.min,
    children: [dragHandle, material.Text('Item $index')],
  );
}

/// Rendered rect of the row shell that owns [text].
Rect _rowRectOf(WidgetTester tester, String text) => tester.getRect(
  find
      .ancestor(
        of: find.text(text),
        matching: find.byType(material.AnimatedContainer),
      )
      .first,
);

/// Rendered width of the row shell that owns [text].
double _rowWidthOf(WidgetTester tester, String text) => tester
    .getSize(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(material.AnimatedContainer),
          )
          .first,
    )
    .width;

void main() {
  group('Sortable widget', () {
    testWidgets('drop leaves no hover tint at the source index', (
      tester,
    ) async {
      var items = <String>['A', 'B', 'C'];
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await tester.pumpWidget(
        _buildApp(
          material.StatefulBuilder(
            builder: (context, setOuterState) => Sortable(
              itemCount: items.length,
              onReorder: (from, to) => setOuterState(() {
                final next = [...items];
                final moved = next.removeAt(from);
                next.insert(to, moved);
                items = next;
              }),
              itemBuilder: (context, index, dragHandle, removeButton) =>
                  material.Row(
                    mainAxisSize: material.MainAxisSize.min,
                    children: [dragHandle, material.Text(items[index])],
                  ),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // Hover row A — the pre-drag hover tint (the stale value the proxy
      // could pin to the source index).
      await gesture.moveTo(tester.getCenter(find.text('A')));
      final settled = await tester.pumpAndSettle();
      expect(settled, greaterThan(0));
      final hoverColor = _rowColorOf(tester, 'A');
      final baseColor = _rowColorOf(tester, 'B');
      expect(hoverColor, isNot(baseColor));

      // Drag A one slot down from its handle and release.
      final handle = find
          .descendant(
            of: find.ancestor(
              of: find.text('A'),
              matching: find.byType(material.AnimatedContainer),
            ),
            matching: find.byType(Icon),
          )
          .first;
      // The engine moves A past B once A's centre crosses B's centre, so
      // the slot is the centre-to-centre pitch — the row height plus the
      // spacing between rows. 1.2 pitches lands past B and well short of C.
      final pitch =
          _rowRectOf(tester, 'B').center.dy - _rowRectOf(tester, 'A').center.dy;
      await gesture.down(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 60));
      for (var step = 0; step < 6; step += 1) {
        await gesture.moveBy(material.Offset(0, pitch * 0.2));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();

      // Frame by frame through the drop settle and past the commit —
      // even a single stale frame is amplified by the AnimatedContainer
      // into a visible in/out pulse:
      //  * 'B' / 'C' may never wear the hover tint (the source-index
      //    flash painted the row left at the old index);
      //  * 'A' may hover only after the commit (the pointer genuinely
      //    rests on it at the target slot) — during the settle the
      //    proxy must wear base chrome, not the frozen pre-drag hover.
      for (var frame = 0; frame < 40; frame += 1) {
        await tester.pump(const Duration(milliseconds: 16));
        final committed = items.first == 'B';
        for (final label in ['B', 'C', if (!committed) 'A']) {
          expect(
            _rowColorOf(tester, label),
            isNot(hoverColor),
            reason: 'stale hover tint on row $label (frame $frame)',
          );
        }
      }
      expect(items, equals(['B', 'A', 'C']));
    });
    testWidgets('renders the requested number of items', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            itemCount: _kItemCount,
            itemBuilder: _item,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Sortable), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = Key('sortable-key');

      await tester.pumpWidget(
        _buildApp(
          Sortable(
            key: testKey,
            itemCount: _kItemCount,
            itemBuilder: _item,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('renders with empty item count', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            itemCount: 0,
            itemBuilder: _item,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Sortable), findsOneWidget);
    });

    testWidgets('rows span the parent width when content is narrow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            itemCount: _kItemCount,
            itemBuilder: _narrowItem,
            onReorder: (oldIndex, newIndex) {},
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // A row is the drop target, so its width is the hit area — it has to
      // come from the component, not from the label the row happens to
      // hold. Mirrors the `w-full` the Web twin emits on every row.
      expect(_rowWidthOf(tester, 'Item 0'), _kSizedBoxWidth);
      expect(_rowWidthOf(tester, 'Item 2'), _kSizedBoxWidth);
    });

    testWidgets('rows sit itemSpacing apart down the column', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            itemCount: _kItemCount,
            itemBuilder: _item,
            onReorder: (oldIndex, newIndex) {},
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // The value the Web twin has to reach with its container `gap`.
      // Pinning it here also catches the opposite regression — Flutter
      // quietly losing `spacing` the way Web lost its gap.
      expect(
        _rowRectOf(tester, 'Item 1').top - _rowRectOf(tester, 'Item 0').bottom,
        CoreSortableStyle.defaultItemSpacing,
      );
    });

    testWidgets('non-interactive rows keep the interactive width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            enabled: false,
            itemCount: _kItemCount,
            itemBuilder: _narrowItem,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // Disabling reordering is not a layout change — the list must not
      // collapse to content width just because the drag engine is off.
      expect(_rowWidthOf(tester, 'Item 0'), _kSizedBoxWidth);
    });

    testWidgets('renders disabled', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            enabled: false,
            itemCount: _kItemCount,
            itemBuilder: _item,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Sortable), findsOneWidget);
    });

    testWidgets('renders removable with a remove button slot', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            removable: true,
            onRemove: (index) {},
            itemCount: _kItemCount,
            itemBuilder: (context, index, dragHandle, removeButton) {
              return material.Row(
                children: [
                  material.Expanded(child: material.Text('Item $index')),
                  dragHandle,
                  if (removeButton != null) removeButton,
                ],
              );
            },
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Sortable), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('accepts onReorder callback', (tester) async {
      var reorderCalls = 0;

      await tester.pumpWidget(
        _buildApp(
          Sortable(
            onReorder: (oldIndex, newIndex) {
              reorderCalls += 1;
            },
            itemCount: _kItemCount,
            itemBuilder: _item,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // Drag gestures are exercised by integration/visual tests; here we only
      // assert the callback wiring compiles and the widget renders.
      expect(find.byType(Sortable), findsOneWidget);
      expect(reorderCalls, equals(0));
    });

    testWidgets('reorders through the shared drag engine on a real drag', (
      tester,
    ) async {
      final reorders = <String>[];
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            itemCount: _kItemCount,
            onReorder: (oldIndex, newIndex) =>
                reorders.add('$oldIndex->$newIndex'),
            itemBuilder: _item,
          ),
        ),
      );
      await tester.pump();

      // Drag item 0 by its handle (the only Icon per row) past item 1.
      final rowExtent =
          tester.getCenter(find.text('Item 1')).dy -
          tester.getCenter(find.text('Item 0')).dy;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Icon).first),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(Offset(0, rowExtent + 4));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(reorders, equals(<String>['0->1']));
    });

    testWidgets('a cancelled pointer abandons the reorder instead of '
        'committing it', (tester) async {
      // The system can take the pointer away mid-drag — a navigation
      // gesture, the notification shade, the app going to the
      // background, a browser `pointercancel`. That has to abandon the
      // reorder. `PanGestureRecognizer` reports a cancelled pointer to
      // `onEnd` once the drag is live (its `onCancel` is reachable only
      // before the drag is accepted), so the abandoned move used to be
      // committed as if the user had dropped it, with nothing on screen
      // to say the list had just been rewritten.
      final reorders = <String>[];
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            itemCount: _kItemCount,
            onReorder: (oldIndex, newIndex) =>
                reorders.add('$oldIndex->$newIndex'),
            itemBuilder: _item,
          ),
        ),
      );
      await tester.pump();

      final rowExtent =
          tester.getCenter(find.text('Item 1')).dy -
          tester.getCenter(find.text('Item 0')).dy;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Icon).first),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(Offset(0, rowExtent + 4));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(reorders, isEmpty);
    });
  });

  group('Sortable row chrome', () {
    material.BoxDecoration rowDecoration(WidgetTester tester) {
      final container = tester.widget<material.AnimatedContainer>(
        find
            .ancestor(
              of: find.text('Item 0'),
              matching: find.byType(material.AnimatedContainer),
            )
            .first,
      );
      return container.decoration! as material.BoxDecoration;
    }

    Color resolved(WidgetTester tester, CoreColor token) => Theme.of(
      tester.element(find.byType(Sortable)),
    ).colorScheme.resolve(token).toValue();

    Future<void> pumpList(
      WidgetTester tester, {
      bool enabled = true,
      bool removable = false,
    }) async {
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            enabled: enabled,
            removable: removable,
            onRemove: (_) {},
            onReorder: (_, _) {},
            itemCount: _kItemCount,
            itemBuilder: (context, index, dragHandle, removeButton) =>
                material.Row(
                  children: [
                    dragHandle,
                    material.Expanded(child: material.Text('Item $index')),
                    ?removeButton,
                  ],
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a row is 48 high with radius 12 and an outline-variant '
        '1 px border', (tester) async {
      await pumpList(tester);

      expect(_rowRectOf(tester, 'Item 0').height, 48);
      final decoration = rowDecoration(tester);
      expect(
        decoration.borderRadius,
        const BorderRadius.all(Radius.circular(12)),
      );
      final border = decoration.border!;
      expect(border.top.width, CoreStrokeWidth.stroke1);
      expect(
        border.top.color,
        resolved(tester, const CoreColor.token(CoreColors.outlineVariant)),
      );
    });

    testWidgets('a disabled list wears the disabled tokens, not a fade', (
      tester,
    ) async {
      await pumpList(tester, enabled: false);

      final decoration = rowDecoration(tester);
      expect(
        decoration.color,
        resolved(tester, const CoreColor.token(CoreColors.disabledContainer)),
      );
      expect(
        decoration.border!.top.color,
        resolved(tester, const CoreColor.token(CoreColors.disabledOutline)),
      );
    });

    testWidgets('the handle glyph takes onSurfaceSubtle, disabled takes '
        'disabledContent', (tester) async {
      await pumpList(tester);
      final enabledStyle = tester
          .widgetList<Icon>(find.byType(Icon))
          .first
          .iconStyle;
      expect(
        enabledStyle!.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );

      await pumpList(tester, enabled: false);
      final disabledStyle = tester
          .widgetList<Icon>(find.byType(Icon))
          .first
          .iconStyle;
      expect(
        disabledStyle!.color,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    testWidgets('the remove control is a plain, sm, square Button of 32', (
      tester,
    ) async {
      await pumpList(tester, removable: true);

      final button = tester.widget<Button>(find.byType(Button).first);
      expect(button.variant, CoreButtonVariant.plain);
      expect(button.size, CoreComponentSize.sm);
      expect(button.shape, CoreButtonShape.square);
      expect(tester.getSize(find.byType(Button).first), const Size(32, 32));
      final style = button.buttonStyle!;
      expect(
        style.foregroundColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(style.leadingIconStyle!.size, CoreIconSize.size16);
    });

    testWidgets('tapping the remove control calls onRemove with the index', (
      tester,
    ) async {
      int? removed;
      await tester.pumpWidget(
        _buildApp(
          Sortable(
            removable: true,
            onRemove: (index) => removed = index,
            itemCount: _kItemCount,
            itemBuilder: (context, index, dragHandle, removeButton) =>
                material.Row(
                  children: [
                    material.Expanded(child: material.Text('Item $index')),
                    ?removeButton,
                  ],
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Button).at(1));
      await tester.pump();
      expect(removed, 1);
    });
  });

  group('Sortable disabled foreground', () {
    testWidgets('a disabled list paints its row text in the disabled '
        'foreground; an enabled one does not', (tester) async {
      Future<material.Color?> rowTextColor({required bool enabled}) async {
        await tester.pumpWidget(
          _buildApp(
            Sortable(
              itemCount: 1,
              enabled: enabled,
              itemBuilder: (context, index, dragHandle, removeButton) =>
                  const material.Text('row'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.text('row'));
        return material.DefaultTextStyle.of(context).style.color;
      }

      final enabledColor = await rowTextColor(enabled: true);
      final disabledColor = await rowTextColor(enabled: false);
      final disabledTone =
          Theme.of(
                tester.element(find.text('row')),
              ).colorScheme
              .resolve(CoreSortableStyle.defaultDisabledForegroundColor)
              .toValue();

      expect(disabledColor, disabledTone);
      expect(enabledColor, isNot(disabledTone));
    });

    testWidgets('the disabled item text and remove glyph take the disabled '
        'foreground; an override moves both', (tester) async {
      await tester.pumpWidget(_buildApp(const material.Placeholder()));
      final context = tester.element(find.byType(material.Placeholder));
      final resolved = resolveSortable(context);
      final custom = resolveSortable(
        context,
        sortableStyle: const CoreSortableStyle(
          disabledForegroundColor: CoreColor(0xFF00FF00),
        ),
      );
      final tone = Theme.of(context).colorScheme
          .resolve(CoreSortableStyle.defaultDisabledForegroundColor)
          .toValue();

      expect(resolved.disabledItemTextStyle.color, tone);
      expect(resolved.itemTextStyle.color, isNot(tone));
      expect(
        resolved.disabledRemoveButtonStyle.foregroundColor,
        CoreSortableStyle.defaultDisabledForegroundColor,
      );
      expect(
        resolved.removeButtonStyle.foregroundColor,
        isNot(CoreSortableStyle.defaultDisabledForegroundColor),
      );
      expect(custom.disabledItemTextStyle.color, const Color(0xFF00FF00));
      expect(
        custom.disabledRemoveButtonStyle.foregroundColor,
        const CoreColor(0xFF00FF00),
      );
    });
  });
}
