import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Class marker the scoped wash rules paint — the overlay inside a trigger.
const String _kCommandSearchWashMarker = 'co-command-search-wash';

/// Paint-ready chrome for Web `CommandSearch`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="button"> — the composed Clickable's box)
///   ├─ <style>                          // * only while enabled — the wash rules
///   ├─ wash (<div>)                     // absolute overlay — :hover / :focus-visible / :active
///   ├─ leading                          // caller-supplied Component, or the search glyph
///   ├─ hint (<div>)                     // takes the remaining width, truncates
///   └─ shortcut                         // caller-supplied Component, optional
/// ```
///
/// `command_search.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion in the
/// widget body. The wash is an overlay rather than a background swap because
/// the face has to stay visible *under* it — that is what makes it a state
/// layer rather than a replacement.
class ResolvedCommandSearch implements WebResolvedChrome {
  /// Creates a [ResolvedCommandSearch].
  const ResolvedCommandSearch({
    required this.root,
    required this.wash,
    required this.hint,
    required this.leadingIconStyle,
    required this.contentGapStyle,
    required this.clickableStyle,
  });

  /// The trigger box — layout, height, insets, corner and face.
  @override
  final WebElementChrome root;

  /// Absolute overlay inside an enabled trigger; the scoped rules paint it.
  /// It takes the box's corner, so its edge stays inside the face.
  final WebElementChrome wash;

  /// Hint typography and the ink it is drawn in.
  final WebElementChrome hint;

  /// Leading glyph chrome — size and ink, handed to the glyph through the
  /// ambient icon theme so a caller's glyph takes it too.
  final CoreIconStyle leadingIconStyle;

  /// Seat gap — raw-forwarded to the composed `Gap`.
  final CoreGapStyle contentGapStyle;

  /// Nested chrome of the composed `Clickable` (focus ring, press).
  final CoreClickableStyle clickableStyle;
}

/// Scoped CSS text for the `<style>` block in `CommandSearch`.
///
/// The wash is the state-layer colour at [CoreStateLayer] weight, so it is a
/// derived colour rather than a token — no preset class can name it, and it
/// would collide with the face if it were emitted as a `background-color` on
/// the trigger. Both facts point the same way: scoped rules on an overlay.
class ResolvedCommandSearchRules {
  /// Creates a [ResolvedCommandSearchRules].
  const ResolvedCommandSearchRules({required this.css});

  /// The rule text — empty when the trigger is disabled (a wash under the
  /// pointer would say it responds).
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCommandSearch] for the given [context].
///
/// Priority (per-field): `commandSearchStyle` >
/// `CoreCommandSearchTheme.style` > `CoreCommandSearchStyle.defaultsBySize`
/// for the size-keyed fields > `CoreCommandSearchStyle.defaultX` — the same
/// chain the Flutter twin walks. Web EMIT is theme-free: token names go out
/// as classes and the browser resolves them at run time.
///
/// [enabled] is build-time semantic state (the Flutter twin selects with the
/// same flag), not interaction state — hover / focus / press stay with the
/// browser.
ResolvedCommandSearch resolveCommandSearch(
  BuildContext context, {
  required String scopeClass,
  CoreCommandSize size = CoreCommandSize.defaultSize,
  bool enabled = true,
  CoreCommandSearchStyle? commandSearchStyle,
}) {
  final searchTheme = context.theme.coreComponentTheme?.commandSearch;
  final merged = resolveStyleChain(const CoreCommandSearchStyle(), [
    searchTheme?.style,
    commandSearchStyle,
  ]);
  final sizeStyle = CoreCommandSearchStyle.defaultsBySize[size]!;

  // ─── Stage 1 RESOLVE ──────────────────────────────
  // The size row's height sits on the control ladder and goes out as its
  // variable, so a density moves it; a caller's own height stays as stated,
  // as on Flutter.
  final heightCss = merged.height == null
      ? controlHeightCss(sizeStyle.height!)
      : '${merged.height! / kRemDivisor}rem';
  final padding = merged.padding ?? sizeStyle.padding!;
  final contentGapStyle = sizeStyle.contentGapStyle!.merge(
    merged.contentGapStyle,
  );
  final borderRadius = merged.borderRadius ?? sizeStyle.borderRadius!;
  // The outline follows the border box, so on Web the corner the ring is
  // drawn on is the corner the element states. The trigger's own corner
  // outranks one a caller states for the ring, which outranks the size row's.
  final statedCorner =
      merged.borderRadius ?? merged.clickableStyle?.borderRadius;
  final leadingIconSlot = sizeStyle.leadingIconStyle!.merge(
    merged.leadingIconStyle,
  );
  final hintSlot = sizeStyle.hintTextStyle!.merge(merged.hintTextStyle);
  final face = enabled
      ? merged.backgroundColor ?? CoreCommandSearchStyle.defaultBackgroundColor
      : merged.disabledBackgroundColor ??
            CoreCommandSearchStyle.defaultDisabledBackgroundColor;
  final foreground =
      merged.foregroundColor ?? CoreCommandSearchStyle.defaultForegroundColor;
  final disabledForeground =
      merged.disabledForegroundColor ??
      CoreCommandSearchStyle.defaultDisabledForegroundColor;
  // A slot colour wins over the shared ink at rest; disabled takes the
  // disabled ink regardless, so a tinted glyph still reads as disabled.
  final leadingIconStyle = leadingIconSlot.copyWith(
    color: enabled ? leadingIconSlot.color ?? foreground : disabledForeground,
  );
  final hintStyle = hintSlot.copyWith(
    color: enabled ? hintSlot.color ?? foreground : disabledForeground,
  );
  // The ring follows the trigger's corner: the corner seeds the composed
  // `Clickable`'s default, and an explicit `clickableStyle` override still
  // wins over it — the chain the Flutter twin walks.
  final clickableStyle = CoreCommandSearchStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // ─── Stage 2 EMIT ─────────────────────────────────
  final faceEmit = emitColor(face, face, ColorTarget.background);
  // Default → the size row's preset classes; a stated corner → inline. The
  // box and the wash overlay share it, so the wash is not squared off.
  final radiusEmit = emitRadius(statedCorner, sizeStyle.borderRadius!);
  final hintEmit = emitTypography(hintStyle, hintStyle);

  // `display` is stated inline: the composed `Clickable` already names
  // `inline-flex`, Tailwind emits that after `flex`, and a `flex` class
  // beside it loses — the trigger would be an inline-level box.
  final rootRaw = <String, String>{
    'display': 'flex',
    'height': heightCss,
    ...padding.toLogicalDeclarations('padding'),
    ...?faceEmit.inline,
    ...?radiusEmit.inline,
  };

  final rootClassName =
      '$scopeClass relative w-full items-center text-start '
      'select-none ${faceEmit.className} ${radiusEmit.className}';
  final washClassName =
      '$_kCommandSearchWashMarker pointer-events-none absolute inset-0 '
      '${radiusEmit.className}';
  final hintClassName = 'min-w-0 flex-1 truncate ${hintEmit.className}';
  final washInline = radiusEmit.inline == null
      ? null
      : Styles(raw: radiusEmit.inline);
  final hintInline = hintEmit.inline == null
      ? null
      : Styles(raw: hintEmit.inline);

  return ResolvedCommandSearch(
    root: WebElementChrome(
      className: rootClassName,
      inlineStyles: Styles(raw: rootRaw),
    ),
    wash: WebElementChrome(
      className: washClassName,
      inlineStyles: washInline,
    ),
    hint: WebElementChrome(
      className: hintClassName,
      inlineStyles: hintInline,
    ),
    leadingIconStyle: leadingIconStyle,
    contentGapStyle: contentGapStyle,
    clickableStyle: clickableStyle,
  );
}

/// Resolves the wash rules for the trigger carrying [scopeClass].
///
/// Walks the same chain as [resolveCommandSearch] so a theme or instance
/// override of the ramp or the state-layer colour lands here too.
ResolvedCommandSearchRules resolveCommandSearchRules(
  BuildContext context, {
  required String scopeClass,
  bool enabled = true,
  CoreCommandSearchStyle? commandSearchStyle,
}) {
  if (!enabled) return const ResolvedCommandSearchRules(css: '');

  final searchTheme = context.theme.coreComponentTheme?.commandSearch;
  final merged = resolveStyleChain(const CoreCommandSearchStyle(), [
    searchTheme?.style,
    commandSearchStyle,
  ]);
  final stateLayerColor =
      merged.stateLayerColor ?? CoreCommandSearchStyle.defaultStateLayerColor;
  final stateLayer =
      merged.stateLayer ?? CoreCommandSearchStyle.defaultStateLayer;

  // Scoped by class, not id: the composed `Clickable` takes the element's id
  // for its own pseudo rules whenever a caller overrides the focus ring, and
  // a wash that silently stopped matching in that case would be a bug nobody
  // sees until someone restyles a ring.
  final trigger = '.$scopeClass';
  const wash = '.$_kCommandSearchWashMarker';
  final buffer = StringBuffer()
    ..write('$trigger:hover > $wash{background-color:')
    ..write(stateLayerColor.scaleAlpha(stateLayer.hover).toValue())
    ..write(';}')
    ..write('$trigger:focus-visible > $wash{background-color:')
    ..write(stateLayerColor.scaleAlpha(stateLayer.focus).toValue())
    ..write(';}')
    ..write('$trigger:active > $wash{background-color:')
    ..write(stateLayerColor.scaleAlpha(stateLayer.pressed).toValue())
    ..write(';}');
  return ResolvedCommandSearchRules(css: buffer.toString());
}
