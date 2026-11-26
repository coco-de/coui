/// Formats a `RichEditor` toolbar offers, and the shortcut of each.
library;

import 'package:meta/meta.dart';

/// One formatting command of a `RichEditor` — a toolbar button and its
/// keyboard shortcut.
///
/// The five inline formats mark a run of text; the block formats turn the
/// caret's block into another kind and back (the three headings, the lists
/// and the quote); [image] adds a picture; [blockType] is the toolbar's
/// block-type menu, which picks between a paragraph and the three headings.
/// Both platforms read the same table, so a format is bound to the same key
/// everywhere.
enum CoreRichEditorFormat {
  /// `**bold**` — Mod+B.
  bold(CoreRichEditorShortcut('B')),

  /// `*italic*` — Mod+I.
  italic(CoreRichEditorShortcut('I')),

  /// `~~strikethrough~~` — Mod+Shift+X.
  strikethrough(CoreRichEditorShortcut('X', shift: true)),

  /// `` `code` `` — Mod+E.
  code(CoreRichEditorShortcut('E')),

  /// `[text](url)` — Mod+K.
  link(CoreRichEditorShortcut('K')),

  /// `- item` — Mod+Shift+8.
  bulletedList(CoreRichEditorShortcut('8', shift: true)),

  /// `1. item` — Mod+Shift+7.
  numberedList(CoreRichEditorShortcut('7', shift: true)),

  /// `- [ ] item` — Mod+Shift+9.
  taskList(CoreRichEditorShortcut('9', shift: true)),

  /// `> quote` — Mod+Shift+. (period).
  quote(CoreRichEditorShortcut('.', shift: true)),

  /// `# Heading` — Mod+Alt+1.
  heading1(CoreRichEditorShortcut('1', alt: true)),

  /// `## Heading` — Mod+Alt+2.
  heading2(CoreRichEditorShortcut('2', alt: true)),

  /// `### Heading` — Mod+Alt+3.
  heading3(CoreRichEditorShortcut('3', alt: true)),

  /// `![alt](url)` — opens the file picker and uploads the chosen image.
  ///
  /// It has no shortcut, and no button unless the editor can take images —
  /// see [CoreRichEditorFormat.visibleToolbar].
  image(null),

  /// The block-type menu — not a format of its own but the toolbar entry
  /// that sets one: a button naming the caret's block
  /// ([CoreRichEditorBlockType]) with a chevron, which opens a menu of Text
  /// and the three headings. Each heading row is the same command as
  /// [heading1] … [heading3] (whose shortcuts stay); Text turns a heading
  /// back into a paragraph.
  blockType(null);

  const CoreRichEditorFormat(this.shortcut);

  /// The toolbar a `RichEditor` shows by default: the block-type menu, the
  /// inline formats, the lists, then the quote with the image button — a gap
  /// and a line between groups. The image button only appears when the
  /// editor was given an `onImageUpload` and the `onImageDelete` that goes
  /// with it; the quote group is the quote alone until then.
  ///
  /// The headings sit in the block-type menu rather than on buttons of their
  /// own. A toolbar that lists [heading1] … [heading3] still draws them as
  /// buttons.
  static const List<List<CoreRichEditorFormat>> defaultToolbar = [
    [blockType],
    [bold, italic, strikethrough, code, link],
    [bulletedList, numberedList, taskList],
    [quote, image],
  ];

  /// The toolbar that floats over a selection (`RichEditorSelectionToolbar`):
  /// [defaultToolbar] without the image button. An image is a new block
  /// rather than a change to the selected text, so it stays on the toolbar
  /// in the box.
  static const List<List<CoreRichEditorFormat>> selectionToolbar = [
    [blockType],
    [bold, italic, strikethrough, code, link],
    [bulletedList, numberedList, taskList],
    [quote],
  ];

  /// The order the toolbar over a selection folds its buttons into its
  /// "more" (⋯) menu when it is too narrow for them all — one step per unit,
  /// the first unit folding first: the quote, then the three lists as one,
  /// then the inline formats one by one from the link back to the bold. The
  /// block-type menu never folds. Each unit is part of a group of
  /// [selectionToolbar]; a group's gap and line go with its last unit.
  ///
  /// Both platforms fold by this list, so a narrow toolbar hides the same
  /// buttons everywhere; how many units fold is
  /// `CoreRichEditorContract.selectionToolbarFoldSteps`.
  static const List<List<CoreRichEditorFormat>> selectionToolbarFoldOrder = [
    [quote],
    [bulletedList, numberedList, taskList],
    [link],
    [code],
    [strikethrough],
    [italic],
    [bold],
  ];

  /// The formats the toolbar over a selection has folded into its "more" menu
  /// after [steps] steps of [selectionToolbarFoldOrder] — in the order they
  /// stand on the toolbar, so the menu reads as the toolbar did.
  static List<CoreRichEditorFormat> selectionToolbarFolded(int steps) {
    final folded = {
      for (final unit in selectionToolbarFoldOrder.take(steps)) ...unit,
    };

    return [
      for (final group in selectionToolbar)
        for (final format in group)
          if (folded.contains(format)) format,
    ];
  }

  /// The key that applies this format together with the platform modifier,
  /// or null for a format that has none ([image], [blockType]).
  final CoreRichEditorShortcut? shortcut;

  /// Whether this format marks a run of text (rather than a whole block).
  bool get isInline => index <= link.index;

  /// The level (1–3) of the heading this format makes, or null for every
  /// other format.
  int? get headingLevel => switch (this) {
    heading1 => 1,
    heading2 => 2,
    heading3 => 3,
    _ => null,
  };

  /// Whether this format only works in an editor that takes images — one
  /// given both an upload and a delete.
  bool get needsImageUpload => this == image;

  /// The buttons [toolbar] shows: a format the editor cannot offer has no
  /// button — [image] in an editor that takes no images ([images] false) —
  /// and a group left empty by that is dropped, so it leaves no gap.
  static List<List<CoreRichEditorFormat>> visibleToolbar(
    List<List<CoreRichEditorFormat>> toolbar, {
    required bool images,
  }) => [
    for (final group in toolbar)
      if (group.any((format) => images || !format.needsImageUpload))
        [
          for (final format in group)
            if (images || !format.needsImageUpload) format,
        ],
  ];

  /// Finds the format bound to [key] (one character, case-insensitive) with
  /// Shift and Alt held or not, or null when none is.
  ///
  /// The key is the *unshifted* character: on most layouts Shift+8 types
  /// `*`, and the caller hands over `8` (Flutter's logical key, the web's
  /// `KeyboardEvent.code`). With Alt held the character is not reliable
  /// either (Option+1 types `¡` on a Mac), so the caller hands over the
  /// physical key's label (`1`).
  static CoreRichEditorFormat? forKey(
    String key, {
    required bool shift,
    bool alt = false,
  }) {
    final upper = key.toUpperCase();
    for (final format in values) {
      final shortcut = format.shortcut;
      if (shortcut == null) continue;
      if (shortcut.key == upper &&
          shortcut.shift == shift &&
          shortcut.alt == alt) {
        return format;
      }
    }
    return null;
  }
}

/// A shortcut of a [CoreRichEditorFormat]: the platform modifier (⌘ on
/// Apple platforms, Ctrl elsewhere), optionally Shift and Alt (⌥ on Apple
/// platforms), and one [key].
@immutable
class CoreRichEditorShortcut {
  /// Creates a [CoreRichEditorShortcut].
  const CoreRichEditorShortcut(
    this.key, {
    this.shift = false,
    this.alt = false,
  });

  /// The key, as printed on the key cap (`B`, `8`, `.`).
  final String key;

  /// Whether Shift is held too.
  final bool shift;

  /// Whether Alt (Option on Apple platforms) is held too.
  final bool alt;

  /// The key caps a tooltip shows, in the order each platform writes them:
  /// `⌥ ⇧ ⌘ X` on Apple platforms, `Ctrl Alt Shift X` elsewhere.
  List<String> keyCaps({required bool apple}) => apple
      ? [if (alt) '⌥', if (shift) '⇧', '⌘', key]
      : ['Ctrl', if (alt) 'Alt', if (shift) 'Shift', key];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRichEditorShortcut &&
          other.key == key &&
          other.shift == shift &&
          other.alt == alt;

  @override
  int get hashCode => Object.hash(key, shift, alt);
}

/// What the block-type menu of a `RichEditor` toolbar
/// ([CoreRichEditorFormat.blockType]) offers: a paragraph and the three
/// headings, in the order the menu lists them.
///
/// The button names the caret's block by [of]. A block that is none of these
/// — a list item, a quote — reads as [paragraph]: the lists and the quote
/// have buttons of their own.
enum CoreRichEditorBlockType {
  /// A plain paragraph — "Text".
  paragraph(null, null),

  /// A level-1 heading.
  heading1(CoreRichEditorFormat.heading1, '#'),

  /// A level-2 heading.
  heading2(CoreRichEditorFormat.heading2, '##'),

  /// A level-3 heading.
  heading3(CoreRichEditorFormat.heading3, '###');

  const CoreRichEditorBlockType(this.format, this.markdownPrefix);

  /// The format that makes this block, or null for [paragraph] — what a
  /// heading turns back into.
  final CoreRichEditorFormat? format;

  /// The Markdown a line starts with to become this block — the hint each
  /// menu row shows at its end (`#` · `##` · `###`); null for [paragraph],
  /// which has none.
  final String? markdownPrefix;

  /// The format a pick of this row toggles when the caret's block is
  /// [current]: this heading, or — for [paragraph] — the heading the caret
  /// is in, toggled back off. Null when there is nothing to do: the row of
  /// the block the caret is already in.
  CoreRichEditorFormat? toggleFrom(CoreRichEditorBlockType current) =>
      this == current ? null : format ?? current.format;

  /// The block type of the caret's block, given the formats that are on
  /// there: the heading that is on, else [paragraph].
  static CoreRichEditorBlockType of(Set<CoreRichEditorFormat> active) {
    for (final type in values) {
      final format = type.format;
      if (format != null && active.contains(format)) return type;
    }
    return paragraph;
  }
}
