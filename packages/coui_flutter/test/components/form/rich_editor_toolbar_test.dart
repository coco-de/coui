import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child, {double scaling = 1}) => material.MaterialApp(
  home: Theme(
    data: ThemeData(scaling: scaling),
    child: material.Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

Finder _button(String name) =>
    find.byKey(ValueKey<String>('richEditorToolbar.$name'));

Button _buttonWidget(WidgetTester tester, String name) =>
    tester.widget<Button>(_button(name));

/// The toolbar the design's `format` row below draws — the headings as
/// buttons of their own, as an app lists them, the groups the editor offered
/// before its block-type menu.
const List<List<CoreRichEditorFormat>> _kHeadingsToolbar = [
  [
    CoreRichEditorFormat.heading1,
    CoreRichEditorFormat.heading2,
    CoreRichEditorFormat.heading3,
  ],
  [
    CoreRichEditorFormat.bold,
    CoreRichEditorFormat.italic,
    CoreRichEditorFormat.strikethrough,
    CoreRichEditorFormat.code,
    CoreRichEditorFormat.link,
  ],
  [
    CoreRichEditorFormat.bulletedList,
    CoreRichEditorFormat.numberedList,
    CoreRichEditorFormat.taskList,
  ],
  [CoreRichEditorFormat.quote, CoreRichEditorFormat.image],
];

// The design's `format` row (Figma 500:18635, 424 wide): the x of each
// 32-square button from the first one's left edge — 2 between buttons, 8
// between groups.
const _designX = <String, double>{
  'heading1': 0,
  'heading2': 34,
  'heading3': 68,
  'bold': 108,
  'italic': 142,
  'strikethrough': 176,
  'code': 210,
  'link': 244,
  'bulletedList': 284,
  'numberedList': 318,
  'taskList': 352,
  'quote': 392,
};

void main() {
  group('RichEditorToolbar on its own', () {
    testWidgets('lays the buttons out as the design draws them', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(
            controller: controller,
            toolbar: _kHeadingsToolbar,
            // The link button waits for an editor; the layout does not.
            onFormat: (_) => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final origin = tester.getTopLeft(_button('heading1'));
      for (final entry in _designX.entries) {
        final rect = tester.getRect(_button(entry.key));
        expect(rect.left - origin.dx, entry.value, reason: entry.key);
        expect(rect.top, origin.dy, reason: '${entry.key} shares the row');
        expect(rect.size, const Size.square(32), reason: entry.key);
      }
      final icon = tester.getSize(
        find.descendant(of: _button('bold'), matching: find.byType(Icon)),
      );
      expect(icon, const Size.square(16));
      // 12 buttons and no image button: it needs an editor that takes files.
      expect(_button('image'), findsNothing);
      expect(
        tester.getSize(find.byType(Wrap)).width,
        424,
        reason: 'the format row is 424 wide',
      );
    });

    testWidgets('wraps between groups when narrow, never inside one', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            width: 200,
            child: RichEditorToolbar(
              controller: controller,
              toolbar: _kHeadingsToolbar,
              onFormat: (_) => true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      double top(String name) => tester.getTopLeft(_button(name)).dy;
      // The three headings share a row, and so do the five inline buttons.
      expect(top('heading1'), top('heading3'));
      expect(top('bold'), top('link'));
      expect(top('bulletedList'), top('taskList'));
      // 424 does not fit in 200: the groups come down onto further rows.
      expect(top('bold'), greaterThan(top('heading1')));
      expect(top('quote'), greaterThan(top('bold')));
    });

    testWidgets('follows the theme scaling like the editor toolbar does', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditor(controller: controller),
          scaling: 1.25,
        ),
      );
      await tester.pumpAndSettle();
      final own = tester.getSize(find.byKey(const ValueKey('richEditor.bold')));
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(
            controller: controller,
            toolbar: _kHeadingsToolbar,
            onFormat: (_) => true,
          ),
          scaling: 1.25,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(_button('bold')), own);
    });

    testWidgets('a press formats the selection of the controller', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(controller: controller, toolbar: _kHeadingsToolbar),
        ),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      await tester.tap(_button('bold'));
      await tester.pumpAndSettle();
      expect(controller.markdown, '**hello**');
      await tester.tap(_button('bold'));
      await tester.pumpAndSettle();
      expect(controller.markdown, 'hello');
    });

    testWidgets('the block formats turn the block over and back', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'item');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(controller: controller, toolbar: _kHeadingsToolbar),
        ),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      for (final (name, expected) in const [
        ('heading1', '# item'),
        ('heading3', '### item'),
        ('bulletedList', '- item'),
        ('numberedList', '1. item'),
        ('taskList', '- [ ] item'),
        ('quote', '> item'),
      ]) {
        await tester.tap(_button(name));
        await tester.pumpAndSettle();
        expect(controller.markdown, expected, reason: name);
        await tester.tap(_button(name));
        await tester.pumpAndSettle();
        expect(controller.markdown, 'item', reason: '$name off');
      }
    });

    testWidgets('only the button of the format at the caret is held down', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: '## Title');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(controller: controller, toolbar: _kHeadingsToolbar),
        ),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      final resting = _buttonWidget(tester, 'heading1').buttonStyle;
      expect(_buttonWidget(tester, 'heading2').buttonStyle, isNot(resting));
      expect(_buttonWidget(tester, 'heading3').buttonStyle, resting);
      expect(_buttonWidget(tester, 'quote').buttonStyle, resting);
      // The buttons follow the caret without a rebuild from the parent.
      controller
        ..markdown = '> quoted'
        ..selectAll();
      await tester.pump();
      expect(_buttonWidget(tester, 'quote').buttonStyle, isNot(resting));
      expect(_buttonWidget(tester, 'heading2').buttonStyle, resting);
    });

    testWidgets('a press before any selection puts the caret at the end', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(controller: controller, toolbar: _kHeadingsToolbar),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.selection, isNull);
      await tester.tap(_button('bold'));
      await tester.pumpAndSettle();
      expect(controller.selection, isNotNull);
      expect(controller.isActive(InlineFormat.bold), isTrue);
    });

    testWidgets('enabled: false switches every button off', (tester) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(
            controller: controller,
            toolbar: _kHeadingsToolbar,
            enabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in _designX.keys) {
        expect(_buttonWidget(tester, name).enabled, isFalse, reason: name);
      }
      controller.selectAll();
      await tester.tap(_button('bold'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(controller.markdown, 'hello');
    });

    testWidgets('a read-only controller switches every button off', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello')
        ..readOnly = true;
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(controller: controller, toolbar: _kHeadingsToolbar),
        ),
      );
      await tester.pumpAndSettle();
      expect(_buttonWidget(tester, 'bold').enabled, isFalse);
      expect(_buttonWidget(tester, 'heading1').enabled, isFalse);
    });

    testWidgets('onFormat takes a press over when it returns true', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      final seen = <CoreRichEditorFormat>[];
      var take = true;
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(
            controller: controller,
            toolbar: _kHeadingsToolbar,
            onFormat: (format) {
              seen.add(format);
              return take;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      await tester.tap(_button('bold'));
      await tester.pumpAndSettle();
      expect(seen, [CoreRichEditorFormat.bold]);
      expect(controller.markdown, 'hello', reason: 'the press was taken');
      take = false;
      await tester.tap(_button('bold'));
      await tester.pumpAndSettle();
      expect(seen, [CoreRichEditorFormat.bold, CoreRichEditorFormat.bold]);
      expect(controller.markdown, '**hello**', reason: 'handed back');
    });

    testWidgets('the link button needs an editor or an onFormat', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(controller: controller, toolbar: _kHeadingsToolbar),
        ),
      );
      await tester.pumpAndSettle();
      expect(_buttonWidget(tester, 'link').enabled, isFalse);
      expect(_buttonWidget(tester, 'bold').enabled, isTrue);
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(
            controller: controller,
            toolbar: _kHeadingsToolbar,
            onFormat: (_) => false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_buttonWidget(tester, 'link').enabled, isTrue);
    });

    testWidgets('a toolbar with its own groups draws only those', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditorToolbar(
            controller: controller,
            toolbar: const [
              [CoreRichEditorFormat.bold, CoreRichEditorFormat.italic],
              [CoreRichEditorFormat.quote],
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_button('bold'), findsOneWidget);
      expect(_button('italic'), findsOneWidget);
      expect(_button('quote'), findsOneWidget);
      expect(_button('heading1'), findsNothing);
      expect(_button('link'), findsNothing);
    });
  });

  group('RichEditorToolbar beside an editor', () {
    Widget page({
      required RichEditorController controller,
      required GlobalKey<RichEditorState> editorKey,
      bool toolbarFirst = true,
      bool withImages = false,
    }) {
      final toolbar = RichEditorToolbar(
        controller: controller,
        toolbar: _kHeadingsToolbar,
        editorKey: editorKey,
      );
      final editor = RichEditor(
        key: editorKey,
        controller: controller,
        showToolbar: false,
        onImageUpload: withImages ? (file) async => 'x' : null,
        onImageDelete: withImages ? (url) async {} : null,
      );
      return _buildApp(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: toolbarFirst ? [toolbar, editor] : [editor, toolbar],
        ),
      );
    }

    testWidgets('the link button opens the editor link dialog', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      final editorKey = GlobalKey<RichEditorState>();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        page(controller: controller, editorKey: editorKey),
      );
      await tester.pumpAndSettle();
      expect(_buttonWidget(tester, 'link').enabled, isTrue);
      controller.selectAll();
      await tester.pump();
      await tester.tap(_button('link'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('richEditor.linkDialog')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('richEditor.linkDialog.url')),
        'example.com',
      );
      await tester.tap(find.byKey(const ValueKey('richEditor.linkDialog.ok')));
      await tester.pumpAndSettle();
      expect(controller.markdown, '[hello](https://example.com)');
    });

    testWidgets('a press hands the focus to the editor', (tester) async {
      final controller = RichEditorController(markdown: 'hello');
      final editorKey = GlobalKey<RichEditorState>();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        page(controller: controller, editorKey: editorKey),
      );
      await tester.pumpAndSettle();
      expect(editorKey.currentState!.focusNode.hasFocus, isFalse);
      controller.selectAll();
      await tester.pump();
      await tester.tap(_button('italic'));
      await tester.pumpAndSettle();
      expect(controller.markdown, '*hello*');
      expect(editorKey.currentState!.focusNode.hasFocus, isTrue);
    });

    for (final toolbarFirst in [true, false]) {
      testWidgets(
        'the image button shows with an editor that takes files '
        '(toolbar ${toolbarFirst ? 'before' : 'after'} the editor)',
        (tester) async {
          final controller = RichEditorController(markdown: 'hello');
          final editorKey = GlobalKey<RichEditorState>();
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            page(
              controller: controller,
              editorKey: editorKey,
              toolbarFirst: toolbarFirst,
              withImages: true,
            ),
          );
          // The editor mounts after the toolbar built: the next frame shows
          // the button.
          await tester.pumpAndSettle();
          expect(_button('image'), findsOneWidget);
          expect(editorKey.currentState!.canInsertImage, isTrue);
        },
      );
    }

    testWidgets('no image button for an editor without upload and delete', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      final editorKey = GlobalKey<RichEditorState>();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        page(controller: controller, editorKey: editorKey),
      );
      await tester.pumpAndSettle();
      expect(_button('image'), findsNothing);
      expect(editorKey.currentState!.canInsertImage, isFalse);
    });

    testWidgets('the editor own toolbar and this one stay the same buttons', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              RichEditor(controller: controller, toolbar: _kHeadingsToolbar),
              RichEditorToolbar(
                controller: controller,
                toolbar: _kHeadingsToolbar,
                onFormat: (_) => false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in _designX.keys) {
        expect(
          tester.getSize(find.byKey(ValueKey<String>('richEditor.$name'))),
          tester.getSize(_button(name)),
          reason: name,
        );
        expect(
          _buttonWidget(tester, name).buttonStyle,
          tester
              .widget<Button>(find.byKey(ValueKey<String>('richEditor.$name')))
              .buttonStyle,
          reason: name,
        );
      }
    });
  });
}
