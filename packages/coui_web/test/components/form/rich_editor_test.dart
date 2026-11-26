// Pins the Web `RichEditor`'s server-rendered markup and its resolver: the
// toolbar is a strip at the top of the box, inside its border, opening with
// the block-type button and composing plain `Button`s with labelled,
// pressed-state attributes (the image button only with an upload and a delete
// handler) with a
// line under it and between its groups, the box is the `TextArea`'s own
// chrome, the first paint is the codec's escaped markup, and the counter
// follows the contract's threshold.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_style.dart';
import 'package:coui_web/src/components/form/text_area/text_area_style.dart';
import 'package:jaspr_test/server_test.dart';

import '../../helpers/pump_with_theme.dart';

/// A locale whose image-unavailable message is unmistakably not English.
class _MarkedLocalizations extends DefaultCouiLocalizations {
  const _MarkedLocalizations();

  @override
  String get richEditorImageUnavailable => '이미지 없음';
}

void _pump(ServerTester tester, Component editor) =>
    tester.pumpComponent(CoUIWeb(theme: .coui, child: editor));

/// Captures the ambient themed [BuildContext] for resolver-level tests.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

/// The class that paints [color] as a background — a `Divider` line is drawn
/// by one, and so is the toolbar's strip.
String _bgClass(CoreColor color) => 'bg-${color.tailwindColor}';

/// The class that fills the toolbar strip by default.
final String _stripClass = _bgClass(
  CoreRichEditorStyle.defaultToolbarBackgroundColor,
);

/// The `TextArea` resolved the way the editor resolves its box.
ResolvedTextArea _wrappingArea(
  BuildContext context, {
  CoreTextAreaStyle? textAreaStyle,
  bool enabled = true,
}) => resolveTextArea(
  context,
  size: CoreComponentSize.md,
  expandableHeight: false,
  expandableWidth: false,
  hasError: false,
  obscureText: false,
  obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
  enabled: enabled,
  textAreaStyle: CoreRichEditorStyle.defaultTextAreaStyle.merge(textAreaStyle),
);

void main() {
  group('RichEditor — server markup', () {
    testServer('the toolbar has one labelled plain button per format', (
      tester,
    ) async {
      _pump(tester, const RichEditor());
      final document = (await tester.request('/')).document!;
      final toolbar = document.querySelector('[role=toolbar]')!;
      expect(toolbar.attributes['aria-label'], 'Formatting');
      final all = toolbar.querySelectorAll('button');
      // The block-type button, then nine format buttons.
      expect(all, hasLength(10));
      expect(all.first.text.trim(), 'Text');
      final buttons = all.skip(1);
      expect(buttons.map((element) => element.attributes['aria-label']), [
        'Bold',
        'Italic',
        'Strikethrough',
        'Code',
        'Link',
        'Bulleted list',
        'Numbered list',
        'Checklist',
        'Quote',
      ]);
      for (final button in buttons) {
        expect(button.attributes['aria-pressed'], 'false');
        expect(button.attributes['aria-keyshortcuts'], startsWith('Control+'));
      }
      // Four groups: the block type, the marks, the lists, the quote. The
      // image button, which joins the quote, needs an upload handler.
      expect(toolbar.querySelectorAll('[role=group]'), hasLength(4));
    });

    testServer('the shortcut of each button reads as aria-keyshortcuts', (
      tester,
    ) async {
      _pump(
        tester,
        const RichEditor(
          toolbar: [
            [
              CoreRichEditorFormat.heading1,
              CoreRichEditorFormat.heading2,
              CoreRichEditorFormat.heading3,
            ],
            [CoreRichEditorFormat.bold, CoreRichEditorFormat.strikethrough],
          ],
        ),
      );
      final listed = (await tester.request('/')).document!;
      final shortcuts = {
        for (final button in listed.querySelectorAll('[role=toolbar] button'))
          button.attributes['aria-label']:
              button.attributes['aria-keyshortcuts'],
      };
      // Alt is part of the shortcut — the headings, listed as buttons of
      // their own, are Mod+Alt+1, 2 and 3 — and Shift keeps its place after
      // it.
      expect(shortcuts['Heading 1'], 'Control+Alt+1');
      expect(shortcuts['Heading 2'], 'Control+Alt+2');
      expect(shortcuts['Heading 3'], 'Control+Alt+3');
      expect(shortcuts['Bold'], 'Control+B');
      expect(shortcuts['Strikethrough'], 'Control+Shift+X');
    });

    testServer('the image button comes with an upload and a delete, last', (
      tester,
    ) async {
      // It shares the last group with the quote.
      _pump(
        tester,
        RichEditor(
          onImageUpload: (file) async => 'unused',
          onImageDelete: (url) async {},
        ),
      );
      final document = (await tester.request('/')).document!;
      final toolbar = document.querySelector('[role=toolbar]')!;
      final buttons = toolbar.querySelectorAll('button');
      expect(buttons, hasLength(11));
      final image = buttons.last;
      expect(image.attributes['aria-label'], 'Image');
      // A picker, not a held-down format, and it has no shortcut.
      expect(image.attributes.containsKey('aria-pressed'), isFalse);
      expect(image.attributes.containsKey('aria-keyshortcuts'), isFalse);
      expect(image.attributes['aria-controls'], isNotEmpty);
      // It is the last group's second button, beside the quote — the group
      // is the quote alone until the editor can take images.
      final groups = toolbar.querySelectorAll('[role=group]');
      expect(groups, hasLength(4));
      expect(
        groups.last
            .querySelectorAll('button')
            .map(
              (element) => element.attributes['aria-label'],
            ),
        ['Quote', 'Image'],
      );
    });

    testServer('without an upload handler there is no image button', (
      tester,
    ) async {
      // A delete handler alone uploads nothing, so it adds no button either.
      _pump(tester, RichEditor(onImageDelete: (url) async {}));
      final document = (await tester.request('/')).document!;
      final labels = [
        for (final button in document.querySelectorAll('[role=toolbar] button'))
          button.attributes['aria-label'],
      ];
      expect(labels, isNot(contains('Image')));
      expect(
        document.querySelectorAll('[role=toolbar] [role=group]'),
        hasLength(4),
        reason: 'no empty group is left where the image button would be',
      );
    });

    test('an upload without its delete asserts in debug builds', () {
      // Every image the user took out would stay on the server for good.
      expect(
        () => RichEditor(onImageUpload: (file) async => 'unused'),
        throwsA(isA<AssertionError>()),
      );
    });

    testServer('a custom toolbar keeps the image button only with the pair', (
      tester,
    ) async {
      const toolbar = [
        [CoreRichEditorFormat.bold, CoreRichEditorFormat.image],
        [CoreRichEditorFormat.image],
      ];
      _pump(tester, const RichEditor(toolbar: toolbar));
      var document = (await tester.request('/')).document!;
      var shown = document.querySelector('[role=toolbar]')!;
      expect(shown.querySelectorAll('button'), hasLength(1));
      expect(shown.querySelectorAll('[role=group]'), hasLength(1));

      _pump(
        tester,
        RichEditor(
          toolbar: toolbar,
          onImageUpload: (file) async => 'unused',
          onImageDelete: (url) async {},
        ),
      );
      document = (await tester.request('/')).document!;
      shown = document.querySelector('[role=toolbar]')!;
      expect(shown.querySelectorAll('button'), hasLength(3));
      expect(shown.querySelectorAll('[role=group]'), hasLength(2));
    });

    testServer('a disabled editor disables the image button too', (
      tester,
    ) async {
      _pump(
        tester,
        RichEditor(
          enabled: false,
          onImageUpload: (file) async => 'unused',
          onImageDelete: (url) async {},
        ),
      );
      final document = (await tester.request('/')).document!;
      final buttons = document.querySelectorAll('[role=toolbar] button');
      expect(buttons, hasLength(11));
      for (final button in buttons) {
        expect(button.attributes.containsKey('disabled'), isTrue);
      }
    });

    testServer('the surface paints an image from the initial Markdown', (
      tester,
    ) async {
      _pump(
        tester,
        const RichEditor(
          initialValue: 'before\n\n![a cat](https://x.test/cat.png)\n\nafter',
        ),
      );
      final document = (await tester.request('/')).document!;
      final surface = document.querySelector('[role=textbox]')!;
      final image = surface.querySelector('img')!;
      expect(image.attributes['src'], 'https://x.test/cat.png');
      expect(image.attributes['alt'], 'a cat');
      expect(image.parent!.localName, 'p', reason: 'a block of its own');
    });

    testServer('an unsafe image address never reaches the surface', (
      tester,
    ) async {
      _pump(
        tester,
        const RichEditor(initialValue: '![a cat](javascript:alert(1))'),
      );
      final document = (await tester.request('/')).document!;
      final surface = document.querySelector('[role=textbox]')!;
      expect(surface.querySelector('img'), isNull);
      expect(surface.text, contains('a cat'));
    });

    testServer('a custom toolbar shows only its formats', (tester) async {
      _pump(
        tester,
        const RichEditor(
          toolbar: [
            [.bold],
            [],
            [.quote],
          ],
        ),
      );
      final document = (await tester.request('/')).document!;
      final toolbar = document.querySelector('[role=toolbar]')!;
      expect(toolbar.querySelectorAll('button'), hasLength(2));
      expect(toolbar.querySelectorAll('[role=group]'), hasLength(2));
    });

    testServer('showToolbar: false renders no toolbar', (tester) async {
      _pump(tester, const RichEditor(showToolbar: false));
      final document = (await tester.request('/')).document!;
      expect(document.querySelector('[role=toolbar]'), isNull);
      expect(document.querySelector('[role=textbox]'), isNotNull);
    });

    testServer('showToolbar: false leaves the TextArea box — the surface alone '
        'in it, no strip and no line', (tester) async {
      _pump(
        tester,
        const RichEditor(
          showToolbar: false,
          toolbarTrailing: Text('Show changes'),
        ),
      );
      final document = (await tester.request('/')).document!;
      final box = document.querySelector('[role=textbox]')!.parent!;
      expect(box.children, hasLength(1));
      expect(box.children.single.attributes['role'], 'textbox');
      expect(
        document.querySelectorAll(
          '.${_bgClass(CoreDividerStyle.defaultColor)}',
        ),
        isEmpty,
      );
      // The trailing slot goes with the toolbar.
      expect(document.body!.text, isNot(contains('Show changes')));
    });

    testServer('the surface paints the initial Markdown, escaped', (
      tester,
    ) async {
      _pump(
        tester,
        const RichEditor(initialValue: '**hi** <b>raw</b>\n\n- [x] done'),
      );
      final document = (await tester.request('/')).document!;
      final surface = document.querySelector('[role=textbox]')!;
      expect(surface.attributes['contenteditable'], 'true');
      expect(surface.attributes['aria-multiline'], 'true');
      expect(surface.querySelector('strong')!.text, 'hi');
      // Raw HTML in the value is text, not an element.
      expect(surface.querySelector('b'), isNull);
      expect(surface.text, contains('<b>raw</b>'));
      final box = surface.querySelector('input')!;
      expect(box.attributes['type'], 'checkbox');
      expect(box.attributes.containsKey('checked'), isTrue);
    });

    testServer(
      'the surface carries the message a broken image gets as its tooltip',
      (tester) async {
        _pump(tester, const RichEditor());
        final document = (await tester.request('/')).document!;
        final surface = document.querySelector('[role=textbox]')!;
        expect(
          surface.attributes['data-unavailable-label'],
          'Image unavailable',
        );
      },
    );

    testServer('and it follows the active locale', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const CouiLocalizationsScope(
            localizations: _MarkedLocalizations(),
            child: RichEditor(),
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final surface = document.querySelector('[role=textbox]')!;
      expect(surface.attributes['data-unavailable-label'], '이미지 없음');
    });

    testServer('an empty editor shows its placeholder', (tester) async {
      _pump(tester, const RichEditor(placeholder: 'Write a comment'));
      final document = (await tester.request('/')).document!;
      final surface = document.querySelector('[role=textbox]')!;
      expect(surface.attributes['data-placeholder'], 'Write a comment');
      expect(surface.attributes['aria-placeholder'], 'Write a comment');
      expect(surface.attributes.containsKey('data-empty'), isTrue);
    });

    testServer('a filled editor drops the empty marker', (tester) async {
      _pump(
        tester,
        const RichEditor(placeholder: 'Write', initialValue: 'text'),
      );
      final document = (await tester.request('/')).document!;
      final surface = document.querySelector('[role=textbox]')!;
      expect(surface.attributes.containsKey('data-empty'), isFalse);
    });

    testServer('disabled: not editable, buttons off', (tester) async {
      _pump(tester, const RichEditor(enabled: false));
      final document = (await tester.request('/')).document!;
      final surface = document.querySelector('[role=textbox]')!;
      expect(surface.attributes['contenteditable'], 'false');
      expect(surface.attributes['aria-disabled'], 'true');
      for (final button in document.querySelectorAll('[role=toolbar] button')) {
        expect(button.attributes.containsKey('disabled'), isTrue);
      }
    });

    testServer('read-only: not editable but keeps its tab stop', (
      tester,
    ) async {
      _pump(tester, const RichEditor(readOnly: true, initialValue: 'x'));
      final document = (await tester.request('/')).document!;
      final surface = document.querySelector('[role=textbox]')!;
      expect(surface.attributes['contenteditable'], 'false');
      expect(surface.attributes['aria-readonly'], 'true');
      expect(surface.attributes['tabindex'], '0');
    });

    testServer('the counter appears from 80% of maxLength', (tester) async {
      _pump(tester, const RichEditor(initialValue: '1234567', maxLength: 10));
      var document = (await tester.request('/')).document!;
      expect(document.body!.text, isNot(contains('7 / 10')));

      _pump(tester, const RichEditor(initialValue: '12345678', maxLength: 10));
      document = (await tester.request('/')).document!;
      expect(document.body!.text, contains('8 / 10'));
    });

    testServer('the document rules are scoped to the surface', (tester) async {
      _pump(tester, const RichEditor());
      final document = (await tester.request('/')).document!;
      final surface = document.querySelector('[role=textbox]')!;
      final id = surface.id;
      expect(id, startsWith('co-rich-editor-'));
      final css = document
          .querySelectorAll('style')
          .map((style) => style.text)
          .firstWhere((text) => text.contains('#$id '));
      expect(css, contains('#$id blockquote'));
      expect(css, contains('#$id[data-empty]::before'));
    });

    testServer('a list is set in by the listIndent of the style, and by the '
        'Core default without one', (tester) async {
      Future<String> documentRules(Component editor) async {
        _pump(tester, editor);
        final document = (await tester.request('/')).document!;
        final id = document.querySelector('[role=textbox]')!.id;
        return document
            .querySelectorAll('style')
            .map((style) => style.text)
            .firstWhere((text) => text.contains('#$id '));
      }

      String inset(double space) =>
          'padding-inline-start:var(--coui-space-${space.toInt()})';

      final byDefault = await documentRules(const RichEditor());
      final defaultInset = inset(CoreRichEditorStyle.defaultListIndent);
      expect(byDefault, contains('ul{list-style:disc;$defaultInset}'));
      expect(byDefault, contains('ol{list-style:decimal;$defaultInset}'));

      final overridden = await documentRules(
        const RichEditor(
          richEditorStyle: CoreRichEditorStyle(listIndent: CoreSpace.space40),
        ),
      );
      final ownInset = inset(CoreSpace.space40);
      expect(overridden, contains('ul{list-style:disc;$ownInset}'));
      expect(overridden, contains('ol{list-style:decimal;$ownInset}'));
    });

    // Out of the flow and with no insets of its own, the placeholder was as
    // wide as the room from where it starts to the far padding edge, and
    // wrapped later than typed text. Chrome lays it out in
    // `tool/parity/test/web/rich_editor_placeholder_probe_test.dart`.
    testServer('the placeholder spans the content box of the surface', (
      tester,
    ) async {
      _pump(tester, const RichEditor(placeholder: 'Write a comment'));
      final document = (await tester.request('/')).document!;
      final id = document.querySelector('[role=textbox]')!.id;
      final css = document
          .querySelectorAll('style')
          .map((style) => style.text)
          .firstWhere((text) => text.contains('#$id '));
      final rule = RegExp(
        '#${RegExp.escape(id)}\\[data-empty\\]::before\\{([^}]*)\\}',
      ).firstMatch(css)!.group(1)!;
      expect(
        rule.split(';'),
        containsAll([
          'position:absolute',
          'inset-inline:0',
          'padding-inline:inherit',
        ]),
      );
    });
  });

  group('RichEditor — the toolbar sits inside the box', () {
    final line = '.${_bgClass(CoreDividerStyle.defaultColor)}';
    final disabledLine =
        '.${_bgClass(const CoreColor.token(CoreColors.disabledOutline))}';

    testServer('the strip, the line under it and the surface share one box', (
      tester,
    ) async {
      _pump(tester, const RichEditor());
      final document = (await tester.request('/')).document!;
      final surface = document.querySelector('[role=textbox]')!;
      final toolbar = document.querySelector('[role=toolbar]')!;
      final box = surface.parent!;
      // In that order: the strip, then the line, then the text.
      expect(box.children, hasLength(3));
      expect(box.children.first, same(toolbar));
      expect(box.children.last, same(surface));
      final rule = box.children[1];
      expect(
        rule.classes,
        containsAll(['w-full', _bgClass(CoreDividerStyle.defaultColor)]),
      );
      expect(rule.classes, isNot(contains('h-full')));
      // One ring for both: the focus outline stands around the box.
      expect(box.parent!.classes, contains('outline'));
      expect(box.parent!.querySelector('[role=toolbar]'), same(toolbar));
      // The strip still controls the surface it now sits in.
      expect(toolbar.attributes['aria-controls'], surface.id);
    });

    testServer('what is not the box stays outside it', (tester) async {
      _pump(tester, const RichEditor(initialValue: '12345678', maxLength: 10));
      final document = (await tester.request('/')).document!;
      final box = document.querySelector('[role=textbox]')!.parent!;
      // The counter is under the box, after the ring that wraps it.
      expect(document.body!.text, contains('8 / 10'));
      expect(box.text, isNot(contains('8 / 10')));
      expect(box.parent!.text, isNot(contains('8 / 10')));
    });

    testServer('a gap and a line lead every group but the first', (
      tester,
    ) async {
      _pump(tester, const RichEditor());
      final document = (await tester.request('/')).document!;
      final toolbar = document.querySelector('[role=toolbar]')!;
      final groups = toolbar.querySelectorAll('[role=group]');
      expect(groups, hasLength(4));
      // The first group stands alone; each later one is a section of
      // gap · line · gap · group.
      final sections = [for (final group in groups) group.parent!];
      expect(sections.map((part) => part.children.length), [1, 4, 4, 4]);
      for (final part in sections.skip(1)) {
        expect(part.children.last.attributes['role'], 'group');
        final rule = part.children[1].querySelector(line)!;
        expect(rule.classes, containsAll(['h-full', 'shrink-0']));
        expect(rule.classes, isNot(contains('w-full')));
      }
      // The three lines between four groups, and the one under the strip.
      expect(toolbar.querySelectorAll(line), hasLength(3));
      expect(
        document
            .querySelector('[role=textbox]')!
            .parent!
            .querySelectorAll(
              line,
            ),
        hasLength(4),
      );
    });

    testServer('the sections are the toolbar buttons’ wrapping row', (
      tester,
    ) async {
      _pump(tester, const RichEditor());
      final document = (await tester.request('/')).document!;
      final toolbar = document.querySelector('[role=toolbar]')!;
      final buttons = toolbar.children.single;
      // The row wraps between sections — a group is never split.
      expect(
        buttons.classes,
        containsAll(['flex', 'flex-wrap', 'items-center']),
      );
      expect(buttons.children, hasLength(4));
      for (final part in buttons.children) {
        expect(part.classes, containsAll(['flex', 'items-center']));
        expect(part.classes, isNot(contains('flex-wrap')));
      }
    });

    testServer('the strip is a wrapping row, apart-justified, in the '
        'surface-container step', (tester) async {
      _pump(tester, const RichEditor());
      final document = (await tester.request('/')).document!;
      final toolbar = document.querySelector('[role=toolbar]')!;
      expect(
        toolbar.classes,
        containsAll([
          'flex',
          'flex-wrap',
          'justify-between',
          'items-center',
          _stripClass,
        ]),
      );
    });

    testServer('a disabled editor leaves the strip unpainted and draws the '
        'line under it in disabled-outline', (tester) async {
      _pump(tester, const RichEditor(enabled: false));
      var document = (await tester.request('/')).document!;
      var toolbar = document.querySelector('[role=toolbar]')!;
      var box = document.querySelector('[role=textbox]')!.parent!;
      expect(
        toolbar.classes.any((cls) => cls.startsWith('bg-')),
        isFalse,
        reason: 'the box’s disabled fill shows through the strip',
      );
      // Only the line under the strip follows the editor into the disabled
      // outline; the three lines between groups stay as they are (the
      // designer's disabled frame, #5951).
      expect(box.querySelectorAll(disabledLine), hasLength(1));
      expect(box.querySelectorAll(line), hasLength(3));

      _pump(tester, const RichEditor());
      document = (await tester.request('/')).document!;
      toolbar = document.querySelector('[role=toolbar]')!;
      box = document.querySelector('[role=textbox]')!.parent!;
      expect(toolbar.classes, contains(_stripClass));
      expect(box.querySelectorAll(disabledLine), isEmpty);
    });

    group('toolbarTrailing', () {
      testServer('sits after the buttons, in a wrapper of its own', (
        tester,
      ) async {
        _pump(
          tester,
          const RichEditor(toolbarTrailing: Text('Show changes')),
        );
        final document = (await tester.request('/')).document!;
        final toolbar = document.querySelector('[role=toolbar]')!;
        expect(toolbar.children, hasLength(2));
        final buttons = toolbar.children.first;
        final trailing = toolbar.children.last;
        expect(buttons.querySelectorAll('button'), hasLength(10));
        expect(buttons.text, isNot(contains('Show changes')));
        expect(trailing.text, 'Show changes');
        expect(trailing.classes, containsAll(['flex', 'items-center']));
        // The strip, not the buttons' row, is what wraps it below them.
        expect(toolbar.classes, contains('flex-wrap'));
        expect(toolbar.classes, contains('justify-between'));
        // The editing surface is not where it goes.
        expect(
          document.querySelector('[role=textbox]')!.text,
          isNot(contains('Show changes')),
        );
      });

      testServer('is left out when there is none', (tester) async {
        _pump(tester, const RichEditor());
        final document = (await tester.request('/')).document!;
        final toolbar = document.querySelector('[role=toolbar]')!;
        expect(toolbar.children, hasLength(1));
      });

      testServer('does not count among the formatting buttons', (
        tester,
      ) async {
        _pump(
          tester,
          RichEditor(
            toolbarTrailing: const Text('Show changes'),
            onImageUpload: (file) async => 'unused',
            onImageDelete: (url) async {},
          ),
        );
        final document = (await tester.request('/')).document!;
        final toolbar = document.querySelector('[role=toolbar]')!;
        expect(
          toolbar.children.first.querySelectorAll('button'),
          hasLength(11),
        );
        expect(toolbar.children.last.querySelectorAll('button'), isEmpty);
      });
    });
  });

  group('resolveRichEditor', () {
    testComponents('the box wears the TextArea box chrome', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveRichEditor(context, enabled: true);
      final area = _wrappingArea(context);
      // The wrapping box's classes — border colour, focus and hover tints,
      // surface marker — except that it is a column here: the text area lays
      // a prefix, its text and a suffix in a centred row.
      final box = resolved.box.className.split(' ');
      for (final c in area.affixWrapper.className.split(' ')) {
        if (c == WebLayout.flex || c == WebLayout.itemsCenter) continue;
        expect(box, contains(c));
      }
      expect(
        box,
        containsAll([
          WebLayout.flex,
          WebLayout.flexCol,
          // The strip is clipped to the box's rounded top corners.
          WebLayout.overflowHidden,
        ]),
      );
      expect(box, isNot(contains(WebLayout.itemsCenter)));
      // Corners, border, fill — the box's own, not a copy of them.
      for (final property in [
        'border-radius',
        'border-style',
        'border-width',
        'background-color',
      ]) {
        expect(
          _inline(resolved.box)[property],
          _inline(area.affixWrapper)[property],
          reason: property,
        );
      }
      // The gap between the text area's prefix and its text would open the
      // column between the strip, the line and the surface.
      expect(_inline(resolved.box), isNot(contains('gap')));
      expect(resolved.focusOutlineStyle, area.focusOutlineStyle);
    });

    testComponents('the surface wears the TextArea text chrome, without a '
        'border of its own', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveRichEditor(context, enabled: true);
      final area = _wrappingArea(context);
      // The text's classes, except that the surface stacks its blocks (the
      // `<textarea>`'s flex row would lay paragraphs and lists side by side)
      // and leaves the border to the box.
      final surface = resolved.surface.className.split(' ');
      for (final c in area.textarea.className.split(' ')) {
        if (c.startsWith('border-') || c.contains(':border-')) {
          expect(surface, isNot(contains(c)), reason: c);
        } else {
          expect(surface, contains(c == WebLayout.flex ? WebLayout.block : c));
        }
      }
      expect(surface, isNot(contains(WebLayout.flex)));
      final inline = _inline(resolved.surface);
      expect(inline, isNot(contains('border-radius')));
      expect(inline['border-width'], '0');
      expect(inline['padding'], _inline(area.textarea)['padding']);
      expect(inline, isNot(contains('flex')));
    });

    testComponents('the textAreaStyle slot is forwarded to the box', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveRichEditor(
        context,
        enabled: true,
        richEditorStyle: const CoreRichEditorStyle(
          textAreaStyle: CoreTextAreaStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
          ),
        ),
      );
      expect(
        _inline(resolved.box)['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius16).toValue(),
      );
      // The ring follows the corners the box has, and the surface has none.
      expect(
        resolved.focusOutlineStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius16),
      );
      expect(_inline(resolved.surface), isNot(contains('border-radius')));
    });

    testComponents('the height range is the editor’s own', (tester) async {
      final context = _themedContext(tester);
      final defaults = resolveRichEditor(context, enabled: true);
      expect(
        _inline(defaults.surface)['min-height'],
        '${CoreRichEditorStyle.defaultMinHeight / 16}rem',
      );
      expect(
        _inline(defaults.surface)['max-height'],
        '${CoreRichEditorStyle.defaultMaxHeight / 16}rem',
      );
      final custom = resolveRichEditor(
        context,
        enabled: true,
        richEditorStyle: const CoreRichEditorStyle(minHeight: 40),
      );
      expect(_inline(custom.surface)['min-height'], '2.5rem');
    });

    // Jaspr's output formatter indents the document markup it paints on the
    // server, and a `pre-wrap` surface draws that indentation as a blank line
    // above and below the blocks — the editor was taller on the first paint
    // than once the browser had taken it over (278 against 194 in the parity
    // capture of the default example).
    testComponents('the server surface collapses the white space around its '
        'blocks, the browser one keeps what is typed', (tester) async {
      final context = _themedContext(tester);
      List<String> surface({required bool serverRendered}) => resolveRichEditor(
        context,
        enabled: true,
        serverRendered: serverRendered,
      ).surface.className.split(' ');

      final server = surface(serverRendered: true);
      expect(server, contains(WebLayout.whitespaceNormal));
      expect(server, isNot(contains(WebLayout.whitespacePreWrap)));

      final browser = surface(serverRendered: false);
      expect(browser, contains(WebLayout.whitespacePreWrap));
      expect(browser, isNot(contains(WebLayout.whitespaceNormal)));
    });

    testComponents('the active button is the button with the active chrome', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveRichEditor(context, enabled: true);
      expect(
        resolved.toolbarButtonStyle,
        CoreRichEditorStyle.defaultToolbarButtonStyle,
      );
      expect(
        resolved.activeToolbarButtonStyle,
        CoreRichEditorStyle.defaultToolbarButtonStyle.merge(
          CoreRichEditorStyle.defaultActiveToolbarButtonStyle,
        ),
      );
    });

    testComponents('an instance button override reaches both states', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const override = CoreButtonStyle(height: CoreSize.size40);
      final resolved = resolveRichEditor(
        context,
        enabled: true,
        richEditorStyle: const CoreRichEditorStyle(
          toolbarButtonStyle: override,
        ),
      );
      expect(resolved.toolbarButtonStyle.height, CoreSize.size40);
      expect(resolved.activeToolbarButtonStyle.height, CoreSize.size40);
      expect(
        resolved.activeToolbarButtonStyle.backgroundColor,
        CoreRichEditorStyle.defaultActiveToolbarButtonStyle.backgroundColor,
      );
    });

    testComponents('disabled states the text area’s disabled row', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveRichEditor(context, enabled: false);
      final row = CoreTextAreaStyle
          .defaultsByVariant[CoreTextAreaVariant.defaultVariant]!;
      // The `contenteditable` `<div>` never matches `:disabled`: the box
      // states the row's fill and border itself, the surface its text.
      expect(
        _inline(resolved.box)['background-color'],
        row.disabledBackgroundColor.toValue(),
      );
      expect(
        _inline(resolved.box)['border-color'],
        row.disabledBorderColor.toValue(),
      );
      expect(
        _inline(resolved.surface)['color'],
        row.disabledForegroundColor.toValue(),
      );
      expect(_inline(resolved.surface), isNot(contains('background-color')));
      expect(_inline(resolved.surface), isNot(contains('border-color')));
      expect(resolved.surface.className, contains('cursor-not-allowed'));
      // The strip is part of the box, and so is the cursor over it.
      expect(resolved.box.className, contains('cursor-not-allowed'));

      // Enabled, none of it is stated: the classes do the colouring.
      final enabled = resolveRichEditor(context, enabled: true);
      expect(_inline(enabled.box), isNot(contains('border-color')));
      expect(_inline(enabled.surface), isNot(contains('color')));
      expect(enabled.box.className, isNot(contains('cursor-not-allowed')));
    });

    testComponents('a colour the textAreaStyle states wins over the disabled '
        'row', (tester) async {
      final context = _themedContext(tester);
      const fill = CoreColor(0xFF112233);
      const border = CoreColor(0xFF445566);
      final resolved = resolveRichEditor(
        context,
        enabled: false,
        richEditorStyle: const CoreRichEditorStyle(
          textAreaStyle: CoreTextAreaStyle(
            backgroundColor: fill,
            borderColor: border,
          ),
        ),
      );
      expect(_inline(resolved.box)['background-color'], fill.toValue());
      expect(_inline(resolved.box)['border-color'], border.toValue());
    });

    group('the toolbar strip', () {
      testComponents('is a wrapping row in the surface-container step', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final resolved = resolveRichEditor(context, enabled: true);
        expect(
          resolved.toolbar.className.split(' '),
          containsAll([
            WebLayout.flex,
            WebLayout.flexWrap,
            WebLayout.justifyBetween,
            WebLayout.itemsCenter,
            WebLayout.shrinkZero,
            _stripClass,
          ]),
        );
        final inline = _inline(resolved.toolbar);
        // Directional: 12 on the side the text starts on, 8 on the other.
        expect(inline['padding-inline-start'], spaceCss(CoreSpace.space12));
        expect(inline['padding-inline-end'], spaceCss(CoreSpace.space8));
        expect(inline['padding-block-start'], spaceCss(CoreSpace.space4));
        expect(inline['padding-block-end'], spaceCss(CoreSpace.space4));
        expect(inline, isNot(contains('padding')));
        // The rows of a toolbar that wraps — its buttons, then the trailing
        // slot — are a row gap apart.
        expect(
          inline['row-gap'],
          spaceCss(CoreRichEditorStyle.defaultToolbarRowSpacing),
        );
        expect(inline, isNot(contains('background-color')));
      });

      testComponents('states the fill, the padding and the row gap the style '
          'asks for', (tester) async {
        final context = _themedContext(tester);
        const fill = CoreColor(0xFF112233);
        const padding = CoreEdgeInsets.all(CoreSpace.space16);
        final resolved = resolveRichEditor(
          context,
          enabled: true,
          richEditorStyle: const CoreRichEditorStyle(
            toolbarBackgroundColor: fill,
            toolbarPadding: padding,
            toolbarRowSpacing: CoreSpace.space12,
          ),
        );
        final inline = _inline(resolved.toolbar);
        // A raw colour has no class: it rides inline.
        expect(inline['background-color'], fill.toValue());
        expect(
          resolved.toolbar.className
              .split(' ')
              .where(
                (cls) => cls.startsWith('bg-'),
              ),
          isEmpty,
        );
        expect(inline['padding'], padding.toValue());
        expect(inline['row-gap'], spaceCss(CoreSpace.space12));

        // A token fill keeps to the class, so it follows the theme.
        const higher = CoreColor.token(CoreColors.surfaceContainerHigh);
        final token = resolveRichEditor(
          context,
          enabled: true,
          richEditorStyle: const CoreRichEditorStyle(
            toolbarBackgroundColor: higher,
          ),
        );
        expect(
          token.toolbar.className.split(' '),
          contains(_bgClass(higher)),
        );
        expect(_inline(token.toolbar), isNot(contains('background-color')));
      });

      testComponents('is not painted while the editor is disabled', (
        tester,
      ) async {
        final context = _themedContext(tester);
        for (final style in const [
          null,
          CoreRichEditorStyle(toolbarBackgroundColor: CoreColor(0xFF112233)),
        ]) {
          final resolved = resolveRichEditor(
            context,
            enabled: false,
            richEditorStyle: style,
          );
          expect(
            resolved.toolbar.className
                .split(' ')
                .where(
                  (cls) => cls.startsWith('bg-'),
                ),
            isEmpty,
          );
          expect(
            _inline(resolved.toolbar),
            isNot(contains('background-color')),
          );
          // The strip keeps its shape: only the fill goes.
          expect(_inline(resolved.toolbar), contains('padding-inline-start'));
        }
      });
    });

    group('the lines of the toolbar', () {
      testComponents('the line between groups is as long as the style says', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final defaults = resolveRichEditor(context, enabled: true);
        expect(
          _inline(defaults.toolbarGroupDivider!)['height'],
          '${CoreRichEditorStyle.defaultToolbarGroupDividerHeight / 16}rem',
        );
        final taller = resolveRichEditor(
          context,
          enabled: true,
          richEditorStyle: const CoreRichEditorStyle(
            toolbarGroupDividerHeight: CoreSize.size32,
          ),
        );
        expect(_inline(taller.toolbarGroupDivider!)['height'], '2.0rem');
      });

      testComponents('a length of 0 draws no line between groups', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final resolved = resolveRichEditor(
          context,
          enabled: true,
          richEditorStyle: const CoreRichEditorStyle(
            toolbarGroupDividerHeight: 0,
          ),
        );
        expect(resolved.toolbarGroupDivider, isNull);
      });

      testComponents('toolbarDividerStyle is forwarded raw to the Dividers', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final defaults = resolveRichEditor(context, enabled: true);
        expect(
          defaults.toolbarDividerStyle,
          CoreRichEditorStyle.defaultToolbarDividerStyle,
        );
        const override = CoreDividerStyle(thickness: CoreStrokeWidth.stroke2);
        final custom = resolveRichEditor(
          context,
          enabled: true,
          richEditorStyle: const CoreRichEditorStyle(
            toolbarDividerStyle: override,
          ),
        );
        expect(custom.toolbarDividerStyle.thickness, CoreStrokeWidth.stroke2);
        expect(custom.toolbarDividerStyle.color, isNull);
        // The lines between groups get the same slot.
        expect(
          custom.toolbarGroupDividerStyle.thickness,
          CoreStrokeWidth.stroke2,
        );
        expect(custom.toolbarGroupDividerStyle.color, isNull);
      });

      testComponents(
        'a disabled editor draws the line under the strip in disabled-outline '
        'and leaves the lines between groups alone',
        (tester) async {
          final context = _themedContext(tester);
          final resolved = resolveRichEditor(context, enabled: false);
          expect(
            resolved.toolbarDividerStyle.color,
            const CoreColor.token(CoreColors.disabledOutline),
          );
          expect(resolved.toolbarGroupDividerStyle.color, isNull);
          // The rest of the style is left as it was.
          final thick = resolveRichEditor(
            context,
            enabled: false,
            richEditorStyle: const CoreRichEditorStyle(
              toolbarDividerStyle: CoreDividerStyle(
                thickness: CoreStrokeWidth.stroke2,
              ),
            ),
          );
          expect(thick.toolbarDividerStyle.thickness, CoreStrokeWidth.stroke2);
          expect(
            thick.toolbarDividerStyle.color,
            const CoreColor.token(CoreColors.disabledOutline),
          );
          expect(
            thick.toolbarGroupDividerStyle.thickness,
            CoreStrokeWidth.stroke2,
          );
          expect(thick.toolbarGroupDividerStyle.color, isNull);
        },
      );

      testComponents('a colour the style states wins, disabled or not', (
        tester,
      ) async {
        final context = _themedContext(tester);
        const color = CoreColor(0xFF112233);
        for (final enabled in [true, false]) {
          final resolved = resolveRichEditor(
            context,
            enabled: enabled,
            richEditorStyle: const CoreRichEditorStyle(
              toolbarDividerStyle: CoreDividerStyle(color: color),
            ),
          );
          expect(resolved.toolbarDividerStyle.color, color, reason: '$enabled');
          expect(
            resolved.toolbarGroupDividerStyle.color,
            color,
            reason: '$enabled',
          );
        }
      });
    });

    testComponents('the upload row is an Alert, styled by uploadAlertStyle', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final defaults = resolveRichEditor(context, enabled: true);
      expect(
        defaults.uploadAlertStyle,
        CoreRichEditorStyle.defaultUploadAlertStyle,
      );
      const override = CoreAlertStyle(minHeight: CoreSize.size48);
      final custom = resolveRichEditor(
        context,
        enabled: true,
        richEditorStyle: const CoreRichEditorStyle(uploadAlertStyle: override),
      );
      expect(custom.uploadAlertStyle.minHeight, CoreSize.size48);
    });

    testComponents('the upload rows stack, spaced like the toolbar buttons', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveRichEditor(context, enabled: true);
      expect(resolved.pendingImages.className, WebLayout.flexColFull);
      expect(
        _inline(resolved.pendingImages)['gap'],
        _inline(resolved.toolbarGroup)['gap'],
      );
      final wide = resolveRichEditor(
        context,
        enabled: true,
        richEditorStyle: const CoreRichEditorStyle(toolbarItemSpacing: 8),
      );
      expect(
        _inline(wide.pendingImages)['gap'],
        _inline(wide.toolbarGroup)['gap'],
      );
      expect(
        _inline(wide.pendingImages)['gap'],
        isNot(_inline(resolved.pendingImages)['gap']),
      );
    });

    testComponents('the counter turns to the error colour at the limit', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final under = resolveRichEditor(context, enabled: true);
      final at = resolveRichEditor(
        context,
        enabled: true,
        counterAtLimit: true,
      );
      final errorClass =
          'text-${CoreTextAreaStyle.defaultErrorTextColor.tailwindColor}';
      expect(under.counter.className, isNot(contains(errorClass)));
      expect(at.counter.className, contains(errorClass));
    });
  });

  group('resolveRichEditorRules', () {
    String sizeOf(CoreTextStyle style) =>
        'font-size:var(--coui-text-${style.token!.name}-size)';

    testComponents('each heading level takes its own text role', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final css = resolveRichEditorRules(context, scopeId: 'ed').css;
      expect(
        css,
        contains(
          '#ed h1{${sizeOf(CoreRichEditorStyle.defaultHeading1TextStyle)}',
        ),
      );
      expect(
        css,
        contains(
          '#ed h2{${sizeOf(CoreRichEditorStyle.defaultHeading2TextStyle)}',
        ),
      );
      expect(
        css,
        contains(
          '#ed h3,#ed h4,#ed h5,#ed h6{'
          '${sizeOf(CoreRichEditorStyle.defaultHeading3TextStyle)}',
        ),
      );
      // Three different steps, largest first.
      expect({
        CoreRichEditorStyle.defaultHeading1TextStyle.token!.name,
        CoreRichEditorStyle.defaultHeading2TextStyle.token!.name,
        CoreRichEditorStyle.defaultHeading3TextStyle.token!.name,
      }, hasLength(3));
    });

    testComponents('a heading style set on the editor reaches only its level', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const larger = CoreTextStyle.token(CoreTextStyles.headlineSmall);
      final css = resolveRichEditorRules(
        context,
        scopeId: 'ed',
        richEditorStyle: const CoreRichEditorStyle(heading2TextStyle: larger),
      ).css;
      expect(css, contains('#ed h2{${sizeOf(larger)}'));
      expect(
        css,
        contains(
          '#ed h1{${sizeOf(CoreRichEditorStyle.defaultHeading1TextStyle)}',
        ),
      );
      expect(
        css,
        contains(
          '#ed h3,#ed h4,#ed h5,#ed h6{'
          '${sizeOf(CoreRichEditorStyle.defaultHeading3TextStyle)}',
        ),
      );
    });

    testComponents('an image is scaled into the box, never up', (tester) async {
      final context = _themedContext(tester);
      final css = resolveRichEditorRules(context, scopeId: 'ed').css;
      final radius = CoreRichEditorStyle.defaultImageBorderRadius.toValue();
      expect(css, contains('#ed img{display:inline-block;'));
      expect(css, contains('max-width:100%;'));
      expect(
        css,
        contains(
          'max-height:${CoreRichEditorStyle.defaultImageMaxHeight / 16}rem;',
        ),
      );
      expect(css, contains('border-radius:$radius;'));
      expect(
        css,
        contains(
          'background-color:'
          '${CoreRichEditorStyle.defaultImageBackgroundColor.toValue()}}',
        ),
      );
    });

    testComponents(
      'an image that cannot be loaded keeps a box the size of the Flutter '
      'placeholder, so it can still be seen and selected',
      (tester) async {
        final context = _themedContext(tester);
        final css = resolveRichEditorRules(context, scopeId: 'ed').css;
        const height = CoreRichEditorStyle.defaultImageMaxHeight;
        const box =
            'min-width:${height / 16}rem;min-height:${height / 2 / 16}rem';
        expect(css, contains('#ed img[data-unavailable]{$box}'));
      },
    );

    testComponents('image style values reach the image rule', (tester) async {
      final context = _themedContext(tester);
      final css = resolveRichEditorRules(
        context,
        scopeId: 'ed',
        richEditorStyle: const CoreRichEditorStyle(
          imageMaxHeight: 64,
          imageBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
          imageBackgroundColor: CoreColor(0xFF112233),
        ),
      ).css;
      expect(css, contains('max-height:4.0rem;'));
      expect(
        css,
        contains(
          'border-radius:'
          '${const CoreBorderRadius.all(CoreRadius.radius16).toValue()};',
        ),
      );
      expect(
        css,
        contains('background-color:${const CoreColor(0xFF112233).toValue()}}'),
      );
      expect(
        css,
        contains(
          '#ed img[data-unavailable]{min-width:4.0rem;min-height:2.0rem}',
        ),
      );
    });

    testComponents('style values reach the scoped rules', (tester) async {
      final context = _themedContext(tester);
      final rules = resolveRichEditorRules(
        context,
        scopeId: 'ed',
        richEditorStyle: const CoreRichEditorStyle(
          linkColor: CoreColor(0xFF112233),
          quoteBarWidth: CoreStrokeWidth.stroke2,
        ),
      );
      expect(
        rules.css,
        contains('#ed a{color:${const CoreColor(0xFF112233).toValue()}'),
      );
      expect(
        rules.css,
        contains(
          'border-inline-start:${strokeWidthCss(CoreStrokeWidth.stroke2)}',
        ),
      );
    });
  });
}
