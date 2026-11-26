import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedRichEditor
// ═══════════════════════════════════════════════════

/// Resolver output for `RichEditor`.
///
/// ```text
/// design system default (CoreRichEditorStyle.defaultX static const)
///   → theme.coreComponentTheme.richEditor.style
///   → widget.richEditorStyle
/// ```
///
/// The child components' slots ([textAreaStyle], [toolbarButtonStyle],
/// [uploadAlertStyle] …) are chained and handed on unresolved — `TextArea`'s
/// resolver, `Button`, `Icon`, `Gap`, `Tooltip`, `Kbd` and `Alert` resolve
/// them. The document's own marks are paint-ready.
class ResolvedRichEditor {
  /// Creates a [ResolvedRichEditor].
  const ResolvedRichEditor({
    required this.textAreaStyle,
    required this.minHeight,
    required this.maxHeight,
    required this.toolbarButtonStyle,
    required this.activeToolbarButtonStyle,
    required this.toolbarIconStyle,
    required this.toolbarItemSpacing,
    required this.toolbarGroupGapStyle,
    required this.toolbarGapStyle,
    required this.toolbarBackgroundColor,
    required this.toolbarPadding,
    required this.toolbarDividerStyle,
    required this.toolbarGroupDividerStyle,
    required this.toolbarGroupDividerHeight,
    required this.toolbarRowSpacing,
    required this.blockTypeButtonStyle,
    required this.blockTypeMenuStyle,
    required this.selectionToolbarPanelStyle,
    required this.selectionToolbarOffset,
    required this.tooltipStyle,
    required this.kbdStyle,
    required this.blockSpacing,
    required this.listIndent,
    required this.linkColor,
    required this.codeTextStyle,
    required this.codeBackgroundColor,
    required this.codePadding,
    required this.quoteBarColor,
    required this.quoteBarWidth,
    required this.quoteSpacing,
    required this.quoteTextColor,
    required this.ruleColor,
    required this.completedTaskColor,
    required this.heading1TextStyle,
    required this.heading2TextStyle,
    required this.heading3TextStyle,
    required this.imageBorderRadius,
    required this.imageMaxHeight,
    required this.imageBackgroundColor,
    required this.uploadAlertStyle,
  });

  /// The box, for `resolveTextArea`.
  final CoreTextAreaStyle textAreaStyle;

  /// Height of the editing area when it holds little text (scaled).
  final double minHeight;

  /// Height the editing area grows to before it scrolls (scaled).
  final double maxHeight;

  /// Each toolbar button.
  final CoreButtonStyle toolbarButtonStyle;

  /// A toolbar button whose format is on — [toolbarButtonStyle] with the
  /// active chrome merged over it.
  final CoreButtonStyle activeToolbarButtonStyle;

  /// Each toolbar icon.
  final CoreIconStyle toolbarIconStyle;

  /// Space between the buttons of one group (scaled).
  final double toolbarItemSpacing;

  /// Gap between toolbar groups.
  final CoreGapStyle toolbarGroupGapStyle;

  /// Gap between the box and the rows above it (the upload rows).
  final CoreGapStyle toolbarGapStyle;

  /// Fill of the toolbar strip at the top of the box; transparent while the
  /// editor is disabled, so the box's disabled fill shows through.
  final Color toolbarBackgroundColor;

  /// Inset of the toolbar's buttons inside its strip (scaled) — directional
  /// by default, so the wider start side follows the reading direction.
  final EdgeInsetsGeometry toolbarPadding;

  /// The line under the strip, handed on unresolved to its `Divider`. The
  /// colour is stated: the style's own, else `outline-variant`
  /// (`disabled-outline` while the editor is disabled).
  final CoreDividerStyle toolbarDividerStyle;

  /// The same slot for the vertical lines between groups: the style's own
  /// colour, else the `Divider`'s — in every state. Only the line under the
  /// strip follows the editor into `disabled-outline`.
  final CoreDividerStyle toolbarGroupDividerStyle;

  /// Length of the line between two toolbar groups (scaled); 0 draws none.
  final double toolbarGroupDividerHeight;

  /// Space between the rows of a toolbar that wraps (scaled).
  final double toolbarRowSpacing;

  /// The block-type button, handed on unresolved to its plain `Button`.
  final CoreButtonStyle blockTypeButtonStyle;

  /// The block-type menu, handed on unresolved to its `DropdownMenu`.
  final CoreDropdownMenuStyle blockTypeMenuStyle;

  /// The panel of the toolbar that floats over a selection, forwarded to its
  /// `Popup` unresolved.
  final CorePopupStyle selectionToolbarPanelStyle;

  /// Distance between the selection and the toolbar floating over it
  /// (scaled). A position offset: density does not move it.
  final double selectionToolbarOffset;

  /// The toolbar tooltip.
  final CoreTooltipStyle tooltipStyle;

  /// The shortcut keys inside the tooltip.
  final CoreKbdStyle kbdStyle;

  /// Space below each block (scaled).
  final double blockSpacing;

  /// How far a list's text sits in from its edge, for each level of nesting
  /// (scaled) — the Web twin's `padding-inline-start` on each list.
  final double listIndent;

  /// Link text and underline colour.
  final Color linkColor;

  /// Inline code and literal block text (colour left to the text).
  final TextStyle codeTextStyle;

  /// Fill behind inline code and literal blocks.
  final Color codeBackgroundColor;

  /// Inset of a literal block's text inside its box.
  final EdgeInsets codePadding;

  /// The bar beside a quote.
  final Color quoteBarColor;

  /// Width of the quote bar (scaled).
  final double quoteBarWidth;

  /// Space between the quote bar and the quoted text (scaled).
  final double quoteSpacing;

  /// Former name of [quoteSpacing].
  @Deprecated('Renamed to quoteSpacing (since 0.177) — same value.')
  double get quoteGap => quoteSpacing;

  /// Quoted text colour.
  final Color quoteTextColor;

  /// Horizontal rule colour.
  final Color ruleColor;

  /// A checked task's text colour.
  final Color completedTaskColor;

  /// A level-1 heading's text (colour left to the text).
  final TextStyle heading1TextStyle;

  /// A level-2 heading's text (colour left to the text).
  final TextStyle heading2TextStyle;

  /// A level-3 heading's text (colour left to the text); levels 4–6 take
  /// it too.
  final TextStyle heading3TextStyle;

  /// The corner of an image (scaled).
  final BorderRadius imageBorderRadius;

  /// The height an image is scaled down to (scaled).
  final double imageMaxHeight;

  /// Fill behind an image: what shows while it loads, through its
  /// transparent parts, and around the note when it cannot be shown.
  final Color imageBackgroundColor;

  /// The `Alert` of the upload rows and of the note in place of an image
  /// that cannot be shown, handed on unresolved.
  final CoreAlertStyle uploadAlertStyle;
}

/// Resolves the chrome of a `RichEditor` — the single entry point both the
/// widget and its tests read. [enabled] picks the colours that differ in the
/// disabled state: the toolbar strip's fill (none) and its rules.
ResolvedRichEditor resolveRichEditor(
  BuildContext context, {
  CoreRichEditorStyle? richEditorStyle,
  bool enabled = true,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;

  final merged = resolveStyleChain(const CoreRichEditorStyle(), [
    theme.coreComponentTheme?.richEditor?.style,
    richEditorStyle,
  ]);

  Color color(CoreColor? value, CoreColor fallback) =>
      scheme.resolve(value ?? fallback).toValue();
  double space(double? value, double fallback) =>
      theme.geometry.space(value ?? fallback) * scaling;

  final toolbarButtonStyle = CoreRichEditorStyle.defaultToolbarButtonStyle
      .merge(merged.toolbarButtonStyle);

  final heading1TextStyle = CoreRichEditorStyle.defaultHeading1TextStyle
      .merge(merged.heading1TextStyle)
      .toValue(theme: theme);
  final heading2TextStyle = CoreRichEditorStyle.defaultHeading2TextStyle
      .merge(merged.heading2TextStyle)
      .toValue(theme: theme);
  final heading3TextStyle = CoreRichEditorStyle.defaultHeading3TextStyle
      .merge(merged.heading3TextStyle)
      .toValue(theme: theme);
  final imageBorderRadius =
      (merged.imageBorderRadius ?? CoreRichEditorStyle.defaultImageBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final imageMaxHeight =
      (merged.imageMaxHeight ?? CoreRichEditorStyle.defaultImageMaxHeight) *
      scaling;
  final imageBackgroundColor = color(
    merged.imageBackgroundColor,
    CoreRichEditorStyle.defaultImageBackgroundColor,
  );
  final uploadAlertStyle = CoreRichEditorStyle.defaultUploadAlertStyle.merge(
    merged.uploadAlertStyle,
  );

  // The toolbar's rules state their colour: a disabled editor draws them in
  // `disabled-outline`, under any colour the style states itself.
  final toolbarDividerStyle = CoreRichEditorStyle.defaultToolbarDividerStyle
      .merge(merged.toolbarDividerStyle);
  final statedDividerColor = toolbarDividerStyle.color;

  final toolbarPadding =
      (merged.toolbarPadding ?? CoreRichEditorStyle.defaultToolbarPadding)
          .toGeometry(geometry: theme.geometry) *
      scaling;
  final blockTypeButtonStyle = CoreRichEditorStyle.defaultBlockTypeButtonStyle
      .merge(merged.blockTypeButtonStyle);
  final blockTypeMenuStyle = CoreRichEditorStyle.defaultBlockTypeMenuStyle
      .merge(merged.blockTypeMenuStyle);
  final selectionToolbarPanelStyle = CoreRichEditorStyle
      .defaultSelectionToolbarPanelStyle
      .merge(merged.selectionToolbarPanelStyle);
  final selectionToolbarOffset =
      (merged.selectionToolbarOffset ??
          CoreRichEditorStyle.defaultSelectionToolbarOffset) *
      scaling;

  return ResolvedRichEditor(
    textAreaStyle: CoreRichEditorStyle.defaultTextAreaStyle.merge(
      merged.textAreaStyle,
    ),
    minHeight:
        (merged.minHeight ?? CoreRichEditorStyle.defaultMinHeight) * scaling,
    maxHeight:
        (merged.maxHeight ?? CoreRichEditorStyle.defaultMaxHeight) * scaling,
    toolbarButtonStyle: toolbarButtonStyle,
    activeToolbarButtonStyle: toolbarButtonStyle
        .merge(CoreRichEditorStyle.defaultActiveToolbarButtonStyle)
        .merge(merged.activeToolbarButtonStyle),
    toolbarIconStyle: CoreRichEditorStyle.defaultToolbarIconStyle.merge(
      merged.toolbarIconStyle,
    ),
    toolbarItemSpacing: space(
      merged.toolbarItemSpacing,
      CoreRichEditorStyle.defaultToolbarItemSpacing,
    ),
    toolbarGroupGapStyle: CoreRichEditorStyle.defaultToolbarGroupGapStyle.merge(
      merged.toolbarGroupGapStyle,
    ),
    toolbarGapStyle: CoreRichEditorStyle.defaultToolbarGapStyle.merge(
      merged.toolbarGapStyle,
    ),
    toolbarBackgroundColor: enabled
        ? color(
            merged.toolbarBackgroundColor,
            CoreRichEditorStyle.defaultToolbarBackgroundColor,
          )
        : const Color(0x00000000),
    toolbarPadding: toolbarPadding,
    toolbarDividerStyle: toolbarDividerStyle.merge(
      CoreDividerStyle(
        color:
            statedDividerColor ??
            CoreColor.token(
              enabled ? CoreColors.outlineVariant : CoreColors.disabledOutline,
            ),
      ),
    ),
    toolbarGroupDividerStyle: toolbarDividerStyle,
    toolbarGroupDividerHeight:
        (merged.toolbarGroupDividerHeight ??
            CoreRichEditorStyle.defaultToolbarGroupDividerHeight) *
        scaling,
    toolbarRowSpacing: space(
      merged.toolbarRowSpacing,
      CoreRichEditorStyle.defaultToolbarRowSpacing,
    ),
    blockTypeButtonStyle: blockTypeButtonStyle,
    blockTypeMenuStyle: blockTypeMenuStyle,
    selectionToolbarPanelStyle: selectionToolbarPanelStyle,
    selectionToolbarOffset: selectionToolbarOffset,
    tooltipStyle: CoreRichEditorStyle.defaultTooltipStyle.merge(
      merged.tooltipStyle,
    ),
    kbdStyle: CoreRichEditorStyle.defaultKbdStyle.merge(merged.kbdStyle),
    blockSpacing: space(
      merged.blockSpacing,
      CoreRichEditorStyle.defaultBlockSpacing,
    ),
    listIndent: space(merged.listIndent, CoreRichEditorStyle.defaultListIndent),
    linkColor: color(merged.linkColor, CoreRichEditorStyle.defaultLinkColor),
    codeTextStyle: CoreRichEditorStyle.defaultCodeTextStyle
        .merge(merged.codeTextStyle)
        .toValue(theme: theme),
    codeBackgroundColor: color(
      merged.codeBackgroundColor,
      CoreRichEditorStyle.defaultCodeBackgroundColor,
    ),
    codePadding: (merged.codePadding ?? CoreRichEditorStyle.defaultCodePadding)
        .toValue(geometry: theme.geometry),
    quoteBarColor: color(
      merged.quoteBarColor,
      CoreRichEditorStyle.defaultQuoteBarColor,
    ),
    quoteBarWidth:
        (merged.quoteBarWidth ?? CoreRichEditorStyle.defaultQuoteBarWidth) *
        scaling,
    quoteSpacing: space(
      merged.quoteSpacing,
      CoreRichEditorStyle.defaultQuoteSpacing,
    ),
    quoteTextColor: color(
      merged.quoteTextColor,
      CoreRichEditorStyle.defaultQuoteTextColor,
    ),
    ruleColor: color(merged.ruleColor, CoreRichEditorStyle.defaultRuleColor),
    completedTaskColor: color(
      merged.completedTaskColor,
      CoreRichEditorStyle.defaultCompletedTaskColor,
    ),
    heading1TextStyle: heading1TextStyle,
    heading2TextStyle: heading2TextStyle,
    heading3TextStyle: heading3TextStyle,
    imageBorderRadius: imageBorderRadius,
    imageMaxHeight: imageMaxHeight,
    imageBackgroundColor: imageBackgroundColor,
    uploadAlertStyle: uploadAlertStyle,
  );
}
