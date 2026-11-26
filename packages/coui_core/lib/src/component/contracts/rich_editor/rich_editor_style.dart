/// Per-instance style for `RichEditor`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/alert/alert_style.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/divider/divider_style.dart';
import 'package:coui_core/src/component/contracts/dropdown_menu/dropdown_menu_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/kbd/kbd_style.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/contracts/text_area/text_area_style.dart';
import 'package:coui_core/src/component/contracts/tooltip/tooltip_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `RichEditor` should render.
///
/// The editor composes other components rather than drawing their chrome:
/// the box is a `TextArea`'s ([textAreaStyle]), each toolbar button is a
/// plain `Button` ([toolbarButtonStyle]) with an `Icon`
/// ([toolbarIconStyle]), its hint is a `Tooltip` ([tooltipStyle]) holding a
/// `Kbd` ([kbdStyle]), the block-type menu is a plain `Button`
/// ([blockTypeButtonStyle]) opening a `DropdownMenu` ([blockTypeMenuStyle]),
/// the toolbar that floats over a selection is a `Popup`
/// ([selectionToolbarPanelStyle]) holding the same buttons, and the spaces
/// are `Gap`s. Those slots are handed to
/// the child components as they are; only the document's own marks — the
/// headings, code, quotes, links, rules and images — are flat fields here.
/// The row that reports an image upload — and the note in place of an image
/// that cannot be shown — is an `Alert` ([uploadAlertStyle]).
///
/// ```text
/// design system default (CoreRichEditorStyle.defaultX static const)
///   → CoreRichEditorTheme.style                      // 프로젝트 공통
///   → widget.richEditorStyle                         // 인스턴스별
/// ```
@immutable
class CoreRichEditorStyle implements CoreStyle<CoreRichEditorStyle> {
  /// Creates a [CoreRichEditorStyle].
  const CoreRichEditorStyle({
    this.textAreaStyle,
    this.minHeight,
    this.maxHeight,
    this.toolbarButtonStyle,
    this.activeToolbarButtonStyle,
    this.toolbarIconStyle,
    this.toolbarItemSpacing,
    this.toolbarGroupGapStyle,
    this.toolbarGapStyle,
    this.toolbarBackgroundColor,
    this.toolbarPadding,
    this.toolbarDividerStyle,
    this.toolbarGroupDividerHeight,
    this.toolbarRowSpacing,
    this.blockTypeButtonStyle,
    this.blockTypeMenuStyle,
    this.selectionToolbarPanelStyle,
    this.selectionToolbarOffset,
    this.tooltipStyle,
    this.kbdStyle,
    this.blockSpacing,
    this.listIndent,
    this.linkColor,
    this.codeTextStyle,
    this.codeBackgroundColor,
    this.codePadding,
    this.quoteBarColor,
    this.quoteBarWidth,
    double? quoteSpacing,
    this.quoteTextColor,
    this.ruleColor,
    this.completedTaskColor,
    this.heading1TextStyle,
    this.heading2TextStyle,
    this.heading3TextStyle,
    this.imageBorderRadius,
    this.imageMaxHeight,
    this.imageBackgroundColor,
    this.uploadAlertStyle,
    @Deprecated(
      'Renamed to quoteSpacing (since 0.177) — same value; the old name '
      'read as a Gap style slot.',
    )
    double? quoteGap,
  }) : quoteSpacing = quoteSpacing ?? quoteGap;

  // ─── Design-system defaults ─────────────────────────────────────────

  /// Default box chrome — the `TextArea`'s own, unchanged.
  static const CoreTextAreaStyle defaultTextAreaStyle = CoreTextAreaStyle();

  /// Default height of the empty editing area — about three lines.
  static const double defaultMinHeight = CoreSize.size80;

  /// Default height the area grows to before it scrolls.
  static const double defaultMaxHeight = CoreSize.size80 * 3;

  /// Default toolbar button — a 32 square with the icon centred, so the
  /// buttons line up as a strip above the box, filled under the pointer.
  static const CoreButtonStyle defaultToolbarButtonStyle = CoreButtonStyle(
    hoverBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    height: CoreSize.size32,
    width: CoreSize.size32,
    minWidth: CoreSize.size32,
    padding: CoreEdgeInsets.zero,
  );

  /// Default chrome added to a toolbar button whose format is on at the
  /// caret — the hover fill, kept, so "on" reads as "held down".
  static const CoreButtonStyle defaultActiveToolbarButtonStyle =
      CoreButtonStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
        foregroundColor: CoreColor.token(CoreColors.onSurface),
      );

  /// Default toolbar icon — 16, the label-sized glyph.
  static const CoreIconStyle defaultToolbarIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default space between buttons of one group.
  static const double defaultToolbarItemSpacing = CoreSpace.space2;

  /// Default gap between toolbar groups.
  static const CoreGapStyle defaultToolbarGroupGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default gap between the box and the rows above it (the upload rows).
  static const CoreGapStyle defaultToolbarGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default fill of the toolbar strip at the top of the box — the
  /// `surface-container` step. Not painted while the editor is disabled: the
  /// box's own disabled fill shows through.
  static const CoreColor defaultToolbarBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default inset of the toolbar's buttons inside its strip — 4 above and
  /// below, 12 on the side the text starts on and 8 on the other.
  ///
  /// The start side is wider because the strip opens with the block-type
  /// button's label, which draws no inset of its own (a plain `Button`):
  /// the 12 is the space a reader sees in front of that label. It is a
  /// statement about where text begins, so it is directional — in a
  /// right-to-left locale the 12 is on the right.
  static const CoreEdgeInsets defaultToolbarPadding =
      CoreEdgeInsets.directional(
        start: CoreSpace.space12,
        top: CoreSpace.space4,
        end: CoreSpace.space8,
        bottom: CoreSpace.space4,
      );

  /// Default rules of the toolbar — the `Divider`'s own (a 1 thick
  /// `outline-variant` line); the disabled editor draws them in
  /// `disabled-outline`.
  static const CoreDividerStyle defaultToolbarDividerStyle = CoreDividerStyle();

  /// Default length of the line between two toolbar groups — 20.
  static const double defaultToolbarGroupDividerHeight = CoreSize.size20;

  /// Default space between the rows of a toolbar that wraps (its buttons,
  /// then its trailing widget) — 4.
  static const double defaultToolbarRowSpacing = CoreSpace.space4;

  /// Default block-type button — a plain `Button` at its `sm` row, with the
  /// label and its chevron 4 apart, closer than the row's own 6 so the
  /// chevron reads as part of the label.
  static const CoreButtonStyle defaultBlockTypeButtonStyle = CoreButtonStyle(
    iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
  );

  /// Default block-type menu — the `DropdownMenu`'s own panel, rows and
  /// offset under the button.
  static const CoreDropdownMenuStyle defaultBlockTypeMenuStyle =
      CoreDropdownMenuStyle();

  /// Default panel of the toolbar that floats over a selection — the
  /// `Popup`'s own face (fill, line, cast), with the two things this panel
  /// states differently: a 10 corner, and an inset of 4 above, below and at
  /// the end with 12 on the side the text starts on.
  ///
  /// The 12 is the same statement as [defaultToolbarPadding]'s: the panel
  /// opens with the block-type button's label, which draws no inset of its
  /// own, so the space in front of that label matches the toolbar in the
  /// box. It is directional — in a right-to-left locale the 12 is on the
  /// right. The corner is the designer's stated 10 for this panel, not a
  /// role: a `Popup` is a panel (12) and this one is drawn tighter.
  static const CorePopupStyle defaultSelectionToolbarPanelStyle =
      CorePopupStyle(
        padding: CoreEdgeInsets.directional(
          start: CoreSpace.space12,
          top: CoreSpace.space4,
          end: CoreSpace.space4,
          bottom: CoreSpace.space4,
        ),
        borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      );

  /// Default distance between a selection and the toolbar floating over it
  /// — 8. A position offset, like a menu's distance from its trigger: it
  /// does not move with density.
  static const double defaultSelectionToolbarOffset = CoreSpace.space8;

  /// Default tooltip — the `Tooltip`'s own.
  static const CoreTooltipStyle defaultTooltipStyle = CoreTooltipStyle();

  /// Default shortcut keys in the tooltip — the `Kbd`'s own.
  static const CoreKbdStyle defaultKbdStyle = CoreKbdStyle();

  /// Default space below each block of the document.
  static const double defaultBlockSpacing = CoreSpace.space6;

  /// Default inset of a list from the text's start, per level of nesting —
  /// the marker's own width.
  static const double defaultListIndent = CoreSpace.space24;

  /// Default colour of link text and its underline.
  static const CoreColor defaultLinkColor = CoreColor.token(CoreColors.link);

  /// Default text of inline code and literal blocks — the small code role.
  static const CoreTextStyle defaultCodeTextStyle = CoreTextStyle.token(
    CoreTextStyles.codeSm,
  );

  /// Default fill behind inline code and literal blocks.
  static const CoreColor defaultCodeBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default inset of a literal block's text inside its box.
  static const CoreEdgeInsets defaultCodePadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space10,
    vertical: CoreSpace.space8,
  );

  /// Default colour of the bar beside a quote.
  static const CoreColor defaultQuoteBarColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default width of the bar beside a quote.
  static const double defaultQuoteBarWidth = CoreStrokeWidth.stroke3;

  /// Default space between the quote bar and the quoted text.
  static const double defaultQuoteSpacing = CoreSpace.space10;

  /// Former name of [defaultQuoteSpacing].
  @Deprecated(
    'Renamed to defaultQuoteSpacing (since 0.177) — same value.',
  )
  static const double defaultQuoteGap = defaultQuoteSpacing;

  // ─── Document geometry the Style has no field for ──────────────────
  //
  // Read by the Web document rules. The Flutter editor takes these from
  // super_editor's own stylesheet today, so the two platforms can draw them
  // differently — wiring Flutter to read them is tracked on #6038.

  /// Corner of a literal block and of inline code — the part role.
  static const CoreBorderRadius defaultCodeBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.part,
  );

  /// Space between a task's checkbox and its text.
  static const double defaultTaskCheckboxSpacing = CoreSpace.space8;

  /// Inset of inline code's text from each side of its fill.
  static const double defaultInlineCodeInset = CoreSpace.space4;

  /// Thickness of a horizontal rule.
  static const double defaultRuleWidth = CoreStrokeWidth.stroke1;

  /// Default colour of quoted text.
  static const CoreColor defaultQuoteTextColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default colour of a horizontal rule.
  static const CoreColor defaultRuleColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default colour of a checked task's text (it is also struck through).
  static const CoreColor defaultCompletedTaskColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default text of a level-1 heading — the large title role.
  static const CoreTextStyle defaultHeading1TextStyle = CoreTextStyle.token(
    CoreTextStyles.titleLarge,
  );

  /// Default text of a level-2 heading — the medium title role.
  static const CoreTextStyle defaultHeading2TextStyle = CoreTextStyle.token(
    CoreTextStyles.titleMedium,
  );

  /// Default text of a level-3 heading — the small title role.
  static const CoreTextStyle defaultHeading3TextStyle = CoreTextStyle.token(
    CoreTextStyles.titleSmall,
  );

  /// Default corner of an image — a control's, 8.
  static const CoreBorderRadius defaultImageBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.control,
  );

  /// Default height an image is scaled down to — 192, so one fits in the
  /// editing area with a line of text beside it.
  static const double defaultImageMaxHeight = CoreSize.size96 * 2;

  /// Default fill behind an image while it loads and when it cannot be
  /// shown.
  static const CoreColor defaultImageBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default row for an upload under way or failed — the `Alert`'s own.
  static const CoreAlertStyle defaultUploadAlertStyle = CoreAlertStyle();

  // ─── Fields ─────────────────────────────────────────────────────────

  /// The box — border, radius, fill, padding, focus ring, text, placeholder,
  /// selection and caret colour — handed to the `TextArea` as is.
  final CoreTextAreaStyle? textAreaStyle;

  /// Height of the editing area when it holds little text.
  final double? minHeight;

  /// Height the editing area grows to before it scrolls.
  final double? maxHeight;

  /// Each toolbar button, forwarded to its plain `Button`.
  final CoreButtonStyle? toolbarButtonStyle;

  /// Merged over [toolbarButtonStyle] while the button's format is on.
  final CoreButtonStyle? activeToolbarButtonStyle;

  /// Each toolbar button's icon, forwarded to its `Icon`.
  final CoreIconStyle? toolbarIconStyle;

  /// Space between the buttons of one group.
  final double? toolbarItemSpacing;

  /// Gap between toolbar groups.
  final CoreGapStyle? toolbarGroupGapStyle;

  /// Gap between the box and the rows above it — the upload rows.
  final CoreGapStyle? toolbarGapStyle;

  /// Fill of the toolbar strip at the top of the box. Not painted while the
  /// editor is disabled.
  final CoreColor? toolbarBackgroundColor;

  /// Inset of the toolbar's buttons inside its strip.
  final CoreEdgeInsets? toolbarPadding;

  /// The toolbar's rules, forwarded to their `Divider`s: the horizontal line
  /// under the strip and the vertical line between groups. A disabled editor
  /// draws the line under the strip in `disabled-outline` unless this states a
  /// colour; the lines between groups keep the `Divider`'s own colour — as in
  /// the designer's disabled frame (#5951), where only the line under the
  /// strip changes.
  final CoreDividerStyle? toolbarDividerStyle;

  /// Length of the vertical line between two groups; 0 draws none, and the
  /// groups sit a gap apart.
  final double? toolbarGroupDividerHeight;

  /// Space between the rows of a toolbar that wraps.
  final double? toolbarRowSpacing;

  /// The block-type button (`CoreRichEditorFormat.blockType`), forwarded to
  /// its plain `Button` — the one toolbar button with a label.
  final CoreButtonStyle? blockTypeButtonStyle;

  /// The menu the block-type button opens, forwarded to its `DropdownMenu`.
  final CoreDropdownMenuStyle? blockTypeMenuStyle;

  /// The panel of the toolbar that floats over a selection
  /// (`RichEditorSelectionToolbar`), passed to its `Popup`. The buttons
  /// inside it use the main toolbar's styles — [toolbarButtonStyle],
  /// [toolbarIconStyle], [blockTypeButtonStyle], the group gap and line —
  /// so the two toolbars always look the same.
  final CorePopupStyle? selectionToolbarPanelStyle;

  /// Distance between the selection and the toolbar floating over it — above
  /// it, or below when there is no room above.
  final double? selectionToolbarOffset;

  /// The toolbar buttons' tooltip, forwarded to `Tooltip`.
  final CoreTooltipStyle? tooltipStyle;

  /// The shortcut keys inside the tooltip, forwarded to `Kbd`.
  final CoreKbdStyle? kbdStyle;

  /// Space below each block of the document.
  final double? blockSpacing;

  /// Inset of a list from the text's start, per level — a list inside a
  /// list is set in by one more of it.
  final double? listIndent;

  /// Colour of link text and its underline.
  final CoreColor? linkColor;

  /// Text of inline code and literal blocks. Its size, weight and family
  /// apply; the colour stays the text's own.
  final CoreTextStyle? codeTextStyle;

  /// Fill behind inline code and literal blocks.
  final CoreColor? codeBackgroundColor;

  /// Inset of a literal block's text inside its box.
  final CoreEdgeInsets? codePadding;

  /// Colour of the bar beside a quote.
  final CoreColor? quoteBarColor;

  /// Width of the bar beside a quote.
  final double? quoteBarWidth;

  /// Space between the quote bar and the quoted text.
  final double? quoteSpacing;

  /// Former name of [quoteSpacing].
  @Deprecated(
    'Renamed to quoteSpacing (since 0.177) — same value; the old name '
    'read as a Gap style slot.',
  )
  double? get quoteGap => quoteSpacing;

  /// Colour of quoted text.
  final CoreColor? quoteTextColor;

  /// Colour of a horizontal rule.
  final CoreColor? ruleColor;

  /// Colour of a checked task's text.
  final CoreColor? completedTaskColor;

  /// Text of a level-1 heading. Its size, weight and family apply; the
  /// colour stays the text's own.
  final CoreTextStyle? heading1TextStyle;

  /// Text of a level-2 heading. Its size, weight and family apply; the
  /// colour stays the text's own.
  final CoreTextStyle? heading2TextStyle;

  /// Text of a level-3 heading. Its size, weight and family apply; the
  /// colour stays the text's own.
  final CoreTextStyle? heading3TextStyle;

  /// Corner of an image.
  final CoreBorderRadius? imageBorderRadius;

  /// Height an image is scaled down to when it is taller; a smaller image
  /// keeps its size.
  final double? imageMaxHeight;

  /// Fill behind an image: what shows while it loads, and through its
  /// transparent parts.
  final CoreColor? imageBackgroundColor;

  /// The row above the box that reports an image upload under way or
  /// failed, and the note that stands in for an image that cannot be shown
  /// (Flutter), forwarded to their `Alert`.
  final CoreAlertStyle? uploadAlertStyle;

  @override
  CoreRichEditorStyle merge(CoreRichEditorStyle? other) {
    if (other == null) return this;
    return CoreRichEditorStyle(
      textAreaStyle: _merge(textAreaStyle, other.textAreaStyle),
      minHeight: other.minHeight ?? minHeight,
      maxHeight: other.maxHeight ?? maxHeight,
      toolbarButtonStyle: _merge(toolbarButtonStyle, other.toolbarButtonStyle),
      activeToolbarButtonStyle: _merge(
        activeToolbarButtonStyle,
        other.activeToolbarButtonStyle,
      ),
      toolbarIconStyle: _merge(toolbarIconStyle, other.toolbarIconStyle),
      toolbarItemSpacing: other.toolbarItemSpacing ?? toolbarItemSpacing,
      toolbarGroupGapStyle: _merge(
        toolbarGroupGapStyle,
        other.toolbarGroupGapStyle,
      ),
      toolbarGapStyle: _merge(toolbarGapStyle, other.toolbarGapStyle),
      toolbarBackgroundColor:
          other.toolbarBackgroundColor ?? toolbarBackgroundColor,
      toolbarPadding: other.toolbarPadding ?? toolbarPadding,
      toolbarDividerStyle: _merge(
        toolbarDividerStyle,
        other.toolbarDividerStyle,
      ),
      toolbarGroupDividerHeight:
          other.toolbarGroupDividerHeight ?? toolbarGroupDividerHeight,
      toolbarRowSpacing: other.toolbarRowSpacing ?? toolbarRowSpacing,
      blockTypeButtonStyle: _merge(
        blockTypeButtonStyle,
        other.blockTypeButtonStyle,
      ),
      blockTypeMenuStyle: _merge(blockTypeMenuStyle, other.blockTypeMenuStyle),
      selectionToolbarPanelStyle: _merge(
        selectionToolbarPanelStyle,
        other.selectionToolbarPanelStyle,
      ),
      selectionToolbarOffset:
          other.selectionToolbarOffset ?? selectionToolbarOffset,
      tooltipStyle: _merge(tooltipStyle, other.tooltipStyle),
      kbdStyle: _merge(kbdStyle, other.kbdStyle),
      blockSpacing: other.blockSpacing ?? blockSpacing,
      listIndent: other.listIndent ?? listIndent,
      linkColor: other.linkColor ?? linkColor,
      codeTextStyle: codeTextStyle == null
          ? other.codeTextStyle
          : codeTextStyle!.merge(other.codeTextStyle),
      codeBackgroundColor: other.codeBackgroundColor ?? codeBackgroundColor,
      codePadding: other.codePadding ?? codePadding,
      quoteBarColor: other.quoteBarColor ?? quoteBarColor,
      quoteBarWidth: other.quoteBarWidth ?? quoteBarWidth,
      quoteSpacing: other.quoteSpacing ?? quoteSpacing,
      quoteTextColor: other.quoteTextColor ?? quoteTextColor,
      ruleColor: other.ruleColor ?? ruleColor,
      completedTaskColor: other.completedTaskColor ?? completedTaskColor,
      heading1TextStyle: _mergeText(heading1TextStyle, other.heading1TextStyle),
      heading2TextStyle: _mergeText(heading2TextStyle, other.heading2TextStyle),
      heading3TextStyle: _mergeText(heading3TextStyle, other.heading3TextStyle),
      imageBorderRadius: other.imageBorderRadius ?? imageBorderRadius,
      imageMaxHeight: other.imageMaxHeight ?? imageMaxHeight,
      imageBackgroundColor: other.imageBackgroundColor ?? imageBackgroundColor,
      uploadAlertStyle: _merge(uploadAlertStyle, other.uploadAlertStyle),
    );
  }

  static T? _merge<T extends CoreStyle<T>>(T? base, T? other) {
    if (base == null) return other;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) =>
      base == null ? other : base.merge(other);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRichEditorStyle &&
          runtimeType == other.runtimeType &&
          textAreaStyle == other.textAreaStyle &&
          minHeight == other.minHeight &&
          maxHeight == other.maxHeight &&
          toolbarButtonStyle == other.toolbarButtonStyle &&
          activeToolbarButtonStyle == other.activeToolbarButtonStyle &&
          toolbarIconStyle == other.toolbarIconStyle &&
          toolbarItemSpacing == other.toolbarItemSpacing &&
          toolbarGroupGapStyle == other.toolbarGroupGapStyle &&
          toolbarGapStyle == other.toolbarGapStyle &&
          toolbarBackgroundColor == other.toolbarBackgroundColor &&
          toolbarPadding == other.toolbarPadding &&
          toolbarDividerStyle == other.toolbarDividerStyle &&
          toolbarGroupDividerHeight == other.toolbarGroupDividerHeight &&
          toolbarRowSpacing == other.toolbarRowSpacing &&
          blockTypeButtonStyle == other.blockTypeButtonStyle &&
          blockTypeMenuStyle == other.blockTypeMenuStyle &&
          selectionToolbarPanelStyle == other.selectionToolbarPanelStyle &&
          selectionToolbarOffset == other.selectionToolbarOffset &&
          tooltipStyle == other.tooltipStyle &&
          kbdStyle == other.kbdStyle &&
          blockSpacing == other.blockSpacing &&
          listIndent == other.listIndent &&
          linkColor == other.linkColor &&
          codeTextStyle == other.codeTextStyle &&
          codeBackgroundColor == other.codeBackgroundColor &&
          codePadding == other.codePadding &&
          quoteBarColor == other.quoteBarColor &&
          quoteBarWidth == other.quoteBarWidth &&
          quoteSpacing == other.quoteSpacing &&
          quoteTextColor == other.quoteTextColor &&
          ruleColor == other.ruleColor &&
          completedTaskColor == other.completedTaskColor &&
          heading1TextStyle == other.heading1TextStyle &&
          heading2TextStyle == other.heading2TextStyle &&
          heading3TextStyle == other.heading3TextStyle &&
          imageBorderRadius == other.imageBorderRadius &&
          imageMaxHeight == other.imageMaxHeight &&
          imageBackgroundColor == other.imageBackgroundColor &&
          uploadAlertStyle == other.uploadAlertStyle;

  @override
  int get hashCode => Object.hashAll([
    textAreaStyle,
    minHeight,
    maxHeight,
    toolbarButtonStyle,
    activeToolbarButtonStyle,
    toolbarIconStyle,
    toolbarItemSpacing,
    toolbarGroupGapStyle,
    toolbarGapStyle,
    toolbarBackgroundColor,
    toolbarPadding,
    toolbarDividerStyle,
    toolbarGroupDividerHeight,
    toolbarRowSpacing,
    blockTypeButtonStyle,
    blockTypeMenuStyle,
    selectionToolbarPanelStyle,
    selectionToolbarOffset,
    tooltipStyle,
    kbdStyle,
    blockSpacing,
    listIndent,
    linkColor,
    codeTextStyle,
    codeBackgroundColor,
    codePadding,
    quoteBarColor,
    quoteBarWidth,
    quoteSpacing,
    quoteTextColor,
    ruleColor,
    completedTaskColor,
    heading1TextStyle,
    heading2TextStyle,
    heading3TextStyle,
    imageBorderRadius,
    imageMaxHeight,
    imageBackgroundColor,
    uploadAlertStyle,
  ]);
}
