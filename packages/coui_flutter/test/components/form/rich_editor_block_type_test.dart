import 'dart:ui' show CheckedState;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(
  Widget child, {
  double width = 640,
  TextDirection direction = TextDirection.ltr,
}) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Directionality(
        textDirection: direction,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

Finder get _blockType =>
    find.byKey(const ValueKey<String>('richEditor.blockType'));

Finder get _blockTypeButton =>
    find.descendant(of: _blockType, matching: find.byType(Button)).first;

Finder _label(String text) =>
    find.descendant(of: _blockType, matching: find.text(text));

/// The menu's rows, by their label — the rows live in the overlay, outside
/// the editor.
Finder _row(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(MenuItem),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(_blockTypeButton);
  await tester.pumpAndSettle();
}

Color _disabledContent(BuildContext context) =>
    Theme.of(
          context,
        ).colorScheme
        .resolve(const CoreColor.token(CoreColors.disabledContent))
        .toValue();

void main() {
  group('RichEditor block-type button', () {
    testWidgets('names the block with a chevron 4 after it, on a sm row', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const RichEditor()));
      await tester.pumpAndSettle();
      final button = tester.widget<Button>(_blockTypeButton);
      expect(button.variant, CoreButtonVariant.plain);
      expect(button.size, CoreComponentSize.sm);
      expect(button.shape, CoreButtonShape.rectangle);
      expect(_label('Text'), findsOneWidget);
      final chevron = find.descendant(
        of: _blockType,
        matching: find.byWidgetPredicate(
          (w) => w is Icon && w.icon == LucideIcons.chevronDown,
        ),
      );
      expect(chevron, findsOneWidget);
      // The label and the chevron are 4 apart — closer than the sm row's 6.
      expect(
        tester.getRect(chevron).left - tester.getRect(_label('Text')).right,
        4,
      );
      expect(tester.getSize(_blockTypeButton).height, 32);
      // A plain button draws no inset: the label is the button's start edge.
      expect(
        tester.getRect(_label('Text')).left,
        tester.getRect(_blockTypeButton).left,
      );
    });

    testWidgets('reads the heading the caret is in', (tester) async {
      final controller = RichEditorController(markdown: '## Title');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller)),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      expect(_label('Heading 2'), findsOneWidget);
      // A list item is none of the four: it reads Text.
      controller
        ..markdown = '- item'
        ..selectAll();
      await tester.pump();
      expect(_label('Text'), findsOneWidget);
    });

    testWidgets(
      'opens Text and the headings, the current one checked, with # hints',
      (tester) async {
        final controller = RichEditorController(markdown: '## Title');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _buildApp(
            // The toolbar in the box is under test; the one over the selection
            // would sit over its first line and its menu.
            RichEditor(controller: controller, showSelectionToolbar: false),
          ),
        );
        await tester.pumpAndSettle();
        controller.selectAll();
        await tester.pump();
        await _open(tester);
        final labels = ['Text', 'Heading 1', 'Heading 2', 'Heading 3'];
        final tops = <double>[];
        for (final label in labels) {
          expect(_row(label), findsOneWidget, reason: label);
          tops.add(tester.getTopLeft(_row(label)).dy);
        }
        expect(tops, [...tops]..sort(), reason: 'listed in this order');
        // The current block is checked, and only it.
        for (final label in labels) {
          final checks = find.descendant(
            of: _row(label),
            matching: find.byWidgetPredicate(
              (w) => w is Icon && w.icon == LucideIcons.check,
            ),
          );
          expect(
            checks,
            label == 'Heading 2' ? findsOneWidget : findsNothing,
            reason: label,
          );
        }
        // Each heading row ends in the Markdown that makes it; Text has none.
        for (final (label, hint) in const [
          ('Heading 1', '#'),
          ('Heading 2', '##'),
          ('Heading 3', '###'),
        ]) {
          expect(
            find.descendant(of: _row(label), matching: find.text(hint)),
            findsOneWidget,
            reason: label,
          );
        }
        expect(
          find.descendant(
            of: _row('Text'),
            matching: find.textContaining('#'),
          ),
          findsNothing,
        );
        // The rows are the menu's default (sm) rows, 32 tall, 4 under the
        // button.
        expect(tester.getSize(_row('Text')).height, CoreControlSize.heightSm);
        expect(
          tester.getTopLeft(find.byType(Popup)).dy -
              tester.getRect(_blockTypeButton).bottom,
          4,
        );
      },
    );

    testWidgets('a row sets the block and the label follows', (tester) async {
      final controller = RichEditorController(markdown: 'Title');
      addTearDown(controller.dispose);
      final changes = <String>[];
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            controller: controller,
            onChanged: changes.add,
            // The toolbar in the box is under test.
            showSelectionToolbar: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      for (final (label, markdown) in const [
        ('Heading 1', '# Title'),
        ('Heading 3', '### Title'),
        ('Text', 'Title'),
      ]) {
        await _open(tester);
        await tester.tap(_row(label));
        await tester.pumpAndSettle();
        expect(controller.markdown, markdown, reason: label);
        expect(changes.last, markdown, reason: label);
        expect(_label(label), findsOneWidget, reason: '$label on the button');
        expect(find.byType(Popup), findsNothing, reason: 'the menu closed');
      }
    });

    testWidgets('picking the current row leaves the block as it is', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: '# Title');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller)),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      await _open(tester);
      await tester.tap(_row('Heading 1'));
      await tester.pumpAndSettle();
      expect(controller.markdown, '# Title');
    });

    testWidgets('the keyboard opens the menu and moves through its rows', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'Title');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          // The toolbar in the box is under test; the one over the selection
          // would sit over its first line and its menu.
          RichEditor(controller: controller, showSelectionToolbar: false),
        ),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      Focus.of(
        tester.element(
          find.descendant(of: _blockTypeButton, matching: find.byType(Text)),
        ),
      ).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(Popup), findsOneWidget, reason: 'Enter opens it');
      expect(_row('Heading 1'), findsOneWidget);
    });

    testWidgets('a disabled editor disables the button and opens nothing', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const RichEditor(enabled: false)));
      await tester.pumpAndSettle();
      expect(tester.widget<Button>(_blockTypeButton).enabled, isFalse);
      await tester.tap(_blockTypeButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(Popup), findsNothing);
    });

    testWidgets('is named for what it picks and the block it shows', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = RichEditorController(markdown: '## Title');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller)),
      );
      await tester.pumpAndSettle();
      // The visible label alone would read as a button called "Text".
      expect(find.bySemanticsLabel('Block type: Text'), findsOneWidget);
      controller.selectAll();
      await tester.pump();
      expect(find.bySemanticsLabel('Block type: Heading 2'), findsOneWidget);
      // The name is read once: the visible label adds nothing after it.
      expect(
        find.bySemanticsLabel(RegExp(r'Heading 2\s+Heading 2')),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Heading 2'), findsNothing);
      handle.dispose();
    });

    testWidgets('the rows are the choices of one group, drawn with a check', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = RichEditorController(markdown: '# Title');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          // The toolbar in the box is under test; the one over the selection
          // would sit over its first line and its menu.
          RichEditor(controller: controller, showSelectionToolbar: false),
        ),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      await _open(tester);
      final dropdown = tester.widget<DropdownMenu>(find.byType(DropdownMenu));
      for (final item in dropdown.items) {
        expect(item.kind, CoreMenuItemKind.radio, reason: item.label);
        expect(item.radioMark, CoreMenuRadioMark.check, reason: item.label);
      }
      for (final label in ['Text', 'Heading 1', 'Heading 2', 'Heading 3']) {
        // The role node encloses the node that carries the label.
        final data = tester
            .getSemantics(
              find.descendant(of: _row(label), matching: find.text(label)),
            )
            .parent!
            .getSemanticsData();
        expect(data.role, SemanticsRole.menuItemRadio, reason: label);
        expect(
          data.flagsCollection.isChecked,
          label == 'Heading 1' ? CheckedState.isTrue : CheckedState.isFalse,
          reason: label,
        );
        expect(
          data.flagsCollection.isInMutuallyExclusiveGroup,
          isTrue,
          reason: label,
        );
        // Never the dot of a radio-button list.
        expect(
          find.descendant(
            of: _row(label),
            matching: find.byWidgetPredicate(
              (w) => w is Icon && w.icon == LucideIcons.circleDot,
            ),
          ),
          findsNothing,
          reason: label,
        );
      }
      handle.dispose();
    });

    testWidgets('the image button draws the image glyph', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            onImageUpload: (file) async => 'x',
            onImageDelete: (url) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('richEditor.image')),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.icon, LucideIcons.image);
    });

    testWidgets('the Style slot reaches the button', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const RichEditor(
            richEditorStyle: CoreRichEditorStyle(
              blockTypeButtonStyle: CoreButtonStyle(
                iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chevron = find.descendant(
        of: _blockType,
        matching: find.byWidgetPredicate(
          (w) => w is Icon && w.icon == LucideIcons.chevronDown,
        ),
      );
      expect(
        tester.getRect(chevron).left - tester.getRect(_label('Text')).right,
        8,
      );
    });
  });

  group('RichEditor toolbar inset', () {
    testWidgets('12 on the start side, 8 on the end, 4 above and below', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const RichEditor(
            toolbarTrailing: SizedBox(
              key: ValueKey('trailing'),
              width: 20,
              height: 20,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(RichEditor));
      expect(tester.getRect(_blockType).left - box.left, 1 + 12);
      expect(tester.getRect(_blockType).top - box.top, 1 + 4);
      expect(
        box.right -
            tester.getRect(find.byKey(const ValueKey('trailing'))).right,
        1 + 8,
      );
    });

    testWidgets('the 12 follows the reading direction', (tester) async {
      await tester.pumpWidget(
        _buildApp(const RichEditor(), direction: TextDirection.rtl),
      );
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(RichEditor));
      expect(box.right - tester.getRect(_blockType).right, 1 + 12);
    });
  });

  group('RichEditor disabled toolbar icons', () {
    testWidgets('every icon is disabled-content, a held-down one too', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: '- **item**');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller, enabled: false)),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      final context = tester.element(find.byType(RichEditor));
      final expected = _disabledContent(context);
      final icons = find.descendant(
        of: find.byType(RichEditor),
        matching: find.byType(Icon),
      );
      expect(icons, findsWidgets);
      for (final element in icons.evaluate()) {
        final icon = element.widget as Icon;
        final color = resolveIcon(
          element,
          icon: icon.icon,
          data: null,
          widgetStyle: icon.iconStyle,
        ).color;
        expect(color, expected, reason: icon.icon.id);
      }
      // And the label of the block-type button.
      final label = tester.widget<RichText>(
        find.descendant(of: _blockType, matching: find.byType(RichText)).first,
      );
      expect(label.text.style?.color, expected);
    });
  });
}
