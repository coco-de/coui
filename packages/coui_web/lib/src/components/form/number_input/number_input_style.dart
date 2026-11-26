import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// ResolvedNumberInput
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `NumberInput`.
///
/// surface:content — draws no box of its own; the composed `TextField`
/// draws it.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                       // fixed-width wrapper
///   └─ TextField                     // fieldStyle · centred value
///        ├─ prefix: Button (minus)   // plain · square · size.toStepButtonSize()
///        └─ suffix: Button (plus)
/// ```
///
/// The field and the ends are composed components, so [fieldStyle] and
/// [buttonStyle] are raw-forwarded and each child resolver fills its own
/// ladder; the only chrome this resolver emits is the wrapper's width.
class ResolvedNumberInput implements WebResolvedChrome {
  /// Creates a [ResolvedNumberInput].
  const ResolvedNumberInput({
    required this.root,
    required this.buttonStyle,
    required this.fieldStyle,
  });

  /// Paint-ready chrome for the wrapper `<div>` — its fixed width.
  @override
  final WebElementChrome root;

  /// Nested button style — forwarded to both step `Button`s.
  final CoreButtonStyle buttonStyle;

  /// Nested field style — forwarded to the composed `TextField`.
  final CoreTextFieldStyle fieldStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedNumberInput] for the given [context].
///
/// ```text
/// design system default for the size
///   → theme.coreComponentTheme.numberInput.style
///   → theme.coreComponentTheme.numberInput.variantStyles[variant]
///   → widget.numberInputStyle
/// ```
ResolvedNumberInput resolveNumberInput(
  BuildContext context, {
  required CoreNumberInputSize size,
  required CoreNumberInputVariant variant,
  CoreNumberInputStyle? numberInputStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.numberInput;

  final merged = resolveStyleChain(const CoreNumberInputStyle(), [
    csTheme?.style,
    csTheme?.variantStyles?[variant],
    numberInputStyle,
  ]);
  final sizeRow = CoreNumberInputStyle.defaultsBySize[size]!;

  // ─── Stage 1 RESOLVE (Core values; theme-free) ─────────
  final width = merged.width ?? sizeRow.width!;
  final buttonStyle = CoreNumberInputStyle.defaultButtonStyle.merge(
    merged.buttonStyle,
  );
  final fieldStyle = CoreNumberInputStyle.defaultFieldStyle.merge(
    merged.fieldStyle,
  );

  // ─── Stage 2 EMIT ──────────────────────────────────────
  // The width is a fixed size, not a gap: Flutter bakes it with the layout
  // scaling only, so density does not move it.
  final rootInline = Styles(raw: {'width': pinnedLengthCss(width)});

  return ResolvedNumberInput(
    root: WebElementChrome(className: 'max-w-full', inlineStyles: rootInline),
    buttonStyle: buttonStyle,
    fieldStyle: fieldStyle,
  );
}
