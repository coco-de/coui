import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/rich_editor/rich_editor_toolbar_fold.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

/// The formatting buttons of a [RichEditor], on their own — for a bar of the
/// app's own, above or beside an editor, over a view that is not an editor,
/// or one bar for several editors.
///
/// It is the toolbar [RichEditor] draws at the top of its box
/// (`showToolbar`), drawn by the same code: the block-type button — the
/// caret's block (Text, Heading 1 … 3) and a chevron, opening a menu of the
/// four — then groups of 32-square icon buttons, each with a `Tooltip` naming
/// it and its shortcut in `Kbd` key caps, and the button of a format that is
/// on at the caret kept filled. A press formats the
/// selection of [controller]; the toolbar listens to it, so the buttons
/// follow the caret. The bar wraps between groups when it is narrow, never
/// inside one.
///
/// A press acts on the [controller] alone — enough for the formats that mark
/// text and the ones that turn a block into another. Three things belong to
/// the editor on screen, so hand over its key as [editorKey]:
///
/// - **focus** goes back into the editor after a press;
/// - **the link button** opens the editor's link dialog (or its
///   `onLinkRequest`) — without an editor, or an [onFormat], it stays off;
/// - **the image button** shows while the editor can store a file
///   (`onImageUpload` with its `onImageDelete`).
///
/// The toolbar draws no container of its own. Wrap it in the bar the design
/// asks for, and put what else the bar holds beside it:
///
/// ```dart
/// final controller = RichEditorController(markdown: '# Terms');
/// final editorKey = GlobalKey<RichEditorState>();
///
/// Column(
///   crossAxisAlignment: .stretch,
///   children: [
///     ColoredBox(
///       color: Theme.of(context).colorScheme.surfaceContainerLow.toValue(),
///       child: Padding(
///         padding: const .symmetric(vertical: 8, horizontal: 12),
///         child: Column(
///           crossAxisAlignment: .start,
///           spacing: 4,
///           children: [
///             RichEditorToolbar(controller: controller, editorKey: editorKey),
///             Checkbox(
///               label: 'Show changes',
///               checked: true,
///               onChanged: print,
///             ),
///           ],
///         ),
///       ),
///     ),
///     RichEditor(
///       key: editorKey,
///       controller: controller,
///       showToolbar: false,
///     ),
///   ],
/// )
/// ```
///
/// One toolbar can serve several editors: hand it the controller and key of
/// the one that was focused last.
///
/// Flutter only — the web editor keeps its document in the DOM and has no
/// controller to bind a toolbar to.
///
/// surface:content — a row of buttons in the flow; the tooltips mount over
/// content.
class RichEditorToolbar extends StatefulWidget {
  /// Creates a [RichEditorToolbar].
  const RichEditorToolbar({
    required this.controller,
    this.editorKey,
    this.toolbar = CoreRichEditorFormat.defaultToolbar,
    this.enabled = true,
    this.onFormat,
    this.trailing,
    this.richEditorStyle,
    super.key,
  });

  /// The controller the buttons format the selection of, and whose caret
  /// decides which of them are on.
  final RichEditorController controller;

  /// The editor [controller] belongs to, when it is on screen: it takes the
  /// focus back after a press, opens the link dialog and picks the image.
  /// Read when the toolbar builds and when a button is pressed, so the editor
  /// may mount after the toolbar.
  final GlobalKey<RichEditorState>? editorKey;

  /// The buttons, in groups — a gap leads every group but the first. The
  /// image button is left out while the editor cannot take images.
  final List<List<CoreRichEditorFormat>> toolbar;

  /// Whether the buttons work. A [controller] that is read-only switches them
  /// off too.
  final bool enabled;

  /// Called first on every press; return true to take the press over and skip
  /// what the toolbar would do — for a screen that shows something other than
  /// the editor and would rather switch to it than format.
  ///
  /// A row of the block-type menu reports the heading it toggles: the
  /// heading picked, or — for Text — the heading the caret is in.
  ///
  /// With it, the link button stays on without an [editorKey]: the press is
  /// the caller's.
  final bool Function(CoreRichEditorFormat format)? onFormat;

  /// What sits at the right end of the toolbar — an app's own control for the
  /// editor, such as a "Show changes" checkbox. When there is no room for it
  /// beside the buttons it wraps onto a row of its own below them, at the
  /// start, `toolbarRowSpacing` under the buttons.
  final Widget? trailing;

  /// Chrome of the buttons — the `toolbar*` and `blockType*` slots of
  /// [CoreRichEditorStyle] (button, active button, icon, spacing, group gap,
  /// row spacing, block-type button and menu, tooltip, key caps). The strip,
  /// the lines and the rest of the style belong to the editor's own toolbar.
  final CoreRichEditorStyle? richEditorStyle;

  @override
  State<RichEditorToolbar> createState() => _RichEditorToolbarState();
}

class _RichEditorToolbarState extends State<RichEditorToolbar> {
  @override
  void initState() {
    super.initState();
    _rebuildOnceEditorMounts();
  }

  @override
  void didUpdateWidget(RichEditorToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editorKey != widget.editorKey) _rebuildOnceEditorMounts();
  }

  /// The editor is read through its key, and a sibling that builds after the
  /// toolbar is not there yet: look again once the frame is out, so the image
  /// button and the link button are not stuck off.
  void _rebuildOnceEditorMounts() {
    final key = widget.editorKey;
    if (key == null || key.currentState != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && key.currentState != null) setState(() {});
    });
  }

  bool _canApply(CoreRichEditorFormat format, RichEditorState? editor) {
    final controller = widget.controller;
    if (!widget.enabled || controller.readOnly) return false;
    if (format == CoreRichEditorFormat.image) {
      return editor?.canInsertImage ?? false;
    }
    // A link is asked for in the editor's dialog, or by the caller.
    if (format == CoreRichEditorFormat.link &&
        editor == null &&
        widget.onFormat == null) {
      return false;
    }
    return richEditorFormatCanApply(controller, format);
  }

  void _apply(CoreRichEditorFormat format, RichEditorState? editor) {
    if (widget.onFormat?.call(format) ?? false) return;
    final controller = widget.controller;
    // A press before the editor was ever focused acts at the end of the
    // text, where focusing puts the caret.
    if (controller.selection == null) {
      if (editor != null) {
        editor.focus();
      } else {
        controller.moveCaretToEnd();
      }
    }
    if (!_canApply(format, editor)) return;
    switch (format) {
      case CoreRichEditorFormat.link:
        unawaited(editor?.editLink());
        return;
      case CoreRichEditorFormat.image:
        unawaited(editor?.insertImage());
        return;
      case _:
        richEditorFormatToggle(controller, format);
    }
    editor?.focus();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveRichEditor(
      context,
      richEditorStyle: widget.richEditorStyle,
    );
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final editor = widget.editorKey?.currentState;
        return RichEditorToolbarBar(
          groups: CoreRichEditorFormat.visibleToolbar(
            widget.toolbar,
            images: editor?.canInsertImage ?? false,
          ),
          resolved: resolved,
          apple: richEditorIsApple,
          keyPrefix: 'richEditorToolbar',
          trailing: widget.trailing,
          isOn: (format) => richEditorFormatIsOn(widget.controller, format),
          canApply: (format) => _canApply(format, editor),
          onApply: (format) => _apply(format, editor),
        );
      },
    );
  }
}

/// The buttons of a [RichEditor] toolbar — groups of icon buttons, each with
/// its tooltip and shortcut — with no say in what a press does: the caller
/// answers [isOn], [canApply] and [onApply].
///
/// Shared by the editor's own toolbar, [RichEditorToolbar] and the toolbar
/// over a selection, so they cannot drift. The bar in the box wraps between
/// its groups when it is narrow; the one over a selection ([foldable]) never
/// wraps — it folds buttons into a "more" (⋯) menu instead, in the order
/// `CoreRichEditorFormat.selectionToolbarFoldOrder`, the block-type menu
/// staying. Not exported.
class RichEditorToolbarBar extends StatefulWidget {
  /// Creates a [RichEditorToolbarBar].
  const RichEditorToolbarBar({
    required this.groups,
    required this.resolved,
    required this.apple,
    required this.isOn,
    required this.canApply,
    required this.onApply,
    this.keyPrefix = 'richEditor',
    this.trailing,
    this.groupDividers = false,
    this.foldable = false,
    this.availableWidth,
    this.label,
    this.onMenuOpenChanged,
    super.key,
  });

  /// The `ValueKey` suffix of the "more" button (`<prefix>.more`).
  static const String moreKeySuffix = 'more';

  /// The groups to draw, already without the formats the editor cannot offer.
  final List<List<CoreRichEditorFormat>> groups;

  /// The editor's resolved chrome; only the toolbar slots are read.
  final ResolvedRichEditor resolved;

  /// Whether the shortcuts read ⌘ rather than Ctrl.
  final bool apple;

  /// Whether the format is on at the caret.
  final bool Function(CoreRichEditorFormat format) isOn;

  /// Whether the format can be applied now.
  final bool Function(CoreRichEditorFormat format) canApply;

  /// A button was pressed.
  final ValueChanged<CoreRichEditorFormat> onApply;

  /// Prefix of each button's `ValueKey` (`<prefix>.<format name>`).
  final String keyPrefix;

  /// What sits at the right end of the bar; it wraps below the buttons when
  /// there is no room beside them.
  final Widget? trailing;

  /// Whether a vertical line separates the groups — the editor's own
  /// toolbar draws them; a [RichEditorToolbar] leaves the look to the app.
  final bool groupDividers;

  /// Whether the bar stays on one row and folds buttons it has no room for
  /// into a "more" menu, rather than wrapping between groups. [trailing] has
  /// no place on a foldable bar.
  final bool foldable;

  /// The room a [foldable] bar folds to, when the panel around it takes its
  /// width from the bar and so cannot tell it — see
  /// `RichEditorToolbarFoldRow.availableWidth`. Null folds to the width
  /// the bar is given.
  final double? availableWidth;

  /// The bar's accessible name; null reads the localized "Formatting". The
  /// toolbar over a selection names itself apart from the one in the box.
  final String? label;

  /// Told when a menu of the bar — the block-type menu, the "more" menu —
  /// opens and closes. A menu takes the focus while it is open, and a host
  /// that follows the focus has to know it went to its own menu.
  final ValueChanged<bool>? onMenuOpenChanged;

  @override
  State<RichEditorToolbarBar> createState() => _RichEditorToolbarBarState();
}

class _RichEditorToolbarBarState extends State<RichEditorToolbarBar> {
  /// How many units of the fold order the row folded last — told by the
  /// row after its layout; the "more" menu lists them and the folded
  /// buttons leave the focus order.
  int _foldSteps = 0;

  void _handleFoldSteps(int steps) {
    if (!mounted || steps == _foldSteps) return;
    setState(() => _foldSteps = steps);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final groups = widget.groups;
    final resolved = widget.resolved;
    final buttons = CoUISemantics(
      role: .group,
      label: widget.label ?? localizations.richEditorToolbar,
      container: true,
      child: widget.foldable
          ? _foldingRow(localizations)
          // Each group is a row of its own, so a narrow bar wraps between
          // groups, never inside one; the separator leads every group but
          // the first.
          : Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (i, group) in groups.indexed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i > 0) _groupSeparator(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: resolved.toolbarItemSpacing,
                        children: [
                          for (final format in group)
                            if (format == CoreRichEditorFormat.blockType)
                              _blockType()
                            else
                              _button(format, localizations),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
    );
    final end = widget.trailing;
    if (end == null || widget.foldable) return buttons;
    // One row while the trailing widget fits beside the buttons, pushed to
    // the right end; otherwise it wraps below them, alone on its row, at the
    // start (a lone child of a space-between run sits at the start).
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: resolved.toolbarRowSpacing,
      children: [buttons, end],
    );
  }

  /// The one row of a foldable bar: the block-type menu pinned at the
  /// start, then each unit of the fold order where it stands on the
  /// toolbar — a group's first unit led by the group separator, the others
  /// by the button spacing — and the "more" button after its own separator,
  /// shown by the row once anything has folded. A format that is in no unit
  /// of the fold order is pinned with its group.
  Widget _foldingRow(CoUILocalizations localizations) {
    final resolved = widget.resolved;
    const order = CoreRichEditorFormat.selectionToolbarFoldOrder;
    int? unitOf(CoreRichEditorFormat format) {
      for (final (i, unit) in order.indexed) {
        if (unit.contains(format)) return i;
      }

      return null;
    }

    final children = <Widget>[];
    for (final (g, group) in widget.groups.indexed) {
      // The formats of the group by unit, in the order they stand.
      final units = <int?, List<CoreRichEditorFormat>>{};
      for (final format in group) {
        units.putIfAbsent(unitOf(format), () => []).add(format);
      }
      var leadsGroup = g > 0;
      for (final MapEntry(key: index, value: formats) in units.entries) {
        final leading = leadsGroup
            ? _groupSeparator()
            : SizedBox(width: resolved.toolbarItemSpacing);
        leadsGroup = false;
        final row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (g > 0 || index != units.keys.first) leading,
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: resolved.toolbarItemSpacing,
              children: [
                for (final format in formats)
                  if (format == CoreRichEditorFormat.blockType)
                    _blockType()
                  else
                    _button(format, localizations),
              ],
            ),
          ],
        );
        children.add(
          RichEditorToolbarFoldSlot(
            foldIndex: index,
            // A folded button is laid out, so its width is known when room
            // comes back, but it is neither painted nor reachable: the Tab
            // key walks past it.
            child: index != null && index < _foldSteps
                ? ExcludeFocus(child: row)
                : row,
          ),
        );
      }
    }
    children.add(
      RichEditorToolbarFoldSlot(
        more: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _groupSeparator(),
            RichEditorMoreMenu(
              key: ValueKey<String>(
                '${widget.keyPrefix}.${RichEditorToolbarBar.moreKeySuffix}',
              ),
              formats: CoreRichEditorFormat.selectionToolbarFolded(_foldSteps),
              apple: widget.apple,
              isOn: widget.isOn,
              canApply: widget.canApply,
              onApply: widget.onApply,
              onOpenChanged: widget.onMenuOpenChanged,
              resolved: resolved,
            ),
          ],
        ),
      ),
    );

    return RichEditorToolbarFoldRow(
      availableWidth: widget.availableWidth,
      onFoldStepsChanged: _handleFoldSteps,
      children: children,
    );
  }

  /// What leads every group but the first: a gap, and — when the lines are
  /// drawn and have a length — the line between the two groups and a second
  /// gap. The separator is not a uniform spacer between equal siblings, so it
  /// is not a `spacing:` of the row.
  Widget _groupSeparator() {
    final resolved = widget.resolved;
    final dividerHeight = resolved.toolbarGroupDividerHeight;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gap(gapStyle: resolved.toolbarGroupGapStyle),
        if (widget.groupDividers && dividerHeight > 0) ...[
          SizedBox(
            height: dividerHeight,
            child: Divider(
              orientation: CoreDividerOrientation.vertical,
              dividerStyle: resolved.toolbarGroupDividerStyle,
            ),
          ),
          Gap(gapStyle: resolved.toolbarGroupGapStyle),
        ],
      ],
    );
  }

  /// The block-type button and its menu: what the caret's block is, read
  /// from the headings that are on there.
  Widget _blockType() {
    final isOn = widget.isOn;
    final canApply = widget.canApply;
    final current = CoreRichEditorBlockType.of({
      for (final type in CoreRichEditorBlockType.values)
        if (type.format case final format? when isOn(format)) format,
    });
    return RichEditorBlockTypeMenu(
      key: ValueKey<String>(
        '${widget.keyPrefix}.${CoreRichEditorFormat.blockType.name}',
      ),
      current: current,
      enabled: canApply(CoreRichEditorFormat.blockType),
      canSelect: (type) =>
          canApply(type.format ?? current.format ?? .blockType),
      onSelect: (type) {
        // Text turns the heading the caret is in back into a paragraph.
        final format = type.toggleFrom(current);
        if (format != null) widget.onApply(format);
      },
      onOpenChanged: widget.onMenuOpenChanged,
      resolved: widget.resolved,
    );
  }

  Widget _button(
    CoreRichEditorFormat format,
    CoUILocalizations localizations,
  ) {
    final resolved = widget.resolved;
    final label = richEditorFormatLabel(format, localizations);
    final enabled = widget.canApply(format);
    final on = widget.isOn(format);
    final shortcut = format.shortcut;
    return Tooltip(
      tooltipStyle: resolved.tooltipStyle,
      tooltipChild: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label)),
          if (enabled && shortcut != null) ...[
            const Gap.space8(),
            Kbd(
              keys: shortcut.keyCaps(apple: widget.apple),
              kbdStyle: resolved.kbdStyle,
            ),
          ],
        ],
      ),
      child: CoUISemantics(
        label: label,
        toggled: on,
        child: Button(
          key: ValueKey<String>('${widget.keyPrefix}.${format.name}'),
          variant: CoreButtonVariant.plain,
          enabled: enabled,
          buttonStyle: on
              ? resolved.activeToolbarButtonStyle
              : resolved.toolbarButtonStyle,
          onPressed: () => widget.onApply(format),
          child: Icon(
            richEditorFormatIcon(format),
            iconStyle: resolved.toolbarIconStyle,
          ),
        ),
      ),
    );
  }
}

/// The "more" (⋯) button of a foldable [RichEditorToolbarBar] — the same
/// plain 32-square button as the format buttons, named the localized "More"
/// — and the `DropdownMenu` it opens: the folded [formats] as checkbox rows,
/// in the order they stood on the toolbar, a format that is on at the
/// selection checked. Picking a row closes the menu and applies the format,
/// as the button would have. With nothing folded the button is drawn alone
/// (the row keeps it out of sight) so its width is known.
///
/// Not exported.
class RichEditorMoreMenu extends StatefulWidget {
  /// Creates a [RichEditorMoreMenu].
  const RichEditorMoreMenu({
    required this.formats,
    required this.apple,
    required this.isOn,
    required this.canApply,
    required this.onApply,
    required this.resolved,
    this.onOpenChanged,
    super.key,
  });

  /// The folded formats, in toolbar order — the menu's rows.
  final List<CoreRichEditorFormat> formats;

  /// Whether the shortcuts read ⌘ rather than Ctrl.
  final bool apple;

  /// Whether the format is on at the selection — its row is checked.
  final bool Function(CoreRichEditorFormat format) isOn;

  /// Whether the format can be applied now — its row is enabled.
  final bool Function(CoreRichEditorFormat format) canApply;

  /// A row was picked.
  final ValueChanged<CoreRichEditorFormat> onApply;

  /// The editor's resolved chrome; the toolbar button and menu slots are
  /// read.
  final ResolvedRichEditor resolved;

  /// Told when the menu opens and closes.
  final ValueChanged<bool>? onOpenChanged;

  @override
  State<RichEditorMoreMenu> createState() => _RichEditorMoreMenuState();
}

class _RichEditorMoreMenuState extends State<RichEditorMoreMenu> {
  final _menu = PopoverController();
  bool _pointerPress = false;

  @override
  void initState() {
    super.initState();
    _menu.addListener(_handleMenuChanged);
  }

  @override
  void dispose() {
    _menu
      ..removeListener(_handleMenuChanged)
      ..dispose();
    super.dispose();
  }

  void _handleMenuChanged() => widget.onOpenChanged?.call(_menu.isOpen);

  void _handlePressed() {
    if (_pointerPress) {
      _pointerPress = false;
      return;
    }
    _menu.show();
  }

  void _handlePick(CoreRichEditorFormat format) {
    _menu.close();
    widget.onApply(format);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final resolved = widget.resolved;
    final enabled = widget.formats.any(widget.canApply);
    final button = Tooltip(
      tooltipStyle: resolved.tooltipStyle,
      tooltipChild: Text(localizations.moreLabel),
      child: CoUISemantics(
        label: localizations.moreLabel,
        child: Button(
          variant: CoreButtonVariant.plain,
          enabled: enabled,
          buttonStyle: resolved.toolbarButtonStyle,
          onTapDown: (_) => _pointerPress = true,
          onTapCancel: () => _pointerPress = false,
          onPressed: _handlePressed,
          child: Icon(
            LucideIcons.ellipsis,
            iconStyle: resolved.toolbarIconStyle,
          ),
        ),
      ),
    );
    if (!enabled) return button;
    return DropdownMenu(
      controller: _menu,
      dropdownMenuStyle: resolved.blockTypeMenuStyle,
      trigger: button,
      items: [
        for (final format in widget.formats)
          CoreMenuItem<Widget>.checkbox(
            richEditorFormatLabel(format, localizations),
            checked: widget.isOn(format),
            disabled: !widget.canApply(format),
            onChanged: (_) => _handlePick(format),
          ),
      ],
    );
  }
}

/// The block-type button of a [RichEditor] toolbar — a plain `Button` naming
/// the caret's block with a chevron after it — and the `DropdownMenu` it
/// opens: Text and the three headings as the choices of one group (radio
/// rows drawn with a check), the [current] one checked, each heading ending
/// in the Markdown that makes it (`#` · `##` · `###`). The button is named
/// for what it picks and the block it shows ("Block type: Text"); it has no
/// tooltip, since its label already is the block's name.
///
/// A pointer press opens the menu through the `DropdownMenu`'s own trigger;
/// Enter or Space on the focused button opens it through [PopoverController],
/// so the keyboard reaches the menu too — the rows then move with the arrow
/// keys, as in any `Menu`. Picking a row closes the menu and reports it to
/// [onSelect], unless it is the [current] one. A disabled button opens
/// nothing.
///
/// Not exported.
class RichEditorBlockTypeMenu extends StatefulWidget {
  /// Creates a [RichEditorBlockTypeMenu].
  const RichEditorBlockTypeMenu({
    required this.current,
    required this.enabled,
    required this.canSelect,
    required this.onSelect,
    required this.resolved,
    this.onOpenChanged,
    super.key,
  });

  /// The caret's block — the button's label and the checked row.
  final CoreRichEditorBlockType current;

  /// Whether the button works.
  final bool enabled;

  /// Whether a row can be picked now.
  final bool Function(CoreRichEditorBlockType type) canSelect;

  /// A row other than [current] was picked.
  final ValueChanged<CoreRichEditorBlockType> onSelect;

  /// The editor's resolved chrome; the block-type slots are read.
  final ResolvedRichEditor resolved;

  /// Told when the menu opens and closes.
  final ValueChanged<bool>? onOpenChanged;

  @override
  State<RichEditorBlockTypeMenu> createState() =>
      _RichEditorBlockTypeMenuState();
}

class _RichEditorBlockTypeMenuState extends State<RichEditorBlockTypeMenu> {
  final _menu = PopoverController();

  /// Whether the press under way came from a pointer — the `DropdownMenu`'s
  /// trigger opens the menu for those; a press without one is the keyboard's.
  bool _pointerPress = false;

  @override
  void initState() {
    super.initState();
    _menu.addListener(_handleMenuChanged);
  }

  @override
  void dispose() {
    _menu
      ..removeListener(_handleMenuChanged)
      ..dispose();
    super.dispose();
  }

  void _handleMenuChanged() => widget.onOpenChanged?.call(_menu.isOpen);

  void _handlePressed() {
    if (_pointerPress) {
      _pointerPress = false;
      return;
    }
    _menu.show();
  }

  void _handleSelect(CoreRichEditorBlockType type) {
    _menu.close();
    if (type != widget.current) widget.onSelect(type);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final resolved = widget.resolved;
    final current = richEditorBlockTypeLabel(widget.current, localizations);
    final button = CoUISemantics(
      label: CoreRichEditorContract.blockTypeButtonLabel(
        localizations.richEditorBlockType,
        current,
      ),
      child: Button(
        variant: CoreButtonVariant.plain,
        size: CoreComponentSize.sm,
        enabled: widget.enabled,
        buttonStyle: resolved.blockTypeButtonStyle,
        onTapDown: (_) => _pointerPress = true,
        onTapCancel: () => _pointerPress = false,
        onPressed: _handlePressed,
        trailing: const Icon(LucideIcons.chevronDown),
        // The name above already says the block; read once.
        child: ExcludeSemantics(child: Text(current)),
      ),
    );
    if (!widget.enabled) return button;
    return DropdownMenu(
      controller: _menu,
      dropdownMenuStyle: resolved.blockTypeMenuStyle,
      trigger: button,
      items: [
        for (final type in CoreRichEditorBlockType.values)
          CoreMenuItem<Widget>.radio(
            richEditorBlockTypeLabel(type, localizations),
            shortcut: type.markdownPrefix,
            selected: type == widget.current,
            radioMark: CoreMenuRadioMark.check,
            disabled: !widget.canSelect(type),
            onChanged: (_) => _handleSelect(type),
          ),
      ],
    );
  }
}

/// The localized name of [type] — the block-type button's label and its
/// menu row.
String richEditorBlockTypeLabel(
  CoreRichEditorBlockType type,
  CoUILocalizations localizations,
) => switch (type) {
  CoreRichEditorBlockType.paragraph => localizations.richEditorParagraph,
  CoreRichEditorBlockType.heading1 => localizations.richEditorHeading1,
  CoreRichEditorBlockType.heading2 => localizations.richEditorHeading2,
  CoreRichEditorBlockType.heading3 => localizations.richEditorHeading3,
};

/// Whether shortcuts read ⌘ (Apple platforms) rather than Ctrl.
bool get richEditorIsApple =>
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// The character format [format] marks a run of text with, or null for a
/// block format, the link and the image.
InlineFormat? richEditorInlineOf(CoreRichEditorFormat format) =>
    switch (format) {
      CoreRichEditorFormat.bold => InlineFormat.bold,
      CoreRichEditorFormat.italic => InlineFormat.italic,
      CoreRichEditorFormat.strikethrough => InlineFormat.strikethrough,
      CoreRichEditorFormat.code => InlineFormat.code,
      _ => null,
    };

/// The block format [format] turns the caret's block into, or null for an
/// inline format, the link and the image.
BlockFormat? richEditorBlockOf(CoreRichEditorFormat format) => switch (format) {
  CoreRichEditorFormat.heading1 => BlockFormat.heading1,
  CoreRichEditorFormat.heading2 => BlockFormat.heading2,
  CoreRichEditorFormat.heading3 => BlockFormat.heading3,
  CoreRichEditorFormat.bulletedList => BlockFormat.bulletList,
  CoreRichEditorFormat.numberedList => BlockFormat.numberedList,
  CoreRichEditorFormat.taskList => BlockFormat.taskList,
  CoreRichEditorFormat.quote => BlockFormat.quote,
  _ => null,
};

/// Whether [format] is on at the caret of [controller] — its button is held
/// down.
bool richEditorFormatIsOn(
  RichEditorController controller,
  CoreRichEditorFormat format,
) {
  if (format == CoreRichEditorFormat.link) return controller.link != null;
  final inline = richEditorInlineOf(format);
  if (inline != null) return controller.isActive(inline);
  final block = richEditorBlockOf(format);
  // The image button adds something; it is never held down.
  return block != null && controller.blockFormat == block;
}

/// Whether the caret of [controller] lets [format] be applied. With no
/// selection yet a press places the caret first, so it can.
bool richEditorFormatCanApply(
  RichEditorController controller,
  CoreRichEditorFormat format,
) {
  if (controller.selection == null) return true;
  if (format.isInline) return controller.canFormatInline;
  final block = richEditorBlockOf(format);
  // The image asks nothing of the caret.
  return block == null || controller.canFormatBlock(block);
}

/// Toggles [format] on [controller] — the character and block formats; the
/// link and the image need the editor.
void richEditorFormatToggle(
  RichEditorController controller,
  CoreRichEditorFormat format,
) {
  final inline = richEditorInlineOf(format);
  if (inline != null) {
    controller.toggleInline(inline);
    return;
  }
  final block = richEditorBlockOf(format);
  if (block != null) controller.toggleBlock(block);
}
