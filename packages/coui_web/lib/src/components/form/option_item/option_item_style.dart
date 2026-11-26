import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// Class marker the scoped pressed rule paints — the face inside a row.
const String kOptionItemWashMarker = 'co-option-item-wash';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `OptionItem`.
///
/// DOM shape (`option_item.dart` decides which optional branches render):
///
/// ```text
/// root (Clickable <div>)               // card: min-height · border · fill ·
///                                      // radius · padding · gap · flex row
///   ├─ <style>                         // the pressed rule (enabled rows)
///   ├─ wash (<div>)                    // absolute face, painted on :active
///   ├─ leading (<div>)                 // optional — ink + size of the glyph
///   ├─ textColumn (<div>)
///   │    ├─ label (<div>)              // typography
///   │    └─ description (<div>)        // optional
///   └─ mark (<div>) | Icon check       // single: check on the chosen row
///                                      // multiple: inert Checkbox, every row
/// ```
///
/// The card's border is a real CSS border — it survives forced colours — and
/// the padding takes the border's width out of itself, so the content sits
/// where the padding says, measured from the outer edge, whatever the state's
/// border width. The pressed face is an absolutely positioned child: it is
/// placed against the inside of the border (the padding box), and the row's
/// own stacking context (`isolate`) holds it over the fill and under the
/// content.
class ResolvedOptionItem implements WebResolvedChrome {
  /// Creates a [ResolvedOptionItem].
  const ResolvedOptionItem({
    required this.root,
    required this.wash,
    required this.leading,
    required this.textColumn,
    required this.label,
    required this.description,
    required this.mark,
    required this.leadingIconStyle,
    required this.checkIconStyle,
    required this.descriptionGapStyle,
    required this.clickableStyle,
  });

  /// The card — min height, border, fill, corner, padding, gap, the flex
  /// row and the scope class.
  @override
  final WebElementChrome root;

  /// The pressed face — positioned against the inside of the border,
  /// painted by the scoped rule.
  final WebElementChrome wash;

  /// The leading glyph's wrapper — the glyph's ink.
  final WebElementChrome leading;

  /// The label and description column.
  final WebElementChrome textColumn;

  /// The label's wrapper — the ambient text style.
  final WebElementChrome label;

  /// The description's wrapper — the ambient text style.
  final WebElementChrome description;

  /// The checkbox seat of a multiple selection.
  final WebElementChrome mark;

  /// Size of the leading glyph — raw-forwarded to the ambient `IconTheme`.
  final CoreIconStyle leadingIconStyle;

  /// The check mark of a chosen single-selection row, raw-forwarded to
  /// `Icon`.
  final CoreIconStyle checkIconStyle;

  /// Gap between the label and the description, raw-forwarded to `Gap`.
  final CoreGapStyle descriptionGapStyle;

  /// Nested chrome of the composed `Clickable` — raw-forwarded.
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text of the pressed face.
///
/// `:active` is a browser state no inline style can express, so the face's
/// colour is a rule keyed on the row's scope class.
class ResolvedOptionItemRules {
  /// Creates a [ResolvedOptionItemRules].
  const ResolvedOptionItemRules({required this.css});

  /// The rule text — empty when the row is disabled (an inert row answers
  /// no press).
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves the chrome of a Web `OptionItem`.
///
/// ```text
/// CoreOptionItemStyle.default*  (+ defaultsBySelection[selection])
///   → CoreOptionItemTheme.style
///   → widget.optionItemStyle
/// ```
ResolvedOptionItem resolveOptionItem(
  BuildContext context, {
  required String scopeClass,
  required CoreOptionItemSelection selection,
  required bool selected,
  required bool enabled,
  required bool hasDescription,
  CoreOptionItemStyle? optionItemStyle,
}) {
  final merged = resolveStyleChain(const CoreOptionItemStyle(), [
    context.theme.coreComponentTheme?.optionItem?.style,
    optionItemStyle,
  ]);
  final selectionStyle = CoreOptionItemStyle.defaultsBySelection[selection]!;

  // ─── RESOLVE (Stage 1) ────────────────────────────────
  final padding = merged.padding ?? CoreOptionItemStyle.defaultPadding;
  final minHeight = merged.minHeight ?? CoreOptionItemStyle.defaultMinHeight;
  final borderRadius =
      merged.borderRadius ?? CoreOptionItemStyle.defaultBorderRadius;
  // A chosen row fills and draws the accent border; a chosen row that is
  // disabled keeps its fill but returns to the resting border.
  final accentBorder = selected && enabled;
  final borderColor = accentBorder
      ? merged.selectedBorderColor ??
            CoreOptionItemStyle.defaultSelectedBorderColor
      : merged.borderColor ?? CoreOptionItemStyle.defaultBorderColor;
  final borderWidth = accentBorder
      ? merged.selectedBorderWidth ??
            CoreOptionItemStyle.defaultSelectedBorderWidth
      : merged.borderWidth ?? CoreOptionItemStyle.defaultBorderWidth;
  final fill = !selected
      ? null
      : enabled
      ? merged.selectedBackgroundColor ??
            CoreOptionItemStyle.defaultSelectedBackgroundColor
      : merged.disabledSelectedBackgroundColor ??
            CoreOptionItemStyle.defaultDisabledSelectedBackgroundColor;
  final spacing = merged.spacing ?? CoreOptionItemStyle.defaultSpacing;
  final disabledForeground =
      merged.disabledForegroundColor ??
      CoreOptionItemStyle.defaultDisabledForegroundColor;
  final labelSlot = CoreOptionItemStyle.defaultLabelTextStyle.merge(
    merged.labelTextStyle,
  );
  final selectedLabelSlot = labelSlot
      .merge(selectionStyle.selectedLabelTextStyle)
      .merge(merged.selectedLabelTextStyle);
  // A chosen row that is disabled keeps the chosen weight; only the ink
  // drops to the disabled foreground.
  final labelStyle = (selected ? selectedLabelSlot : labelSlot).merge(
    enabled ? null : CoreTextStyle(color: disabledForeground),
  );
  final descriptionSlot = CoreOptionItemStyle.defaultDescriptionTextStyle.merge(
    merged.descriptionTextStyle,
  );
  final descriptionStyle = enabled
      ? descriptionSlot
      : descriptionSlot.merge(CoreTextStyle(color: disabledForeground));
  final leadingIconStyle = CoreOptionItemStyle.defaultLeadingIconStyle.merge(
    merged.leadingIconStyle,
  );
  final checkIconSlot = CoreOptionItemStyle.defaultCheckIconStyle.merge(
    merged.checkIconStyle,
  );
  final checkIconStyle = enabled
      ? checkIconSlot
      : checkIconSlot.merge(CoreIconStyle(color: disabledForeground));
  // The glyph rests in the label's ink unless its slot states a colour.
  final leadingColor = !enabled
      ? disabledForeground
      : leadingIconStyle.color ?? labelSlot.color!;
  final pressedOutset =
      merged.pressedBackgroundOutset ??
      CoreOptionItemStyle.defaultPressedBackgroundOutset;
  final pressedInset =
      merged.pressedBackgroundInset ??
      CoreOptionItemStyle.defaultPressedBackgroundInset;

  // ─── EMIT (Stage 2 — Web, theme-free) ─────────────────
  final labelEmit = emitTypography(labelStyle, labelStyle);
  final descriptionEmit = emitTypography(descriptionStyle, descriptionStyle);
  final leadingInkEmit = emitColor(leadingColor, leadingColor, .text);
  final pressedRadius =
      merged.pressedBackgroundBorderRadius ??
      CoreOptionItemStyle.defaultPressedBackgroundBorderRadius;
  final cardRadiusEmit = emitRadius(
    merged.borderRadius,
    CoreOptionItemStyle.defaultBorderRadius,
  );
  final borderEmit = emitColor(borderColor, borderColor, .border);
  final fillEmit = fill == null ? null : emitColor(fill, fill, .background);
  final borderWidthCss = strokeWidthCss(borderWidth);

  WebElementChrome typographyChrome(
    ({String className, Map<String, String>? inline}) emit,
  ) => WebElementChrome(
    className: emit.className,
    inlineStyles: emit.inline == null ? null : Styles(raw: emit.inline),
  );

  return ResolvedOptionItem(
    root: WebElementChrome(
      className: [
        '$scopeClass relative flex w-full',
        if (hasDescription) 'items-start' else 'items-center',
        // The row isolates its own stacking context so the face's negative
        // z-index (the pressed rule) paints over the fill and under the
        // content — a positioned face would otherwise paint over the text.
        'text-start select-none isolate',
        cardRadiusEmit.className,
        borderEmit.className,
        ?fillEmit?.className,
      ].where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: Styles(
        raw: {
          // A floor, not a height — it does not move with a density.
          'min-height': pinnedLengthCss(minHeight),
          'border-style': 'solid',
          'border-width': borderWidthCss,
          ...?borderEmit.inline,
          ...?fillEmit?.inline,
          ...?cardRadiusEmit.inline,
          ...padding.toDeclarationsWithinBorder('padding', borderWidthCss),
          'gap': spaceCss(spacing),
        },
      ),
    ),
    wash: WebElementChrome(
      className: '$kOptionItemWashMarker pointer-events-none absolute',
      inlineStyles: Styles(
        raw: {
          // Against the inside of the border (the padding box); an outset
          // reaches past it, and the variable keeps it moving with the
          // density the row's padding follows.
          'inset-inline': 'calc(-1 * ${spaceCss(pressedOutset)})',
          'inset-block': spaceCss(pressedInset),
          // Concentric with the border's inner curve: the stated corner less
          // the border in effect, so the face follows the state's width.
          'border-radius': pressedRadius.insideBorderValue(borderWidthCss),
        },
      ),
    ),
    leading: WebElementChrome(
      className: 'flex shrink-0 items-center ${leadingInkEmit.className}',
      inlineStyles: leadingInkEmit.inline == null
          ? null
          : Styles(raw: leadingInkEmit.inline),
    ),
    textColumn: const WebElementChrome(
      className: 'flex min-w-0 flex-1 flex-col items-start',
    ),
    label: typographyChrome(labelEmit),
    description: typographyChrome(descriptionEmit),
    mark: const WebElementChrome(
      // A picture of the row's state: the row takes the tap.
      className: 'flex shrink-0 items-center pointer-events-none',
    ),
    leadingIconStyle: leadingIconStyle,
    checkIconStyle: checkIconStyle,
    descriptionGapStyle: CoreOptionItemStyle.defaultDescriptionGapStyle.merge(
      merged.descriptionGapStyle,
    ),
    // The focus ring follows the corner of the card.
    clickableStyle: CoreOptionItemStyle.defaultClickableStyle
        .merge(CoreClickableStyle(borderRadius: borderRadius))
        .merge(merged.clickableStyle),
  );
}

/// Resolves the pressed-face rule for the row carrying [scopeClass].
///
/// Walks the same chain as [resolveOptionItem], so a theme or instance
/// override of the face's colour or weight lands here too.
ResolvedOptionItemRules resolveOptionItemRules(
  BuildContext context, {
  required String scopeClass,
  required bool enabled,
  CoreOptionItemStyle? optionItemStyle,
}) {
  if (!enabled) return const ResolvedOptionItemRules(css: '');
  final merged = resolveStyleChain(const CoreOptionItemStyle(), [
    context.theme.coreComponentTheme?.optionItem?.style,
    optionItemStyle,
  ]);
  final color =
      merged.pressedBackgroundColor ??
      CoreOptionItemStyle.defaultPressedBackgroundColor;
  final stateLayer = merged.stateLayer ?? CoreOptionItemStyle.defaultStateLayer;
  final buffer = StringBuffer()
    ..write('.$scopeClass:active > .$kOptionItemWashMarker{')
    ..write('background-color:')
    ..write(color.scaleAlpha(stateLayer.pressed).toValue())
    ..write(';z-index:-1;}');
  return ResolvedOptionItemRules(css: buffer.toString());
}
