// Tests for the `RichEditor` format table: the shortcut each format is bound
// to, how a tooltip spells it, and which toolbar buttons an editor shows.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('shortcuts', () {
    test('every format with a shortcut is found by its own key', () {
      for (final format in CoreRichEditorFormat.values) {
        final shortcut = format.shortcut;
        if (shortcut == null) continue;
        expect(
          CoreRichEditorFormat.forKey(
            shortcut.key,
            shift: shortcut.shift,
            alt: shortcut.alt,
          ),
          format,
          reason: format.name,
        );
      }
    });

    test('no two formats share a shortcut', () {
      final seen = <CoreRichEditorShortcut, CoreRichEditorFormat>{};
      for (final format in CoreRichEditorFormat.values) {
        final shortcut = format.shortcut;
        if (shortcut == null) continue;
        expect(
          seen[shortcut],
          isNull,
          reason: '${format.name} repeats ${seen[shortcut]?.name}',
        );
        seen[shortcut] = format;
      }
    });

    test('the headings are Mod+Alt+1, 2 and 3', () {
      expect(
        CoreRichEditorFormat.forKey('1', shift: false, alt: true),
        CoreRichEditorFormat.heading1,
      );
      expect(
        CoreRichEditorFormat.forKey('2', shift: false, alt: true),
        CoreRichEditorFormat.heading2,
      );
      expect(
        CoreRichEditorFormat.forKey('3', shift: false, alt: true),
        CoreRichEditorFormat.heading3,
      );
    });

    test('Alt is part of the shortcut, not an extra that is ignored', () {
      // Mod+1 alone and Mod+Alt+8 name nothing; Mod+Shift+8 is still the list.
      expect(CoreRichEditorFormat.forKey('1', shift: false), isNull);
      expect(CoreRichEditorFormat.forKey('8', shift: true, alt: true), isNull);
      expect(
        CoreRichEditorFormat.forKey('8', shift: true),
        CoreRichEditorFormat.bulletedList,
      );
    });

    test('the key is case-insensitive', () {
      expect(
        CoreRichEditorFormat.forKey('b', shift: false),
        CoreRichEditorFormat.bold,
      );
    });

    test('the image button has no shortcut', () {
      expect(CoreRichEditorFormat.image.shortcut, isNull);
    });

    test("key caps follow each platform's order", () {
      const heading = CoreRichEditorShortcut('1', alt: true);
      expect(heading.keyCaps(apple: true), ['⌥', '⌘', '1']);
      expect(heading.keyCaps(apple: false), ['Ctrl', 'Alt', '1']);
      const strike = CoreRichEditorShortcut('X', shift: true);
      expect(strike.keyCaps(apple: true), ['⇧', '⌘', 'X']);
      expect(strike.keyCaps(apple: false), ['Ctrl', 'Shift', 'X']);
      const all = CoreRichEditorShortcut('9', shift: true, alt: true);
      expect(all.keyCaps(apple: true), ['⌥', '⇧', '⌘', '9']);
      expect(all.keyCaps(apple: false), ['Ctrl', 'Alt', 'Shift', '9']);
    });

    test('shortcuts compare by key, Shift and Alt', () {
      expect(
        const CoreRichEditorShortcut('1', alt: true),
        const CoreRichEditorShortcut('1', alt: true),
      );
      expect(
        const CoreRichEditorShortcut('1', alt: true),
        isNot(const CoreRichEditorShortcut('1')),
      );
      expect(
        const CoreRichEditorShortcut('1', alt: true).hashCode,
        isNot(const CoreRichEditorShortcut('1').hashCode),
      );
    });
  });

  group('kinds', () {
    test('the five marks are inline, nothing after them is', () {
      const inline = {
        CoreRichEditorFormat.bold,
        CoreRichEditorFormat.italic,
        CoreRichEditorFormat.strikethrough,
        CoreRichEditorFormat.code,
        CoreRichEditorFormat.link,
      };
      for (final format in CoreRichEditorFormat.values) {
        expect(format.isInline, inline.contains(format), reason: format.name);
      }
    });

    test('the headings carry their level', () {
      expect(CoreRichEditorFormat.heading1.headingLevel, 1);
      expect(CoreRichEditorFormat.heading2.headingLevel, 2);
      expect(CoreRichEditorFormat.heading3.headingLevel, 3);
      expect(CoreRichEditorFormat.bold.headingLevel, isNull);
      expect(CoreRichEditorFormat.image.headingLevel, isNull);
    });

    test('only the image button needs an upload', () {
      for (final format in CoreRichEditorFormat.values) {
        expect(
          format.needsImageUpload,
          format == CoreRichEditorFormat.image,
          reason: format.name,
        );
      }
    });
  });

  group('toolbar', () {
    test('the default toolbar offers every format exactly once', () {
      final formats = [
        for (final group in CoreRichEditorFormat.defaultToolbar) ...group,
      ];
      // The headings are rows of the block-type menu, not buttons.
      const headings = {
        CoreRichEditorFormat.heading1,
        CoreRichEditorFormat.heading2,
        CoreRichEditorFormat.heading3,
      };
      expect(
        formats.toSet(),
        CoreRichEditorFormat.values.toSet().difference(headings),
      );
      expect(formats, hasLength(CoreRichEditorFormat.values.length - 3));
      // Every heading is a row of that menu.
      expect({
        for (final type in CoreRichEditorBlockType.values) ?type.format,
      }, headings);
    });

    test('the block type leads and the quote shares its group with the '
        'image', () {
      const toolbar = CoreRichEditorFormat.defaultToolbar;
      expect(toolbar, hasLength(4));
      expect(toolbar.first, [CoreRichEditorFormat.blockType]);
      expect(toolbar.last, [
        CoreRichEditorFormat.quote,
        CoreRichEditorFormat.image,
      ]);
    });

    test('without an upload the image button goes and the quote stays', () {
      final visible = CoreRichEditorFormat.visibleToolbar(
        CoreRichEditorFormat.defaultToolbar,
        images: false,
      );
      // No group is emptied by it: the quote keeps the last one.
      expect(visible, hasLength(CoreRichEditorFormat.defaultToolbar.length));
      expect(visible.last, [CoreRichEditorFormat.quote]);
      expect(
        [for (final group in visible) ...group],
        isNot(contains(CoreRichEditorFormat.image)),
      );
    });

    test('with an upload the default toolbar is untouched', () {
      expect(
        CoreRichEditorFormat.visibleToolbar(
          CoreRichEditorFormat.defaultToolbar,
          images: true,
        ),
        CoreRichEditorFormat.defaultToolbar,
      );
    });

    test('a custom toolbar keeps the image button where it was put', () {
      const custom = [
        [CoreRichEditorFormat.bold, CoreRichEditorFormat.image],
        <CoreRichEditorFormat>[],
        [CoreRichEditorFormat.image],
      ];
      expect(CoreRichEditorFormat.visibleToolbar(custom, images: true), [
        [CoreRichEditorFormat.bold, CoreRichEditorFormat.image],
        [CoreRichEditorFormat.image],
      ]);
      expect(CoreRichEditorFormat.visibleToolbar(custom, images: false), [
        [CoreRichEditorFormat.bold],
      ]);
    });
  });

  group('block type', () {
    test('the button is named for what it picks and the block it shows', () {
      expect(
        CoreRichEditorContract.blockTypeButtonLabel('Block type', 'Text'),
        'Block type: Text',
      );
    });

    test('a radio entry draws the dot unless it states the check', () {
      const plain = CoreMenuItem<Object>.radio('A');
      expect(plain.radioMark, CoreMenuRadioMark.dot);
      expect(plain.radioMark.icon, LucideIcons.circleDot);
      const checked = CoreMenuItem<Object>.radio(
        'A',
        shortcut: '#',
        radioMark: CoreMenuRadioMark.check,
      );
      expect(checked.kind, CoreMenuItemKind.radio);
      expect(checked.radioMark.icon, LucideIcons.check);
      expect(checked.shortcut, '#');
    });

    test('the menu lists Text, then the headings, with their Markdown', () {
      expect(CoreRichEditorBlockType.values.map((t) => t.format), [
        null,
        CoreRichEditorFormat.heading1,
        CoreRichEditorFormat.heading2,
        CoreRichEditorFormat.heading3,
      ]);
      expect(CoreRichEditorBlockType.values.map((t) => t.markdownPrefix), [
        null,
        '#',
        '##',
        '###',
      ]);
    });

    test('the caret block is the heading on there, else a paragraph', () {
      expect(
        CoreRichEditorBlockType.of(const {}),
        CoreRichEditorBlockType.paragraph,
      );
      expect(
        CoreRichEditorBlockType.of(const {
          CoreRichEditorFormat.bold,
          CoreRichEditorFormat.heading3,
        }),
        CoreRichEditorBlockType.heading3,
      );
      // A list item or a quote is none of the four.
      expect(
        CoreRichEditorBlockType.of(const {CoreRichEditorFormat.quote}),
        CoreRichEditorBlockType.paragraph,
      );
    });

    test('a row toggles its heading; Text the one the caret is in', () {
      const p = CoreRichEditorBlockType.paragraph;
      const h1 = CoreRichEditorBlockType.heading1;
      const h2 = CoreRichEditorBlockType.heading2;
      expect(h1.toggleFrom(p), CoreRichEditorFormat.heading1);
      expect(h2.toggleFrom(h1), CoreRichEditorFormat.heading2);
      expect(p.toggleFrom(h2), CoreRichEditorFormat.heading2);
      // The row of the block the caret is in would toggle it off.
      expect(h1.toggleFrom(h1), isNull);
      expect(p.toggleFrom(p), isNull);
    });

    test('the block type has no shortcut and is no inline mark', () {
      expect(CoreRichEditorFormat.blockType.shortcut, isNull);
      expect(CoreRichEditorFormat.blockType.isInline, isFalse);
      expect(CoreRichEditorFormat.blockType.headingLevel, isNull);
    });
  });

  group('toolbar style defaults', () {
    test('the strip is inset 12 at the start, 8 at the end, 4 around', () {
      const padding = CoreRichEditorStyle.defaultToolbarPadding;
      expect(padding.isDirectional, isTrue);
      expect(padding.start, CoreSpace.space12);
      expect(padding.end, CoreSpace.space8);
      expect(padding.top, CoreSpace.space4);
      expect(padding.bottom, CoreSpace.space4);
    });

    test('the block-type label is 4 from its chevron', () {
      expect(
        CoreRichEditorStyle.defaultBlockTypeButtonStyle.iconLabelGapStyle,
        const CoreGapStyle(size: CoreSpace.space4),
      );
    });

    test('the block-type slots merge and compare', () {
      const a = CoreRichEditorStyle(
        blockTypeButtonStyle: CoreButtonStyle(height: 1),
        blockTypeMenuStyle: CoreDropdownMenuStyle(menuOffset: 1),
      );
      const b = CoreRichEditorStyle(
        blockTypeButtonStyle: CoreButtonStyle(width: 2),
        blockTypeMenuStyle: CoreDropdownMenuStyle(menuOffset: 2),
      );
      final merged = a.merge(b);
      expect(merged.blockTypeButtonStyle?.height, 1);
      expect(merged.blockTypeButtonStyle?.width, 2);
      expect(merged.blockTypeMenuStyle?.menuOffset, 2);
      expect(a, isNot(b));
      expect(
        a,
        const CoreRichEditorStyle(
          blockTypeButtonStyle: CoreButtonStyle(height: 1),
          blockTypeMenuStyle: CoreDropdownMenuStyle(menuOffset: 1),
        ),
      );
      expect(a.hashCode, isNot(const CoreRichEditorStyle().hashCode));
    });
  });
}
