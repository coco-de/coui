import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/form/text_area/text_area_style.dart';
import 'package:coui_web/src/components/infra/popup/popup_style.dart';
import 'package:coui_web/src/components/overlay/popover/popover_style.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `RichEditor`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)
///   ├─ pendingImages (<div>)                // rich_editor renders only while an upload is under way or failed
///   │    └─ Alert (uploadAlertStyle)        // one per upload — inline, with a spinner or a dismiss button
///   ├─ Gap (toolbarGapStyle)                // rich_editor renders only with pendingImages
///   ├─ FocusOutline (focusOutlineStyle)     // rings the box whole — the toolbar and the surface together
///   │    └─ box (<div>)                     // the TextArea's border, corners, fill and focus tint
///   │         ├─ toolbar (<div role="toolbar">)       // rich_editor renders only when showToolbar — the strip
///   │         │    ├─ toolbarButtons (<div>)          // wraps between sections, never inside one
///   │         │    │    └─ toolbarSection (<div>)     // one per toolbar group
///   │         │    │         ├─ Gap (toolbarGroupGapStyle)       // a section after the first leads with
///   │         │    │         ├─ toolbarGroupDivider (<div>)      // gap · line · gap — the line only when
///   │         │    │         │    └─ Divider (.vertical, toolbarGroupDividerStyle)  // its length is above 0
///   │         │    │         ├─ Gap (toolbarGroupGapStyle)
///   │         │    │         └─ toolbarGroup (<div role="group">)
///   │         │    │              ├─ DropdownMenu → Button(.plain, .sm)  // the block-type entry — blockTypeMenuStyle /
///   │         │    │              │    ├─ Text (the caret's block)      // blockTypeButtonStyle; a disabled editor draws
///   │         │    │              │    └─ Icon (chevron-down)           // the Button alone
///   │         │    │              └─ Tooltip → Button(.plain) → Icon   // toolbarButtonStyle / activeToolbarButtonStyle
///   │         │    │                                                   // toolbarIconStyle · tooltipStyle
///   │         │    │               tooltip content: tooltipContent (<span>)
///   │         │    │                    ├─ label            // bare Text
///   │         │    │                    ├─ Gap (toolbarGapStyle)
///   │         │    │                    └─ Kbd (kbdStyle)
///   │         │    └─ toolbarTrailing (<div>)         // rich_editor renders only with toolbarTrailing
///   │         ├─ Divider (toolbarDividerStyle)        // rich_editor renders only when showToolbar
///   │         └─ surface (<div contenteditable>)      // the TextArea's text box, without its border
///   ├─ Gap (counterGapStyle)                // rich_editor renders only with the counter
///   └─ counterRow (<div>)
///        └─ counter (<span>)
/// ```
///
/// The box is the composed `TextArea`'s: [box] is the wrapping `<div>` box
/// `resolveTextArea` resolves from the forwarded
/// `CoreRichEditorStyle.textAreaStyle` (border, corners, fill, focus and
/// hover tints), stacked as a column that clips the toolbar's strip to its
/// rounded top corners. [surface] is that resolution's `<textarea>` text
/// chrome — padding, type, caret, placeholder — on the `contenteditable`
/// `<div>`, with the editor's height range stated over it and no border of
/// its own. The document inside it is styled by [ResolvedRichEditorRules].
class ResolvedRichEditor implements WebResolvedChrome {
  /// Creates a [ResolvedRichEditor].
  const ResolvedRichEditor({
    required this.root,
    required this.box,
    required this.toolbar,
    required this.toolbarButtons,
    required this.toolbarRow,
    required this.toolbarSection,
    required this.toolbarGroup,
    required this.toolbarUnit,
    required this.toolbarUnitSpacing,
    required this.toolbarUnitHidden,
    required this.toolbarGroupDivider,
    required this.toolbarTrailing,
    required this.tooltipContent,
    required this.pendingImages,
    required this.surface,
    required this.counterRow,
    required this.counter,
    required this.focusOutlineStyle,
    required this.toolbarButtonStyle,
    required this.activeToolbarButtonStyle,
    required this.toolbarIconStyle,
    required this.toolbarDividerStyle,
    required this.toolbarGroupDividerStyle,
    required this.toolbarGroupGapStyle,
    required this.toolbarGapStyle,
    required this.blockTypeButtonStyle,
    required this.blockTypeMenuStyle,
    required this.tooltipStyle,
    required this.kbdStyle,
    required this.uploadAlertStyle,
    required this.counterGapStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` — a full-width column.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the box `<div>` that holds the toolbar and the
  /// editing surface — the `TextArea`'s border, corners, fill and focus
  /// tint, one for both, clipping what is inside to its rounded corners.
  final WebElementChrome box;

  /// Paint-ready chrome for the toolbar's strip `<div>` — the row at the top
  /// of the box that holds the buttons and, at its far end, the trailing
  /// slot. It wraps the trailing slot below the buttons when there is no
  /// room beside them, and is painted in the `surface-container` step (not
  /// while the editor is disabled).
  final WebElementChrome toolbar;

  /// Paint-ready chrome for the `<div>` of toolbar sections inside the strip
  /// — a wrapping row, so a narrow toolbar breaks between sections.
  final WebElementChrome toolbarButtons;

  /// Paint-ready chrome for the one row of a toolbar that never wraps — the
  /// toolbar over a selection, which folds buttons it has no room for into
  /// its "more" menu instead (`RichEditorToolbarBar.foldSteps`).
  final WebElementChrome toolbarRow;

  /// Paint-ready chrome for one section of the toolbar `<div>` — a group of
  /// buttons with the gap and line that lead it, kept together so a wrap
  /// never parts them.
  final WebElementChrome toolbarSection;

  /// Paint-ready chrome for one group of toolbar buttons — a row spaced by
  /// `CoreRichEditorStyle.toolbarItemSpacing`.
  final WebElementChrome toolbarGroup;

  /// Paint-ready chrome for one unit of a toolbar that folds — a button, or
  /// a group with the gap and line that lead it — a row centred on its
  /// buttons.
  final WebElementChrome toolbarUnit;

  /// [toolbarUnit] for a button that follows another of its group: it
  /// stands `CoreRichEditorStyle.toolbarItemSpacing` from it. A folded unit
  /// is out of the flow, so the space goes with it.
  final WebElementChrome toolbarUnitSpacing;

  /// What a folded unit adds to [toolbarUnit] or [toolbarUnitSpacing]: out of
  /// the flow and out of sight — but in the DOM, so its width still reads
  /// when room comes back.
  final WebElementChrome toolbarUnitHidden;

  /// Paint-ready chrome for the box that holds the vertical line between two
  /// groups — as tall as `CoreRichEditorStyle.toolbarGroupDividerHeight`.
  /// Null when that length is 0: no line is drawn and the groups sit a gap
  /// apart.
  final WebElementChrome? toolbarGroupDivider;

  /// Paint-ready chrome for the `<div>` around the trailing slot, centred on
  /// the buttons' row.
  final WebElementChrome toolbarTrailing;

  /// Paint-ready chrome for the tooltip's content row — the label and the
  /// shortcut's key caps side by side.
  final WebElementChrome tooltipContent;

  /// Paint-ready chrome for the column of rows above the box that report an
  /// image upload under way or failed, spaced by
  /// `CoreRichEditorStyle.toolbarItemSpacing`.
  final WebElementChrome pendingImages;

  /// Paint-ready chrome for the editing surface — the `TextArea`'s text box
  /// (padding, type, caret, placeholder) on the `contenteditable` `<div>`,
  /// with the editor's height range and scroll. The border, fill and focus
  /// tint are the [box]'s.
  final WebElementChrome surface;

  /// Paint-ready chrome for the row that holds the character counter,
  /// end-aligned under the box.
  final WebElementChrome counterRow;

  /// Paint-ready chrome for the character counter `<span>` — the
  /// `TextArea`'s counter, in the error colour at or over the limit.
  final WebElementChrome counter;

  /// Nested slot raw-forwarded to `FocusOutline` — the `TextArea`'s ring,
  /// drawn around the [box].
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Nested slot raw-forwarded to each toolbar `Button`.
  final CoreButtonStyle toolbarButtonStyle;

  /// Nested slot raw-forwarded to a toolbar `Button` whose format is on —
  /// [toolbarButtonStyle] with the active chrome merged over it.
  final CoreButtonStyle activeToolbarButtonStyle;

  /// Nested slot raw-forwarded to each toolbar `Icon`.
  final CoreIconStyle toolbarIconStyle;

  /// Nested slot raw-forwarded to the horizontal `Divider` under the strip. A
  /// disabled editor has the `disabled-outline` colour merged in, unless the
  /// style states a colour of its own.
  final CoreDividerStyle toolbarDividerStyle;

  /// The same slot raw-forwarded to the vertical `Divider`s between groups:
  /// the style's own colour, else the `Divider`'s — in every state. Only the
  /// line under the strip follows the editor into `disabled-outline`.
  final CoreDividerStyle toolbarGroupDividerStyle;

  /// Nested slot raw-forwarded to the `Gap` on each side of a group line (or
  /// the one `Gap` between two groups when there is no line).
  final CoreGapStyle toolbarGroupGapStyle;

  /// Nested slot raw-forwarded to the `Gap` between the rows above the box
  /// and the box (and between a tooltip's label and its key caps).
  final CoreGapStyle toolbarGapStyle;

  /// Nested slot raw-forwarded to the block-type `Button`.
  final CoreButtonStyle blockTypeButtonStyle;

  /// Nested slot raw-forwarded to the block-type `DropdownMenu`.
  final CoreDropdownMenuStyle blockTypeMenuStyle;

  /// Nested slot raw-forwarded to each toolbar `Tooltip`.
  final CoreTooltipStyle tooltipStyle;

  /// Nested slot raw-forwarded to each tooltip's `Kbd`.
  final CoreKbdStyle kbdStyle;

  /// Nested slot raw-forwarded to the `Alert` of each pending upload.
  final CoreAlertStyle uploadAlertStyle;

  /// Nested slot raw-forwarded to the `Gap` above the counter — the
  /// `TextArea`'s own helper gap.
  final CoreGapStyle counterGapStyle;
}

/// Scoped CSS text for `<style>` block in `RichEditor`.
///
/// The document inside the editing surface is markup the user edits, not
/// components — its marks (paragraph spacing, headings, lists, quotes,
/// literal code, links, rules, checked tasks) and the empty-state
/// placeholder have no element of their own to carry a class, so they are
/// painted by rules scoped to the surface's id.
class ResolvedRichEditorRules {
  /// Creates a [ResolvedRichEditorRules].
  const ResolvedRichEditorRules({required this.css});

  /// Raw CSS rule text, scoped to `#scopeId`.
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Merges the `RichEditor` style chain:
///
/// ```text
/// const CoreRichEditorStyle()
///   → theme.coreComponentTheme.richEditor.style
///   → widget.richEditorStyle
/// ```
CoreRichEditorStyle _mergeChain(
  BuildContext context,
  CoreRichEditorStyle? richEditorStyle,
) => resolveStyleChain(const CoreRichEditorStyle(), [
  context.theme.coreComponentTheme?.richEditor?.style,
  richEditorStyle,
]);

/// Resolves [ResolvedRichEditor] for a `RichEditor`.
///
/// The box is resolved by the `TextArea` resolver itself from the forwarded
/// `textAreaStyle` slot (`CoreRichEditorStyle.defaultTextAreaStyle` merged
/// with the instance's), so the editor's box is the text area's box by
/// construction — as the box that wraps its `<textarea>` (the one a prefix or
/// suffix puts on a wrapper), because here too more than the text sits inside
/// the border: the toolbar does. The wrapper's border, corners, fill and
/// focus tint become [ResolvedRichEditor.box]; the `<textarea>` chrome that
/// is left is the text's, which [ResolvedRichEditor.surface] wears. [enabled]
/// picks the text area's disabled row; the `contenteditable` `<div>` never
/// matches `:disabled`, so that row's fill and border are stated on the box
/// here and its text colour on the surface, under any colour the forwarded
/// slot states itself (an override wins in every state, the text area's own
/// order). [counterAtLimit] turns the counter to the error colour.
///
/// [serverRendered] is the surface painting its document on the server, from
/// where the browser takes it over. There the output formatter indents the
/// document's markup, and a `white-space: pre-wrap` surface draws that
/// indentation — a blank line above and below the blocks that the browser's
/// own, unformatted markup does not have, so the editor was taller on the
/// first paint than once it came alive. The server's surface therefore
/// collapses the white space around its blocks (they hold the text, and keep
/// no spaces of their own to preserve); the browser's keeps what is typed.
ResolvedRichEditor resolveRichEditor(
  BuildContext context, {
  required bool enabled,
  bool counterAtLimit = false,
  bool serverRendered = false,
  CoreRichEditorStyle? richEditorStyle,
}) {
  final merged = _mergeChain(context, richEditorStyle);

  // ─── Nested slots (default.merge(override), raw-forwarded) ─────────
  final textAreaStyle = CoreRichEditorStyle.defaultTextAreaStyle.merge(
    merged.textAreaStyle,
  );
  final toolbarButtonStyle = CoreRichEditorStyle.defaultToolbarButtonStyle
      .merge(merged.toolbarButtonStyle);
  final activeToolbarButtonStyle = toolbarButtonStyle.merge(
    CoreRichEditorStyle.defaultActiveToolbarButtonStyle.merge(
      merged.activeToolbarButtonStyle,
    ),
  );
  final toolbarIconStyle = CoreRichEditorStyle.defaultToolbarIconStyle.merge(
    merged.toolbarIconStyle,
  );
  final toolbarGroupGapStyle = CoreRichEditorStyle.defaultToolbarGroupGapStyle
      .merge(merged.toolbarGroupGapStyle);
  final toolbarGapStyle = CoreRichEditorStyle.defaultToolbarGapStyle.merge(
    merged.toolbarGapStyle,
  );
  final tooltipStyle = CoreRichEditorStyle.defaultTooltipStyle.merge(
    merged.tooltipStyle,
  );
  final kbdStyle = CoreRichEditorStyle.defaultKbdStyle.merge(merged.kbdStyle);
  final blockTypeButtonStyle = CoreRichEditorStyle.defaultBlockTypeButtonStyle
      .merge(merged.blockTypeButtonStyle);
  final blockTypeMenuStyle = CoreRichEditorStyle.defaultBlockTypeMenuStyle
      .merge(merged.blockTypeMenuStyle);
  final uploadAlertStyle = CoreRichEditorStyle.defaultUploadAlertStyle.merge(
    merged.uploadAlertStyle,
  );

  // ─── Scalars ───────────────────────────────────────────────────────
  final minHeight = merged.minHeight ?? CoreRichEditorStyle.defaultMinHeight;
  final maxHeight = merged.maxHeight ?? CoreRichEditorStyle.defaultMaxHeight;
  final toolbarItemSpacing =
      merged.toolbarItemSpacing ??
      CoreRichEditorStyle.defaultToolbarItemSpacing;
  final toolbarPadding =
      merged.toolbarPadding ?? CoreRichEditorStyle.defaultToolbarPadding;
  final toolbarRowSpacing =
      merged.toolbarRowSpacing ?? CoreRichEditorStyle.defaultToolbarRowSpacing;
  final toolbarGroupDividerHeight =
      merged.toolbarGroupDividerHeight ??
      CoreRichEditorStyle.defaultToolbarGroupDividerHeight;
  final toolbarBackground = emitColor(
    merged.toolbarBackgroundColor,
    CoreRichEditorStyle.defaultToolbarBackgroundColor,
    .background,
  );

  // ─── The composed TextArea's box ───────────────────────────────────
  // Resolved as the box that wraps its text (`affixed`): the border, the
  // corners, the fill and the focus tint then come out on the wrapper, which
  // is the one element that can hold the toolbar inside them.
  final area = resolveTextArea(
    context,
    size: CoreComponentSize.md,
    expandableHeight: false,
    expandableWidth: false,
    hasError: false,
    obscureText: false,
    obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
    enabled: enabled,
    textAreaStyle: textAreaStyle,
  );
  final areaClasses = area.textarea.className.split(' ');
  final disabledRow =
      CoreTextAreaStyle.defaultsByVariant[CoreTextAreaVariant.of(
        hasError: false,
        enabled: enabled,
      )]!;
  final errorTextColor = emitColor(
    textAreaStyle.errorTextColor,
    CoreTextAreaStyle.defaultErrorTextColor,
    .text,
  );

  // The toolbar's rules are the `Divider`'s own unless the style says
  // otherwise; a disabled editor draws the line under the strip in the
  // disabled outline, as it draws its border, unless the style states a colour
  // of its own. The lines between groups stay as they are — the designer's
  // disabled frame changes the line under the strip only.
  final dividerStyle = CoreRichEditorStyle.defaultToolbarDividerStyle.merge(
    merged.toolbarDividerStyle,
  );
  final toolbarDividerStyle = enabled || dividerStyle.color != null
      ? dividerStyle
      : dividerStyle.copyWith(color: disabledRow.disabledBorderColor);

  // ─── Local builders ───────────────────────────────────────────────

  String buildRootClassName() => WebLayout.flexColFull;

  /// The text area's wrapping box on the `<div>` that holds the toolbar and
  /// the surface: border colour, focus and hover tints, surface marker — as
  /// a column that clips the strip to its rounded top corners.
  String buildBoxClassName() => [
    WebLayout.flex,
    WebLayout.flexCol,
    WebLayout.overflowHidden,
    // The wrapper is a row there (prefix · text · suffix) and centres its
    // children; here the strip and the surface fill its width.
    for (final c in area.affixWrapper.className.split(' '))
      if (c != WebLayout.flex && c != WebLayout.itemsCenter) c,
    // The border colour fades on focus. Those classes ride the
    // `<textarea>`'s list, and the border is the box's now.
    for (final c in areaClasses)
      if (_isTransitionClass(c)) c,
    if (!enabled) 'cursor-not-allowed',
  ].where((cls) => cls.isNotEmpty).join(' ');

  Styles buildBoxInlineStyles() => .new(
    raw: {
      // Corners, border, fill and boundary layers, without the gap the
      // wrapper puts between its prefix and its text — it would open the
      // column up between the strip, the line and the surface.
      ..._without(area.affixWrapper.inlineStyles?.properties, const {'gap'}),
      // The disabled row, under the slot's own colours.
      if (!enabled) ...{
        'background-color':
            (textAreaStyle.backgroundColor ??
                    disabledRow.disabledBackgroundColor)
                .toValue(),
        'border-color':
            (textAreaStyle.borderColor ?? disabledRow.disabledBorderColor)
                .toValue(),
      },
    },
  );

  /// The strip: a wrapping row whose far end holds the trailing slot. Its
  /// own children are the buttons and the trailing slot, so a lone child on
  /// a line — the trailing slot, once it wraps — sits at the start.
  String buildToolbarClassName() => [
    WebLayout.flexBetween,
    WebLayout.flexWrap,
    WebLayout.shrinkZero,
    // Not painted while disabled: the box's own disabled fill shows through.
    if (enabled) toolbarBackground.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  Styles buildToolbarInlineStyles() => .new(
    raw: {
      // Directional by default: the wider start side follows `dir`.
      ...toolbarPadding.toLogicalDeclarations('padding'),
      'row-gap': spaceCss(toolbarRowSpacing),
      if (enabled) ...?toolbarBackground.inline,
    },
  );

  String buildToolbarButtonsClassName() => [
    WebLayout.flex,
    WebLayout.flexWrap,
    WebLayout.itemsCenter,
  ].join(' ');

  String buildToolbarRowClassName() => [
    WebLayout.flex,
    WebLayout.flexNowrap,
    WebLayout.itemsCenter,
  ].join(' ');

  String buildToolbarSectionClassName() => WebLayout.flexItemsCenter;

  String buildToolbarGroupClassName() =>
      '${WebLayout.flex} ${WebLayout.itemsCenter}';

  Styles buildToolbarGroupInlineStyles() =>
      .new(raw: {'gap': spaceCss(toolbarItemSpacing)});

  String buildToolbarUnitClassName() =>
      '${WebLayout.flex} ${WebLayout.itemsCenter} ${WebLayout.shrinkZero}';

  Styles buildToolbarUnitSpacingInlineStyles() =>
      .new(raw: {'margin-inline-start': spaceCss(toolbarItemSpacing)});

  String buildToolbarUnitHiddenClassName() =>
      '${WebLayout.absolute} ${WebLayout.invisible}';

  /// The box the group line is drawn in: as tall as the line is long, so
  /// the section's row centres it on the buttons.
  String buildToolbarGroupDividerClassName() => WebLayout.shrinkZero;

  Styles buildToolbarGroupDividerInlineStyles() =>
      .new(raw: {'height': '${toolbarGroupDividerHeight / kRemDivisor}rem'});

  String buildToolbarTrailingClassName() => WebLayout.flexItemsCenter;

  String buildTooltipContentClassName() =>
      '${WebLayout.inlineFlex} ${WebLayout.itemsCenter}';

  String buildPendingImagesClassName() => WebLayout.flexColFull;

  Styles buildPendingImagesInlineStyles() =>
      .new(raw: {'gap': spaceCss(toolbarItemSpacing)});

  /// The text area's `<textarea>` classes on the `contenteditable` `<div>`,
  /// plus what a `<div>` needs to behave as the editing surface: wrapped,
  /// space-keeping text (not on the server — see [serverRendered]), a scroll
  /// past the height range, and the not-allowed cursor while disabled.
  String buildSurfaceClassName() => [
    // The `<textarea>` box is a flex row; the document's blocks stack, so
    // the surface is a block box instead. Its border colours go with the
    // border: the surface keeps the text and leaves the box to the wrapper.
    for (final c in areaClasses)
      if (c == WebLayout.flex) WebLayout.block else if (!_isBorderClass(c)) c,
    WebLayout.overflowYAuto,
    WebLayout.breakWords,
    if (serverRendered)
      WebLayout.whitespaceNormal
    else
      WebLayout.whitespacePreWrap,
    // The placeholder is laid over the empty box from here.
    WebLayout.relative,
    if (!enabled) 'cursor-not-allowed',
  ].join(' ');

  Styles buildSurfaceInlineStyles() => .new(
    raw: {
      // The text area's padding, caret and type — not its corners (the box
      // rounds them) and not the share of a row it takes (the surface sizes
      // itself in the column).
      ..._without(area.textarea.inlineStyles?.properties, const {
        'border-radius',
        'flex',
      }),
      // The editor's height range, over the text area's own.
      'height': 'auto',
      'min-height': '${minHeight / kRemDivisor}rem',
      if (maxHeight.isFinite) 'max-height': '${maxHeight / kRemDivisor}rem',
      // The disabled row's text, under the slot's own colours; its fill and
      // border are the box's.
      if (!enabled) 'color': disabledRow.disabledForegroundColor.toValue(),
    },
  );

  String buildCounterRowClassName() =>
      '${WebLayout.flex} ${WebLayout.justifyEnd} ${WebLayout.wFull}';

  String buildCounterClassName() => [
    area.counter.className,
    if (counterAtLimit) errorTextColor.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  Styles? buildCounterInlineStyles() {
    final inline = <String, String>{
      ...?area.counter.inlineStyles?.properties,
      if (counterAtLimit) ...?errorTextColor.inline,
    };
    return inline.isEmpty ? null : .new(raw: inline);
  }

  return ResolvedRichEditor(
    root: WebElementChrome(className: buildRootClassName()),
    box: WebElementChrome(
      className: buildBoxClassName(),
      inlineStyles: buildBoxInlineStyles(),
    ),
    toolbar: WebElementChrome(
      className: buildToolbarClassName(),
      inlineStyles: buildToolbarInlineStyles(),
    ),
    toolbarButtons: WebElementChrome(className: buildToolbarButtonsClassName()),
    toolbarRow: WebElementChrome(className: buildToolbarRowClassName()),
    toolbarSection: WebElementChrome(className: buildToolbarSectionClassName()),
    toolbarUnit: WebElementChrome(className: buildToolbarUnitClassName()),
    toolbarUnitSpacing: WebElementChrome(
      className: buildToolbarUnitClassName(),
      inlineStyles: buildToolbarUnitSpacingInlineStyles(),
    ),
    toolbarUnitHidden: WebElementChrome(
      className: buildToolbarUnitHiddenClassName(),
    ),
    toolbarGroup: WebElementChrome(
      className: buildToolbarGroupClassName(),
      inlineStyles: buildToolbarGroupInlineStyles(),
    ),
    // A length of 0 draws no line: the groups sit a gap apart.
    toolbarGroupDivider: toolbarGroupDividerHeight > 0
        ? WebElementChrome(
            className: buildToolbarGroupDividerClassName(),
            inlineStyles: buildToolbarGroupDividerInlineStyles(),
          )
        : null,
    toolbarTrailing: WebElementChrome(
      className: buildToolbarTrailingClassName(),
    ),
    tooltipContent: WebElementChrome(className: buildTooltipContentClassName()),
    pendingImages: WebElementChrome(
      className: buildPendingImagesClassName(),
      inlineStyles: buildPendingImagesInlineStyles(),
    ),
    surface: WebElementChrome(
      className: buildSurfaceClassName(),
      inlineStyles: buildSurfaceInlineStyles(),
    ),
    counterRow: WebElementChrome(className: buildCounterRowClassName()),
    counter: WebElementChrome(
      className: buildCounterClassName(),
      inlineStyles: buildCounterInlineStyles(),
    ),
    focusOutlineStyle: area.focusOutlineStyle,
    toolbarButtonStyle: toolbarButtonStyle,
    activeToolbarButtonStyle: activeToolbarButtonStyle,
    toolbarIconStyle: toolbarIconStyle,
    toolbarDividerStyle: toolbarDividerStyle,
    toolbarGroupDividerStyle: dividerStyle,
    toolbarGroupGapStyle: toolbarGroupGapStyle,
    toolbarGapStyle: toolbarGapStyle,
    blockTypeButtonStyle: blockTypeButtonStyle,
    blockTypeMenuStyle: blockTypeMenuStyle,
    tooltipStyle: tooltipStyle,
    kbdStyle: kbdStyle,
    uploadAlertStyle: uploadAlertStyle,
    counterGapStyle: area.descriptionGapStyle,
  );
}

// ═══════════════════════════════════════════════════
// The toolbar over a selection
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for the `RichEditorSelectionToolbar` of a
/// `RichEditor` — the toolbar that floats over a run of selected text.
///
/// DOM shape:
///
/// ```text
/// root (<div fixed>)                 // placed by the OverlayPositioner
///   └─ motion (<div>)                // enter / exit keyframes
///        └─ Popup                    // ← panelStyle
///             └─ buttons             // the editor's own toolbar chrome
/// ```
///
/// The buttons inside are drawn from [ResolvedRichEditor]'s toolbar slots —
/// the same ones the toolbar in the box reads.
class ResolvedRichEditorSelectionToolbar implements WebResolvedChrome {
  /// Creates a [ResolvedRichEditorSelectionToolbar].
  const ResolvedRichEditorSelectionToolbar({
    required this.root,
    required this.motion,
    required this.panelStyle,
  });

  /// The positioning wrapper the engine measures: viewport-fixed, at the
  /// resolved `(left, top)` once there is one.
  @override
  final WebElementChrome root;

  /// The box the enter / exit keyframes play on — inside [root], so the
  /// scale never skews the box the engine measures.
  final WebElementChrome motion;

  /// The panel, forwarded to its `Popup` unresolved.
  final CorePopupStyle panelStyle;
}

/// Resolves the chrome of the toolbar over a selection: where it sits
/// ([left] / [top], viewport coordinates from the positioner — null until it
/// has placed the panel), its motion ([closing] plays the exit) and the panel
/// slot.
ResolvedRichEditorSelectionToolbar resolveRichEditorSelectionToolbar(
  BuildContext context, {
  required bool closing,
  double? left,
  double? top,
  CoreRichEditorStyle? richEditorStyle,
}) {
  final merged = _mergeChain(context, richEditorStyle);
  final panelStyle = CoreRichEditorStyle.defaultSelectionToolbarPanelStyle
      .merge(merged.selectionToolbarPanelStyle);
  // The enter and exit motion is the panel `Popup`'s own.
  final panel = resolvePopup(
    context,
    direction: CoreAxis.vertical,
    popupStyle: panelStyle,
  ).style;
  final motion = resolveOverlayMotion(
    positioned: left != null && top != null,
    closing: closing,
    openDuration: panel.openAnimationDuration!,
    closeDuration: panel.closeAnimationDuration!,
  );

  /// Viewport-fixed on the popover layer, above in-flow content.
  String buildRootClassName() => '${WebLayout.fixed} z-${CoreZIndex.scale.z60}';

  /// The flip/shift-resolved origin the positioner reported.
  Styles? buildRootInlineStyles() {
    if (left == null || top == null) return null;
    return .new(
      raw: {
        'top': '${top / kRemDivisor}rem',
        'left': '${left / kRemDivisor}rem',
      },
    );
  }

  return ResolvedRichEditorSelectionToolbar(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    motion: motion,
    panelStyle: panelStyle,
  );
}

/// Resolves the `OverlayPositioner` inputs for the toolbar over a selection
/// — above the selection, centred, the style's distance from it — and how
/// long its exit plays before it is unmounted (the panel `Popup`'s own).
({
  CorePopoverPlacement placement,
  double gap,
  CoreEdgeInsets viewportPadding,
  Duration closeDuration,
})
resolveRichEditorSelectionToolbarConfig(
  BuildContext context, {
  CoreRichEditorStyle? richEditorStyle,
}) {
  final merged = _mergeChain(context, richEditorStyle);
  final gap =
      merged.selectionToolbarOffset ??
      CoreRichEditorStyle.defaultSelectionToolbarOffset;
  final panel = resolvePopup(
    context,
    direction: CoreAxis.vertical,
    popupStyle: CoreRichEditorStyle.defaultSelectionToolbarPanelStyle.merge(
      merged.selectionToolbarPanelStyle,
    ),
  ).style;
  // The room the panel is held inside of — the popover's own distance from
  // the viewport's edges, as its engine config resolves it — named so the
  // bar folds its buttons to the same room the engine places the panel in.
  final viewportPadding = resolvePopoverConfig(context).viewportPadding;

  return (
    placement: CorePopoverPlacement.top,
    gap: gap,
    viewportPadding: viewportPadding,
    closeDuration: panel.closeAnimationDuration!,
  );
}

/// Resolves the scoped document rules for a `RichEditor` whose editing
/// surface carries `id=scopeId`.
///
/// Every value comes from the merged `CoreRichEditorStyle` (block spacing,
/// the three headings, link / code / quote / rule / checked-task / image
/// chrome) or from the forwarded `textAreaStyle` (the placeholder colour),
/// emitted theme-free so the rules track the theme at runtime.
ResolvedRichEditorRules resolveRichEditorRules(
  BuildContext context, {
  required String scopeId,
  CoreRichEditorStyle? richEditorStyle,
}) {
  final merged = _mergeChain(context, richEditorStyle);
  final textAreaStyle = CoreRichEditorStyle.defaultTextAreaStyle.merge(
    merged.textAreaStyle,
  );
  final normalRow =
      CoreTextAreaStyle.defaultsByVariant[CoreTextAreaVariant.defaultVariant]!;

  final blockSpacing = spaceCss(
    merged.blockSpacing ?? CoreRichEditorStyle.defaultBlockSpacing,
  );
  final linkColor = (merged.linkColor ?? CoreRichEditorStyle.defaultLinkColor)
      .toValue();
  final codeTextStyle = CoreRichEditorStyle.defaultCodeTextStyle.merge(
    merged.codeTextStyle,
  );
  final codeBackground =
      (merged.codeBackgroundColor ??
              CoreRichEditorStyle.defaultCodeBackgroundColor)
          .toValue();
  final heading1 = CoreRichEditorStyle.defaultHeading1TextStyle.merge(
    merged.heading1TextStyle,
  );
  final heading2 = CoreRichEditorStyle.defaultHeading2TextStyle.merge(
    merged.heading2TextStyle,
  );
  final heading3 = CoreRichEditorStyle.defaultHeading3TextStyle.merge(
    merged.heading3TextStyle,
  );
  final imageRadius =
      (merged.imageBorderRadius ?? CoreRichEditorStyle.defaultImageBorderRadius)
          .toValue();
  final imageMaxHeight =
      (merged.imageMaxHeight ?? CoreRichEditorStyle.defaultImageMaxHeight) /
      kRemDivisor;
  final imageBackground =
      (merged.imageBackgroundColor ??
              CoreRichEditorStyle.defaultImageBackgroundColor)
          .toValue();
  final codePadding =
      (merged.codePadding ?? CoreRichEditorStyle.defaultCodePadding).toValue();
  final quoteBarColor =
      (merged.quoteBarColor ?? CoreRichEditorStyle.defaultQuoteBarColor)
          .toValue();
  final quoteBarWidth = strokeWidthCss(
    merged.quoteBarWidth ?? CoreRichEditorStyle.defaultQuoteBarWidth,
  );
  final quoteSpacing = spaceCss(
    merged.quoteSpacing ?? CoreRichEditorStyle.defaultQuoteSpacing,
  );
  final listIndent = spaceCss(
    merged.listIndent ?? CoreRichEditorStyle.defaultListIndent,
  );
  final quoteTextColor =
      (merged.quoteTextColor ?? CoreRichEditorStyle.defaultQuoteTextColor)
          .toValue();
  final ruleColor = (merged.ruleColor ?? CoreRichEditorStyle.defaultRuleColor)
      .toValue();
  final completedTaskColor =
      (merged.completedTaskColor ??
              CoreRichEditorStyle.defaultCompletedTaskColor)
          .toValue();
  final placeholderColor =
      (textAreaStyle.placeholderStyle?.color ?? normalRow.placeholderColor)
          .toValue();
  // The document geometry the style contract leaves to the platform — a
  // literal block's corner, the space after a task's checkbox, inline
  // code's side inset and a rule's thickness — on the design scales.
  final radius = CoreRichEditorStyle.defaultCodeBorderRadius.toValue();
  final markerGap = spaceCss(CoreRichEditorStyle.defaultTaskCheckboxSpacing);
  final codeInset = spaceCss(CoreRichEditorStyle.defaultInlineCodeInset);
  final ruleWidth = strokeWidthCss(CoreRichEditorStyle.defaultRuleWidth);
  final codeRole = codeTextStyle.token?.name ?? CoreTextStyles.codeSm.name;

  /// The declarations of a type role — its role variables, then any
  /// explicit scalar override on top. The colour stays the text's own.
  String typographyCss(CoreTextStyle style) {
    final role = style.token?.name;
    final declarations = <String, String>{
      if (role != null) ...{
        'font-size': 'var(--coui-text-$role-size)',
        'line-height': 'var(--coui-text-$role-line-height)',
        'font-weight': 'var(--coui-text-$role-weight)',
        'letter-spacing': 'var(--coui-text-$role-tracking)',
      },
      ...style.toInlineCss(includeColor: false),
    };
    return declarations.entries.map((e) => '${e.key}:${e.value}').join(';');
  }

  /// A heading's declarations: its role, and the role's family when the
  /// role states one (an undefined variable leaves the family inherited).
  String headingCss(CoreTextStyle style) {
    final role = style.token?.name;
    return [
      typographyCss(style),
      if (role != null) 'font-family:var(--coui-text-$role-family)',
    ].join(';');
  }

  final s = '#$scopeId';
  const task = 'li>input[type=checkbox]:first-child';
  final rules = <String>[
    // Blocks: the space below each, none below the last.
    '$s>*,$s li>p,$s blockquote>*{margin:0 0 $blockSpacing 0}',
    '$s>*:last-child,$s blockquote>*:last-child,$s li>p:last-child',
    '{margin-bottom:0}',
    // Headings: `h4`–`h6` take the smallest step.
    '$s h1{${headingCss(heading1)}}',
    '$s h2{${headingCss(heading2)}}',
    '$s h3,$s h4,$s h5,$s h6{${headingCss(heading3)}}',
    // Lists: markers outside, indented by the marker's own width.
    '$s ul{list-style:disc;padding-inline-start:$listIndent}',
    '$s ol{list-style:decimal;padding-inline-start:$listIndent}',
    '$s ul ul,$s ol ul{list-style:circle}',
    // The page's reset strips `li` markers; an item takes its list's.
    '$s li{list-style:inherit}',
    '$s li>ul,$s li>ol{margin:0}',
    // Tasks: the checkbox stands in for the marker.
    '$s li:has(>input[type=checkbox]:first-child){list-style:none;',
    'margin-inline-start:calc(-1 * $listIndent)}',
    '$s $task{margin:0;margin-inline-end:$markerGap;',
    'vertical-align:middle;cursor:pointer}',
    '$s li:has(>input[type=checkbox]:first-child:checked)',
    '{color:$completedTaskColor;text-decoration:line-through}',
    '$s[contenteditable=false] input[type=checkbox]{pointer-events:none}',
    // Quotes.
    '$s blockquote{',
    'border-inline-start:$quoteBarWidth solid $quoteBarColor;',
    'padding-inline-start:$quoteSpacing;color:$quoteTextColor}',
    // Literal code, inline and as a block.
    '$s code{${typographyCss(codeTextStyle)};',
    'font-family:var(--coui-text-$codeRole-family);',
    'background-color:$codeBackground;border-radius:$radius;',
    'padding:0 $codeInset}',
    '$s pre{background-color:$codeBackground;border-radius:$radius;',
    'padding:$codePadding;overflow-x:auto;white-space:pre}',
    '$s pre code{padding:0;background:none}',
    // Images: scaled down into the box, never up. One alone in its paragraph
    // is a block of its own; one in a sentence stays on the line. One that
    // cannot be loaded (the bridge marks it) keeps a box of the size the
    // Flutter editor's placeholder has, so it can still be seen and selected
    // — a broken image with no alternative text would collapse to nothing.
    '$s img{display:inline-block;vertical-align:bottom;max-width:100%;',
    'max-height:${imageMaxHeight}rem;border-radius:$imageRadius;',
    'background-color:$imageBackground}',
    '$s img[data-unavailable]{min-width:${imageMaxHeight}rem;',
    'min-height:${imageMaxHeight / 2}rem}',
    // Links and rules.
    '$s a{color:$linkColor;text-decoration:underline;',
    'text-decoration-color:$linkColor}',
    '$s hr{border:0;border-top:$ruleWidth solid $ruleColor}',
    // Marks a browser spells its own way.
    '$s strong,$s b{font-weight:bold}$s em,$s i{font-style:italic}',
    '$s del,$s s,$s strike{text-decoration:line-through}',
    // The placeholder of the empty editor, over its empty paragraph and as
    // wide as the surface's content: with no insets of its own it would run
    // from where it starts to the far padding edge, and wrap later than the
    // text typed in its place.
    '$s[data-empty]::before{content:attr(data-placeholder);',
    'color:$placeholderColor;pointer-events:none;position:absolute;',
    'inset-inline:0;padding-inline:inherit}',
  ];
  return ResolvedRichEditorRules(css: rules.join());
}

// ═══════════════════════════════════════════════════
// File-private helpers
// ═══════════════════════════════════════════════════

/// Whether [cls] is a border-colour class (`border-outline`,
/// `focus-visible:border-primary`) — the colour half of a border, which the
/// box draws and the surface inside it does not.
bool _isBorderClass(String cls) =>
    cls.startsWith('border-') || cls.contains(':border-');

/// Whether [cls] is one of the classes that fade a colour change
/// (`transition-colors`, `duration-150`).
bool _isTransitionClass(String cls) =>
    cls == 'transition-colors' || cls.startsWith('duration-');

/// [properties] without the CSS properties in [names].
Map<String, String> _without(
  Map<String, String>? properties,
  Set<String> names,
) => {
  for (final entry in properties?.entries ?? const <MapEntry<String, String>>[])
    if (!names.contains(entry.key)) entry.key: entry.value,
};
