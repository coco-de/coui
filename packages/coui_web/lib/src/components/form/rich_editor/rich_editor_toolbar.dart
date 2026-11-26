import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/display/kbd/kbd.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/menu/dropdown_menu/dropdown_menu.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// The buttons of a `RichEditor` toolbar — the block-type button and its
/// menu, then groups of icon buttons, each with its tooltip and shortcut, a
/// gap and a line between groups — with no say in what a press does: the
/// editor answers [active] and [enabled], and is told about a press through
/// [onFormat].
///
/// Shared by the toolbar at the top of the editor's box and the one that
/// floats over a selection (`RichEditorSelectionToolbar`), so the two cannot
/// drift. Not exported.
///
/// ```text
/// root (<div>)                              // wraps between sections
///   └─ section (<div>) × groups
///        ├─ Gap · line (<div> Divider) · Gap   // every section but the first
///        └─ group (<div role="group">)
///             └─ DropdownMenu | Tooltip > Button
/// ```
///
/// The toolbar over a selection never wraps ([foldSteps] given): it is one
/// row of units, each marked `data-fold` for the editor to measure, and
/// folds the units it has no room for — the quote, then the lists, then the
/// inline formats from the link back
/// (`CoreRichEditorFormat.selectionToolbarFoldOrder`) — into a "more" (⋯)
/// menu of checkbox rows. A folded unit stays in the DOM out of the flow and
/// out of sight, so its width still reads. The block-type menu never folds.
///
/// ```text
/// root (<div data-fold=bar>)                // one row, never wraps
///   ├─ unit (<div data-fold=pinned>)         // the block-type menu
///   ├─ section (<div>)                       // the inline formats
///   │    ├─ Gap · line · Gap (data-fold=u6)  // goes with the bold
///   │    └─ group (<div role="group">)
///   │         └─ unit (<div data-fold=u<i>>) × 5   // bold … link
///   ├─ section (<div data-fold=u1>)          // the lists, with their line
///   ├─ section (<div data-fold=u0>)          // the quote, with its line
///   └─ section (<div data-fold=more>)        // line · the more button
/// ```
class RichEditorToolbarBar extends StatelessComponent {
  /// Creates a [RichEditorToolbarBar].
  const RichEditorToolbarBar({
    required this.groups,
    required this.resolved,
    required this.active,
    required this.enabled,
    required this.apple,
    required this.surfaceId,
    required this.onFormat,
    required this.blockTypeMenu,
    this.attributes,
    this.foldSteps,
    this.moreMenu,
    super.key,
  });

  /// The `data-fold` value of the bar's root on a toolbar that folds.
  static const String foldBarTag = 'bar';

  /// The `data-fold` value of what never folds.
  static const String foldPinnedTag = 'pinned';

  /// The `data-fold` value of the "more" button with its separator.
  static const String foldMoreTag = 'more';

  /// The `data-fold` value of the unit at [index] of the fold order.
  static String foldUnitTag(int index) => 'u$index';

  /// The groups to draw, already without the formats the editor cannot offer.
  final List<List<CoreRichEditorFormat>> groups;

  /// The editor's resolved chrome; only the toolbar slots are read.
  final ResolvedRichEditor resolved;

  /// The formats on at the caret — the held-down buttons.
  final Set<CoreRichEditorFormat> active;

  /// Whether the buttons work.
  final bool enabled;

  /// Whether the shortcuts read ⌘ rather than Ctrl.
  final bool apple;

  /// The id of the editing surface the buttons control.
  final String surfaceId;

  /// A button was pressed, or a row of the block-type menu picked — the
  /// format to toggle.
  final void Function(CoreRichEditorFormat format) onFormat;

  /// Opens and closes this bar's block-type menu.
  final PopoverController blockTypeMenu;

  /// Attributes of the bar's root — a role and a name, where the bar is the
  /// whole toolbar.
  final Map<String, String>? attributes;

  /// How many units of `CoreRichEditorFormat.selectionToolbarFoldOrder` are
  /// folded into the "more" menu — on the toolbar over a selection, which
  /// never wraps. Null draws the wrapping toolbar of the box.
  final int? foldSteps;

  /// Opens and closes the "more" menu of a toolbar that folds.
  final PopoverController? moreMenu;

  /// The localized name of [format].
  static String labelOf(CouiLocalizations l10n, CoreRichEditorFormat format) =>
      switch (format) {
        .bold => l10n.richEditorBold,
        .italic => l10n.richEditorItalic,
        .strikethrough => l10n.richEditorStrikethrough,
        .code => l10n.richEditorCode,
        .link => l10n.richEditorLink,
        .bulletedList => l10n.richEditorBulletedList,
        .numberedList => l10n.richEditorNumberedList,
        .taskList => l10n.richEditorTaskList,
        .quote => l10n.richEditorQuote,
        .heading1 => l10n.richEditorHeading1,
        .heading2 => l10n.richEditorHeading2,
        .heading3 => l10n.richEditorHeading3,
        .image => l10n.richEditorImage,
        // What the block-type button picks; its visible label is the
        // block.
        .blockType => l10n.richEditorBlockType,
      };

  static String _blockTypeLabelOf(
    CouiLocalizations l10n,
    CoreRichEditorBlockType type,
  ) => switch (type) {
    .paragraph => l10n.richEditorParagraph,
    .heading1 => l10n.richEditorHeading1,
    .heading2 => l10n.richEditorHeading2,
    .heading3 => l10n.richEditorHeading3,
  };

  static IconName _iconOf(CoreRichEditorFormat format) => switch (format) {
    .bold => LucideIcons.bold,
    .italic => LucideIcons.italic,
    .strikethrough => LucideIcons.strikethrough,
    .code => LucideIcons.code,
    .link => LucideIcons.link,
    .bulletedList => LucideIcons.list,
    .numberedList => LucideIcons.listOrdered,
    .taskList => LucideIcons.listTodo,
    .quote => LucideIcons.quote,
    .heading1 => LucideIcons.heading1,
    .heading2 => LucideIcons.heading2,
    .heading3 => LucideIcons.heading3,
    .image => LucideIcons.image,
    // The block-type button is drawn as its label and this chevron.
    .blockType => LucideIcons.chevronDown,
  };

  /// The shortcut as `aria-keyshortcuts` spells it (`Meta+Alt+Shift+X`).
  String _ariaShortcut(CoreRichEditorShortcut shortcut) => [
    if (apple) 'Meta' else 'Control',
    if (shortcut.alt) 'Alt',
    if (shortcut.shift) 'Shift',
    shortcut.key,
  ].join('+');

  Component _buildButton(CouiLocalizations l10n, CoreRichEditorFormat format) {
    final label = labelOf(l10n, format);
    final on = active.contains(format);
    final shortcut = format.shortcut;
    return Tooltip(
      message: label,
      tooltipStyle: resolved.tooltipStyle,
      tooltipChild: span(
        [
          Text(label),
          if (shortcut != null) ...[
            Gap(gapStyle: resolved.toolbarGapStyle),
            Kbd(
              keys: shortcut.keyCaps(apple: apple),
              kbdStyle: resolved.kbdStyle,
            ),
          ],
        ],
        classes: resolved.tooltipContent.className,
        styles: resolved.tooltipContent.inlineStyles,
      ),
      child: Button(
        variant: .plain,
        enabled: enabled,
        buttonStyle: on
            ? resolved.activeToolbarButtonStyle
            : resolved.toolbarButtonStyle,
        onPressed: () => onFormat(format),
        attributes: {
          'aria-label': label,
          // The image button opens a picker; it is not a held-down format.
          if (format != .image) 'aria-pressed': '$on',
          if (shortcut != null) 'aria-keyshortcuts': _ariaShortcut(shortcut),
          'aria-controls': surfaceId,
        },
        child: Icon(_iconOf(format), iconStyle: resolved.toolbarIconStyle),
      ),
    );
  }

  /// Picks [type] from the block-type menu: the heading it is, or — for
  /// Text — the heading the caret is in, toggled off. The row of the block
  /// the caret is already in changes nothing.
  void _handleBlockType(
    CoreRichEditorBlockType type,
    CoreRichEditorBlockType current,
  ) {
    blockTypeMenu.close();
    final format = type.toggleFrom(current);
    if (format != null) onFormat(format);
  }

  /// The block-type button — the caret's block and a chevron — and the
  /// `DropdownMenu` it opens: Text and the three headings as the choices of
  /// one group (radio rows drawn with a check), the current one checked,
  /// each heading ending in the Markdown that makes it. A disabled
  /// editor draws the button alone, so nothing opens.
  Component _buildBlockType(CouiLocalizations l10n) {
    final current = CoreRichEditorBlockType.of(active);
    final label = _blockTypeLabelOf(l10n, current);
    final button = Button(
      variant: .plain,
      size: .sm,
      enabled: enabled,
      buttonStyle: resolved.blockTypeButtonStyle,
      onPressed: () {},
      trailing: const Icon(LucideIcons.chevronDown),
      attributes: {
        // What the button picks and the block it shows; the visible label
        // alone would read as a button called "Text".
        'aria-label': CoreRichEditorContract.blockTypeButtonLabel(
          l10n.richEditorBlockType,
          label,
        ),
        'aria-controls': surfaceId,
      },
      child: Text(label),
    );
    if (!enabled) return button;
    return DropdownMenu(
      controller: blockTypeMenu,
      dropdownMenuStyle: resolved.blockTypeMenuStyle,
      trigger: button,
      items: [
        for (final type in CoreRichEditorBlockType.values)
          CoreMenuItem<Component>.radio(
            _blockTypeLabelOf(l10n, type),
            shortcut: type.markdownPrefix,
            selected: type == current,
            radioMark: CoreMenuRadioMark.check,
            onChanged: (_) => _handleBlockType(type, current),
          ),
      ],
    );
  }

  /// One group of buttons with the gap and the line that lead it (none for
  /// the first group). They are one section so that a narrow toolbar, which
  /// wraps between sections, never leaves a gap or a line on a row of its own.
  Component _buildSection(
    CouiLocalizations l10n,
    List<CoreRichEditorFormat> group, {
    required bool leads,
  }) {
    return div(
      [
        if (leads) ..._separator(),
        div(
          [
            for (final format in group)
              if (format == .blockType)
                _buildBlockType(l10n)
              else
                _buildButton(l10n, format),
          ],
          classes: resolved.toolbarGroup.className,
          styles: resolved.toolbarGroup.inlineStyles,
          attributes: const {'role': 'group'},
        ),
      ],
      classes: resolved.toolbarSection.className,
      styles: resolved.toolbarSection.inlineStyles,
    );
  }

  /// The gap and the line that lead every section but the first.
  List<Component> _separator() {
    final line = resolved.toolbarGroupDivider;
    return [
      Gap(gapStyle: resolved.toolbarGroupGapStyle),
      // The line sits between two gaps; with none, the groups are one gap
      // apart.
      if (line != null) ...[
        div(
          [
            Divider(
              orientation: .vertical,
              dividerStyle: resolved.toolbarGroupDividerStyle,
            ),
          ],
          classes: line.className,
          styles: line.inlineStyles,
        ),
        Gap(gapStyle: resolved.toolbarGroupGapStyle),
      ],
    ];
  }

  /// The "more" (⋯) button — one of the toolbar's own, named the localized
  /// "More" — and the `DropdownMenu` it opens: the folded formats as
  /// checkbox rows in toolbar order, a format on at the selection checked.
  /// Picking a row closes the menu and applies the format, as the button
  /// would have. With nothing folded the button is drawn alone, out of
  /// sight, so its width is known.
  Component _buildMore(
    CouiLocalizations l10n,
    List<CoreRichEditorFormat> folded,
  ) {
    final menu = moreMenu;
    final button = Tooltip(
      message: l10n.moreLabel,
      tooltipStyle: resolved.tooltipStyle,
      child: Button(
        variant: .plain,
        enabled: enabled && folded.isNotEmpty,
        buttonStyle: resolved.toolbarButtonStyle,
        onPressed: () {},
        attributes: {
          'aria-label': l10n.moreLabel,
          'aria-controls': surfaceId,
        },
        child: Icon(LucideIcons.ellipsis, iconStyle: resolved.toolbarIconStyle),
      ),
    );
    if (!enabled || folded.isEmpty || menu == null) return button;
    return DropdownMenu(
      controller: menu,
      dropdownMenuStyle: resolved.blockTypeMenuStyle,
      trigger: button,
      items: [
        for (final format in folded)
          CoreMenuItem<Component>.checkbox(
            labelOf(l10n, format),
            checked: active.contains(format),
            onChanged: (_) {
              menu.close();
              onFormat(format);
            },
          ),
      ],
    );
  }

  /// One unit of a toolbar that folds: [children] marked [tag], out of the
  /// flow and out of sight when [hidden], a button's spacing before it when
  /// [spaced].
  Component _unit(
    String tag,
    List<Component> children, {
    required bool hidden,
    bool spaced = false,
    Map<String, String>? attributes,
  }) {
    final base = spaced ? resolved.toolbarUnitSpacing : resolved.toolbarUnit;
    final hiddenChrome = resolved.toolbarUnitHidden;
    return div(
      children,
      classes: hidden
          ? '${base.className} ${hiddenChrome.className}'
          : base.className,
      styles: base.inlineStyles,
      attributes: {
        'data-fold': tag,
        if (hidden) 'aria-hidden': 'true',
        ...?attributes,
      },
    );
  }

  /// The one row of a toolbar that folds — see the class doc's second tree.
  Component _buildFolding(CouiLocalizations l10n, int steps) {
    const order = CoreRichEditorFormat.selectionToolbarFoldOrder;
    int? unitOf(CoreRichEditorFormat format) {
      for (var i = 0; i < order.length; i++) {
        if (order[i].contains(format)) return i;
      }
      return null;
    }

    bool folded(int? unit) => unit != null && unit < steps;
    final children = <Component>[];
    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];
      // The formats of the group by unit, in the order they stand.
      final units = <int?, List<CoreRichEditorFormat>>{};
      for (final format in group) {
        units.putIfAbsent(unitOf(format), () => []).add(format);
      }
      final allFolded = units.keys.every(folded);
      // One unit that is the whole group: the section is the unit, its
      // separator going with it.
      if (units.length == 1) {
        final unit = units.keys.single;
        final tag = unit == null
            ? RichEditorToolbarBar.foldPinnedTag
            : RichEditorToolbarBar.foldUnitTag(unit);
        children.add(
          _unit(tag, [
            if (g > 0) ..._separator(),
            div(
              [
                for (final format in group)
                  if (format == .blockType)
                    _buildBlockType(l10n)
                  else
                    _buildButton(l10n, format),
              ],
              classes: resolved.toolbarGroup.className,
              styles: resolved.toolbarGroup.inlineStyles,
              attributes: const {'role': 'group'},
            ),
          ], hidden: folded(unit)),
        );
        continue;
      }
      // Several units in one group: each button is a unit of its own, the
      // separator going with the group's last unit to fold.
      final last = units.keys.whereType<int>().fold<int?>(
        null,
        (highest, unit) => highest == null || unit > highest ? unit : highest,
      );
      final buttons = <Component>[];
      for (final MapEntry(key: unit, value: formats) in units.entries) {
        for (final format in formats) {
          buttons.add(
            _unit(
              unit == null
                  ? RichEditorToolbarBar.foldPinnedTag
                  : RichEditorToolbarBar.foldUnitTag(unit),
              [
                if (format == .blockType)
                  _buildBlockType(l10n)
                else
                  _buildButton(l10n, format),
              ],
              hidden: folded(unit),
              // A button's spacing before every button but the group's first.
              spaced: buttons.isNotEmpty,
            ),
          );
        }
      }
      children.add(
        div(
          [
            if (g > 0)
              _unit(
                last == null
                    ? RichEditorToolbarBar.foldPinnedTag
                    : RichEditorToolbarBar.foldUnitTag(last),
                _separator(),
                hidden: allFolded,
              ),
            div(
              buttons,
              classes: resolved.toolbarGroup.className,
              // No gap of its own: a unit's spacing goes with the unit.
              attributes: const {'role': 'group'},
            ),
          ],
          classes: resolved.toolbarSection.className,
          styles: resolved.toolbarSection.inlineStyles,
        ),
      );
    }
    children.add(
      _unit(RichEditorToolbarBar.foldMoreTag, [
        ..._separator(),
        _buildMore(l10n, CoreRichEditorFormat.selectionToolbarFolded(steps)),
      ], hidden: steps == 0),
    );
    return div(
      children,
      classes: resolved.toolbarRow.className,
      styles: resolved.toolbarRow.inlineStyles,
      attributes: {
        'data-fold': RichEditorToolbarBar.foldBarTag,
        ...?attributes,
      },
    );
  }

  @override
  Component build(BuildContext context) {
    final l10n = CouiLocalizations.of(context);
    final steps = foldSteps;
    if (steps != null) return _buildFolding(l10n, steps);
    return div(
      [
        for (var i = 0; i < groups.length; i++)
          _buildSection(l10n, groups[i], leads: i > 0),
      ],
      classes: resolved.toolbarButtons.className,
      styles: resolved.toolbarButtons.inlineStyles,
      attributes: attributes,
    );
  }
}
