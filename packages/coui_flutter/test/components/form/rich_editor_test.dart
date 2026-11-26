import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

/// The font size the document draws the text [text] in.
double? _fontSizeOf(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.text(text, findRichText: true),
  );
  double? size;
  paragraph.text.visitChildren((span) {
    if (span is TextSpan) size ??= span.style?.fontSize;
    return size == null;
  });
  return size ?? paragraph.text.style?.fontSize;
}

LogicalKeyboardKey get _mod => defaultTargetPlatform == TargetPlatform.macOS
    ? LogicalKeyboardKey.metaLeft
    : LogicalKeyboardKey.controlLeft;

/// Presses [key] with [held] down, and lets the editor react.
Future<void> _chord(
  WidgetTester tester,
  List<LogicalKeyboardKey> held,
  LogicalKeyboardKey key,
) async {
  for (final k in held) {
    await tester.sendKeyDownEvent(k);
  }
  await tester.sendKeyEvent(key);
  for (final k in held.reversed) {
    await tester.sendKeyUpEvent(k);
  }
  await tester.pumpAndSettle();
}

/// A toolbar that lists the headings as buttons of their own, beside the
/// formats the held-down test compares them with.
const List<List<CoreRichEditorFormat>> _kHeadingToolbar = [
  [
    CoreRichEditorFormat.heading1,
    CoreRichEditorFormat.heading2,
    CoreRichEditorFormat.heading3,
  ],
  [CoreRichEditorFormat.bold],
  [CoreRichEditorFormat.quote],
];

void main() {
  group('RichEditorController Markdown', () {
    for (final markdown in const [
      'plain text',
      '**bold** and *italic* and ~~gone~~',
      'some `code` here',
      'a [link](https://example.com) in text',
      '# Heading\n\nbody',
      '- one\n- two\n  - nested',
      '1. first\n2. second',
      '- [ ] todo\n- [x] done',
      '> quoted\n> lines',
      'before\n\n---\n\nafter',
      '```dart\nfinal x = 1;\n```',
      r'escaped \*stars\* and 1\. not a list',
    ]) {
      test('round-trips ${markdown.replaceAll('\n', r'\n')}', () {
        final controller = RichEditorController(markdown: markdown);
        addTearDown(controller.dispose);
        expect(controller.markdown, markdown);
      });
    }

    test('toggling bold over a selection writes ** markers', () {
      final controller = RichEditorController(markdown: 'hello')..selectAll();
      addTearDown(controller.dispose);
      controller.toggleInline(InlineFormat.bold);
      expect(controller.markdown, '**hello**');
      controller.toggleInline(InlineFormat.bold);
      expect(controller.markdown, 'hello');
    });

    test('toggling a block format turns the paragraph into a list', () {
      final controller = RichEditorController(markdown: 'item')..selectAll();
      addTearDown(controller.dispose);
      controller.toggleBlock(BlockFormat.bulletList);
      expect(controller.markdown, '- item');
      controller.toggleBlock(BlockFormat.quote);
      expect(controller.markdown, '> item');
    });

    test('native typing converts heading and bold Markdown', () {
      final controller = RichEditorController()..moveCaretToEnd();
      addTearDown(controller.dispose);
      controller.editor.replaceText(
        0,
        0,
        '## ',
        const TextSelection.collapsed(offset: 3),
      );
      expect(controller.blockFormat, BlockFormat.heading2);
      controller.editor.replaceText(
        0,
        0,
        '**Title**',
        const TextSelection.collapsed(offset: 9),
      );
      expect(controller.markdown, '## **Title**');
    });

    test('editing a block preserves adjacent source Markdown', () {
      const original =
          '__keep this markup__\n\n| left | right |\n| --- | --- |\n| a | b |\n\nlast';
      final controller = RichEditorController(markdown: original)
        ..moveCaretToEnd();
      addTearDown(controller.dispose);
      final at = controller.selection!.extentOffset;
      controller.editor.replaceText(
        at,
        0,
        'ed',
        TextSelection.collapsed(offset: at + 2),
      );
      expect(controller.markdown, '${original}ed');
    });

    test('unsafe link targets are refused', () {
      expect(CoreRichEditorContract.normalizeLink('javascript:alert(1)'), null);
      expect(
        CoreRichEditorContract.normalizeLink('example.com'),
        'https://example.com',
      );
      expect(
        CoreRichEditorContract.normalizeLink('a@b.co'),
        'mailto:a@b.co',
      );
    });
  });

  group('RichEditor widget', () {
    testWidgets('shows one toolbar button per default format', (tester) async {
      await tester.pumpWidget(_buildApp(const RichEditor()));
      await tester.pumpAndSettle();
      final listed = CoreRichEditorFormat.defaultToolbar.expand((g) => g);
      for (final format in CoreRichEditorFormat.values) {
        // The image button needs somewhere to send the file and a way to
        // take it off again: no upload and delete, no button. The headings
        // are rows of the block-type menu, not buttons.
        expect(
          find.byKey(ValueKey<String>('richEditor.${format.name}')),
          listed.contains(format) && !format.needsImageUpload
              ? findsOneWidget
              : findsNothing,
          reason: format.name,
        );
      }
    });

    testWidgets(
      'the image button shows once an upload and a delete are given',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            RichEditor(
              onImageUpload: (file) async => 'x',
              onImageDelete: (url) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final format in CoreRichEditorFormat.defaultToolbar.expand(
          (g) => g,
        )) {
          expect(
            find.byKey(ValueKey<String>('richEditor.${format.name}')),
            findsOneWidget,
            reason: format.name,
          );
        }
      },
    );

    testWidgets('a delete alone adds no image button', (tester) async {
      // Nothing is uploaded, so there is nothing for the delete to take off.
      await tester.pumpWidget(
        _buildApp(RichEditor(onImageDelete: (url) async {})),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('richEditor.image')),
        findsNothing,
      );
    });

    test('an upload without its delete asserts in debug builds', () {
      // Every image the user took out would stay on the server for good.
      expect(
        () => RichEditor(onImageUpload: (file) async => 'x'),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('the toolbar keeps the default groups, block type first', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const RichEditor()));
      await tester.pumpAndSettle();
      final blockType = tester.getRect(
        find.byKey(const ValueKey('richEditor.blockType')),
      );
      final bold = tester.getRect(
        find.byKey(const ValueKey('richEditor.bold')),
      );
      expect(blockType.left, lessThan(bold.left));
      expect(blockType.center.dy, bold.center.dy, reason: 'one row');
    });

    testWidgets('hides the toolbar when showToolbar is false', (tester) async {
      await tester.pumpWidget(_buildApp(const RichEditor(showToolbar: false)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('richEditor.bold')), findsNothing);
    });

    testWidgets('the bold button formats the selection and reports it', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      final changes = <String>[];
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller, onChanged: changes.add)),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('richEditor.bold')));
      await tester.pumpAndSettle();
      expect(controller.markdown, '**hello**');
      expect(changes.last, '**hello**');
    });

    testWidgets('Mod+E toggles inline code', (tester) async {
      final controller = RichEditorController(markdown: 'x');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RichEditor));
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      final mod = defaultTargetPlatform == TargetPlatform.macOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      await tester.sendKeyDownEvent(mod);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyUpEvent(mod);
      await tester.pumpAndSettle();
      expect(controller.markdown, '`x`');
    });

    testWidgets('Mod+Enter submits the Markdown', (tester) async {
      final controller = RichEditorController(markdown: 'send me');
      addTearDown(controller.dispose);
      String? submitted;
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            controller: controller,
            onSubmit: (markdown) => submitted = markdown,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RichEditor));
      await tester.pumpAndSettle();
      final mod = defaultTargetPlatform == TargetPlatform.macOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      await tester.sendKeyDownEvent(mod);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(mod);
      await tester.pumpAndSettle();
      expect(submitted, 'send me');
    });

    testWidgets('a disabled editor disables its toolbar', (tester) async {
      await tester.pumpWidget(_buildApp(const RichEditor(enabled: false)));
      await tester.pumpAndSettle();
      final button = tester.widget<Button>(
        find.byKey(const ValueKey('richEditor.bold')),
      );
      expect(button.enabled, isFalse);
    });

    testWidgets('the heading buttons turn the block into # ## ### and back', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'Title');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            controller: controller,
            toolbar: _kHeadingToolbar,
            // The buttons in the box are pressed twice each; the toolbar
            // over the selection would sit over them after the first press.
            showSelectionToolbar: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      for (final (name, prefix) in const [
        ('heading1', '# '),
        ('heading2', '## '),
        ('heading3', '### '),
      ]) {
        final button = find.byKey(ValueKey<String>('richEditor.$name'));
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(controller.markdown, '${prefix}Title', reason: name);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(controller.markdown, 'Title', reason: '$name off');
      }
    });

    testWidgets('only the button of the heading at the caret is held down', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: '## Title');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditor(controller: controller, toolbar: _kHeadingToolbar),
        ),
      );
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      Button button(String name) => tester.widget<Button>(
        find.byKey(ValueKey<String>('richEditor.$name')),
      );
      final resting = button('heading1').buttonStyle;
      expect(button('heading2').buttonStyle, isNot(resting));
      expect(button('heading3').buttonStyle, resting);
      expect(button('quote').buttonStyle, resting);
      expect(button('bold').buttonStyle, resting);
    });

    testWidgets('a heading shows at a size of its own per level', (
      tester,
    ) async {
      final controller = RichEditorController(
        markdown: '# one\n\n## two\n\n### three\n\n#### four\n\nbody',
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      final one = _fontSizeOf(tester, 'one')!;
      final two = _fontSizeOf(tester, 'two')!;
      final three = _fontSizeOf(tester, 'three')!;
      final four = _fontSizeOf(tester, 'four')!;
      final body = _fontSizeOf(tester, 'body')!;
      expect(one, greaterThan(two));
      expect(two, greaterThan(three));
      expect(three, greaterThan(body));
      expect(four, three, reason: 'levels 4–6 take the smallest');
    });

    testWidgets('the Style slot sets the size of each level on its own', (
      tester,
    ) async {
      final controller = RichEditorController(
        markdown: '# one\n\n## two\n\n### three\n\nbody',
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            controller: controller,
            richEditorStyle: const CoreRichEditorStyle(
              heading2TextStyle: CoreTextStyle(fontSize: 19),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_fontSizeOf(tester, 'two'), 19);
      // The other levels keep theirs.
      expect(_fontSizeOf(tester, 'one'), greaterThan(19));
      expect(_fontSizeOf(tester, 'three'), lessThan(19));
    });

    testWidgets('Mod+Alt+1, 2 and 3 toggle the headings', (tester) async {
      final controller = RichEditorController(markdown: 'x');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RichEditor));
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      for (final (key, prefix) in [
        (LogicalKeyboardKey.digit1, '# '),
        (LogicalKeyboardKey.digit2, '## '),
        (LogicalKeyboardKey.digit3, '### '),
      ]) {
        await _chord(tester, [_mod, LogicalKeyboardKey.altLeft], key);
        expect(controller.markdown, '${prefix}x', reason: '$key');
        await _chord(tester, [_mod, LogicalKeyboardKey.altLeft], key);
        expect(controller.markdown, 'x', reason: '$key off');
      }
    });

    testWidgets('Mod+1 and Alt+1 alone are not heading shortcuts', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'x');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RichEditor));
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      await _chord(tester, [_mod], LogicalKeyboardKey.digit1);
      await _chord(tester, [
        LogicalKeyboardKey.altLeft,
      ], LogicalKeyboardKey.digit1);
      expect(controller.markdown, 'x');
    });

    testWidgets('AltGr+1 is not a heading shortcut — it types a character', (
      tester,
    ) async {
      // AltGr arrives as Ctrl + the right Alt on Windows.
      final controller = RichEditorController(markdown: 'x');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RichEditor));
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      await _chord(
        tester,
        [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.altRight],
        LogicalKeyboardKey.digit1,
      );
      expect(controller.markdown, 'x');
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

    testWidgets('Mod+Shift+8 still makes a bulleted list', (tester) async {
      final controller = RichEditorController(markdown: 'x');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RichEditor));
      await tester.pumpAndSettle();
      controller.selectAll();
      await tester.pump();
      await _chord(tester, [
        _mod,
        LogicalKeyboardKey.shiftLeft,
      ], LogicalKeyboardKey.digit8);
      expect(controller.markdown, '- x');
    });

    testWidgets('the counter appears near maxLength', (tester) async {
      final controller = RichEditorController(markdown: 'abcdefgh');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller, maxLength: 10)),
      );
      await tester.pumpAndSettle();
      expect(find.text('8 / 10'), findsOneWidget);
    });
  });
}
