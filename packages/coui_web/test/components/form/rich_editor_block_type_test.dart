// Pins the Web `RichEditor`'s block-type button and menu: the first toolbar
// entry is a plain `sm` `Button` naming the caret's block with a chevron 4
// after it, it opens a `DropdownMenu` of Text and the three headings with the
// current one checked and the Markdown of each heading at its end, and a
// disabled editor draws the button alone. Also the toolbar's directional
// inset and the disabled colour of its glyphs.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_style.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' as server;

void _pumpServer(server.ServerTester tester, Component editor) =>
    tester.pumpComponent(CoUIWeb(theme: .coui, child: editor));

/// The block-type `Button` — the first one in the toolbar.
Finder get _blockTypeButton => find
    .descendant(
      of: find.byComponentPredicate(
        (c) => c is div && c.attributes?['role'] == 'toolbar',
      ),
      matching: find.byType(Button),
    )
    .first;

/// The `DropdownMenu` trigger the block-type button sits in.
Finder get _trigger => find.byComponentPredicate(
  (c) => c is div && c.attributes?['aria-haspopup'] == 'true',
);

Future<void> _open(ComponentTester tester) async {
  tester.dispatchEvent(_trigger, 'click');
  await tester.pump();
  await tester.pump();
}

void main() {
  group('RichEditor block-type button — server markup', () {
    server.testServer('opens the toolbar, named Text, with a chevron', (
      tester,
    ) async {
      _pumpServer(tester, const RichEditor());
      final document = (await tester.request('/')).document!;
      final toolbar = document.querySelector('[role=toolbar]')!;
      final first = toolbar.querySelector('[role=group]')!;
      final button = first.querySelector('button')!;
      expect(button.text.trim(), 'Text');
      // Named for what it picks and the block it shows: the visible label
      // alone would read as a button called "Text".
      expect(button.attributes['aria-label'], 'Block type: Text');
      // No tooltip: the label already is the block's name.
      expect(button.attributes.containsKey('aria-describedby'), isFalse);
      // The menu trigger says it opens one.
      expect(button.parent!.attributes['aria-haspopup'], 'true');
      expect(button.parent!.attributes['aria-expanded'], 'false');
      // The first group is the block-type button alone.
      expect(first.querySelectorAll('button'), hasLength(1));
    });

    server.testServer('a disabled editor draws the button alone, disabled', (
      tester,
    ) async {
      _pumpServer(tester, const RichEditor(enabled: false));
      final document = (await tester.request('/')).document!;
      final first = document.querySelector('[role=toolbar] [role=group]')!;
      final button = first.querySelector('button')!;
      expect(button.attributes.containsKey('disabled'), isTrue);
      expect(button.text.trim(), 'Text');
      expect(first.querySelector('[aria-haspopup]'), isNull);
    });
  });

  group('RichEditor disabled toolbar', () {
    server.testServer('every button takes the disabled-content ink', (
      tester,
    ) async {
      _pumpServer(tester, const RichEditor(enabled: false));
      final document = (await tester.request('/')).document!;
      final ink =
          'disabled:text-'
          '${const CoreColor.token(CoreColors.disabledContent).tailwindColor}';
      final buttons = document.querySelectorAll('[role=toolbar] button');
      expect(buttons, hasLength(10));
      for (final button in buttons) {
        final label = button.attributes['aria-label'] ?? button.text.trim();
        expect(
          button.attributes.containsKey('disabled'),
          isTrue,
          reason: label,
        );
        expect(button.classes, contains(ink), reason: label);
        // Nothing inside paints a colour of its own over the button's ink,
        // and nothing paints it inline.
        expect(button.attributes['style'] ?? '', isNot(contains('color:')));
        for (final inner in button.querySelectorAll('*')) {
          expect(
            inner.classes.where((cls) => cls.startsWith('text-on-')),
            isEmpty,
            reason: '$label ${inner.localName}',
          );
        }
      }
    });
  });

  group('RichEditor block-type button — composition', () {
    testComponents('a plain sm Button, the label 4 from its chevron', (
      tester,
    ) async {
      tester.pumpComponent(hostedEditor(const RichEditor()));
      await tester.pump();
      final button = _component<Button>(_blockTypeButton);
      expect(button.variant, CoreButtonVariant.plain);
      expect(button.size, CoreComponentSize.sm);
      expect(button.shape, CoreButtonShape.rectangle);
      expect(button.buttonStyle?.iconLabelGapStyle?.size, CoreSpace.space4);
      final trailing = button.trailing! as Icon;
      expect(trailing.icon, LucideIcons.chevronDown);
      expect(
        find.descendant(of: _blockTypeButton, matching: find.text('Text')),
        findsOneComponent,
      );
    });

    testComponents('the Style slot reaches the button and the menu', (
      tester,
    ) async {
      const menu = CoreDropdownMenuStyle(menuOffset: CoreSpace.space8);
      tester.pumpComponent(
        hostedEditor(
          const RichEditor(
            richEditorStyle: CoreRichEditorStyle(
              blockTypeButtonStyle: CoreButtonStyle(
                iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
              ),
              blockTypeMenuStyle: menu,
            ),
          ),
        ),
      );
      await tester.pump();
      final button = _component<Button>(_blockTypeButton);
      expect(button.buttonStyle?.iconLabelGapStyle?.size, CoreSpace.space8);
      final dropdown = _component<DropdownMenu>(
        find.byType(DropdownMenu),
      );
      expect(dropdown.dropdownMenuStyle?.menuOffset, CoreSpace.space8);
    });

    testComponents(
      'opens Text and the headings, Text checked, the headings with # hints',
      (tester) async {
        tester.pumpComponent(hostedEditor(const RichEditor()));
        await tester.pump();
        await _open(tester);
        final dropdown = _component<DropdownMenu>(
          find.byType(DropdownMenu),
        );
        expect(
          [for (final item in dropdown.items) item.label],
          ['Text', 'Heading 1', 'Heading 2', 'Heading 3'],
        );
        expect(
          [for (final item in dropdown.items) item.kind],
          List.filled(4, CoreMenuItemKind.radio),
        );
        expect(
          [for (final item in dropdown.items) item.radioMark],
          List.filled(4, CoreMenuRadioMark.check),
        );
        expect(
          [for (final item in dropdown.items) item.selected],
          [true, false, false, false],
        );
        expect(
          [for (final item in dropdown.items) item.shortcut],
          [null, '#', '##', '###'],
        );
        // The panel is open, and draws the rows with their hints.
        for (final label in ['Text', 'Heading 1', 'Heading 2', 'Heading 3']) {
          expect(find.text(label), findsComponents, reason: label);
        }
        expect(find.text('###'), findsOneComponent);
        // The rows are the choices of one group — four radio rows, one of
        // them checked — and none is a checkbox.
        Finder rows(String role, {String? checked}) =>
            find.byComponentPredicate(
              (c) =>
                  c is DomComponent &&
                  c.attributes?['role'] == role &&
                  (checked == null || c.attributes?['aria-checked'] == checked),
            );
        expect(rows('menuitemradio'), findsNComponents(4));
        expect(rows('menuitemradio', checked: 'true'), findsOneComponent);
        expect(rows('menuitemcheckbox'), findsNothing);
        // The checked row draws a check, not the dot of a radio-button list.
        final marks = [
          for (final element
              in find
                  .descendant(
                    of: rows('menuitemradio', checked: 'true'),
                    matching: find.byType(Icon),
                  )
                  .evaluate())
            (element.component as Icon).icon,
        ];
        expect(marks, [LucideIcons.check]);
      },
    );

    testComponents('the image button draws the image glyph', (tester) async {
      tester.pumpComponent(
        hostedEditor(
          RichEditor(
            onImageUpload: (file) async => 'unused',
            onImageDelete: (url) async {},
          ),
        ),
      );
      await tester.pump();
      final icons = [
        for (final element in find.byType(Icon).evaluate())
          (element.component as Icon).icon,
      ];
      expect(icons.last, LucideIcons.image);
      expect(icons, isNot(contains(LucideIcons.imagePlus)));
    });

    testComponents('picking a row closes the menu', (tester) async {
      tester.pumpComponent(hostedEditor(const RichEditor()));
      await tester.pump();
      await _open(tester);
      final dropdown = _component<DropdownMenu>(
        find.byType(DropdownMenu),
      );
      expect(dropdown.controller!.isOpen, isTrue);
      dropdown.items[1].onChanged!(true);
      await tester.pump();
      await tester.pump();
      expect(dropdown.controller!.isOpen, isFalse);
    });
  });

  group('resolveRichEditor — the toolbar', () {
    testComponents('the inset is 12 at the start, 8 at the end, 4 around', (
      tester,
    ) async {
      late BuildContext context;
      tester.pumpComponent(
        Theme.defaults(
          child: Builder(
            builder: (c) {
              context = c;
              return const div([]);
            },
          ),
        ),
      );
      final resolved = resolveRichEditor(context, enabled: true);
      final inline = resolved.toolbar.inlineStyles!.properties;
      expect(inline['padding-inline-start'], spaceCss(CoreSpace.space12));
      expect(inline['padding-inline-end'], spaceCss(CoreSpace.space8));
      expect(inline['padding-block-start'], spaceCss(CoreSpace.space4));
      expect(inline['padding-block-end'], spaceCss(CoreSpace.space4));
    });
  });
}

/// The single component [finder] finds.
T _component<T extends Component>(Finder finder) =>
    finder.evaluate().single.component as T;

/// The editor under a host, as `CoUIWeb` mounts one: the menu panel renders
/// in the host's layer.
Component hostedEditor(Component editor) =>
    Theme.defaults(child: OverlayHost(child: editor));
