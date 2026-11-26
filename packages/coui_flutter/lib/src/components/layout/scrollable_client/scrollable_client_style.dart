import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [ScrollableClient].
class ResolvedScrollableClient {
  /// Creates a [ResolvedScrollableClient].
  const ResolvedScrollableClient({
    required this.diagonalDragBehavior,
    required this.overscroll,
    required this.clipBehavior,
    required this.hitTestBehavior,
    required this.keyboardDismissBehavior,
    required this.scrollbarThickness,
    required this.scrollbarRadius,
    required this.scrollbarColor,
    required this.scrollbarTrackColor,
    required this.showScrollbar,
    required this.focusOutlineStyle,
  });

  /// Effective diagonal drag behaviour (already folded widget/theme).
  final CoreDiagonalDragBehavior diagonalDragBehavior;

  /// Whether overscroll physics are enabled.
  final bool overscroll;

  /// Clip behaviour applied to the viewport.
  final Clip clipBehavior;

  /// Effective hit-test behaviour (already folded widget/theme).
  final CoreHitTestBehavior hitTestBehavior;

  /// Effective keyboard-dismiss behaviour (already folded widget/theme).
  final CoreKeyboardDismissBehavior keyboardDismissBehavior;

  /// Scrollbar thumb thickness (pixels).
  final double scrollbarThickness;

  /// Scrollbar thumb corner radius.
  final Radius scrollbarRadius;

  /// Scrollbar thumb colour as a `CoreColor` (raw-forwarded into
  /// `CoreScrollbarStyle`; `Scrollbar`'s resolver resolves it — no
  /// `CoreColor(color.toARGB32())` paint→domain round-trip in the widget).
  final CoreColor scrollbarColor;

  /// Scrollbar track colour as a `CoreColor` (raw-forwarded into
  /// `CoreScrollbarStyle.trackColor`; `Scrollbar`'s resolver resolves it).
  final CoreColor scrollbarTrackColor;

  /// Whether the design-system scrollbar is rendered. When `false` the
  /// `RawScrollbar` overlay is suppressed but the viewport still scrolls.
  final bool showScrollbar;

  /// Focus-ring chrome for the viewport, raw-forwarded into
  /// `FocusOutline` — its own resolver fills any field left unset.
  final CoreFocusOutlineStyle focusOutlineStyle;
}

/// Resolves [ResolvedScrollableClient] for [ScrollableClient].
///
/// Priority (per-field): widget value > `CoreScrollableClientContract`
/// design-system default. Behaviour scalars source their defaults from the
/// shared `CoreScrollableClientContract.defaultX` static consts; the scrollbar
/// chrome dimensions / colour fold the design-system default with the project
/// `CoreComponentTheme.scrollableClient.style` override.
ResolvedScrollableClient resolveScrollableClient(
  BuildContext context, {
  CoreDiagonalDragBehavior? diagonalDragBehavior,
  bool? overscroll,
  Clip? clipBehavior,
  CoreHitTestBehavior? hitTestBehavior,
  CoreKeyboardDismissBehavior? keyboardDismissBehavior,
  bool? showScrollbar,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.scrollableClient;

  // Fold the design-system default scrollbar style with the project
  // theme override so the thumb dimensions stay 1:1 with the Web
  // `::-webkit-scrollbar` skin.
  final merged = resolveStyleChain(const CoreScrollableClientStyle(), [
    coreTheme?.style,
  ]);

  // ─── Stage 1 RESOLVE — behaviour scalars (widget > Core default) ───
  final effectiveDiagonalDragBehavior =
      diagonalDragBehavior ??
      CoreScrollableClientContract.defaultDiagonalDragBehavior;
  final effectiveOverscroll =
      overscroll ?? CoreScrollableClientContract.defaultOverscroll;
  final effectiveClipBehavior = clipBehavior ?? .hardEdge;
  final effectiveHitTestBehavior =
      hitTestBehavior ?? CoreScrollableClientContract.defaultHitTestBehavior;
  final effectiveKeyboardDismissBehavior =
      keyboardDismissBehavior ??
      CoreScrollableClientContract.defaultKeyboardDismissBehavior;
  final effectiveShowScrollbar =
      showScrollbar ?? CoreScrollableClientContract.defaultShowScrollbar;

  // ─── Stage 1 RESOLVE — scrollbar chrome (merged > Core default) ───
  final scrollbarThickness =
      merged.scrollbarThickness ??
      CoreScrollableClientStyle.defaultScrollbarThickness;
  final scrollbarRadius =
      merged.scrollbarRadius ??
      CoreScrollableClientStyle.defaultScrollbarRadius;

  // ─── Stage 2 EMIT — scaled dimensionals ───
  // The scrollbar thumb colour is raw-forwarded as the design-system
  // `CoreColor` default — `Scrollbar`'s resolver resolves it through the
  // scheme (no double resolution / round-trip here).
  final scaledScrollbarThickness = theme.geometry.stroke(
    scrollbarThickness,
    scaling: scaling,
  );
  final scaledScrollbarRadius = Radius.circular(scrollbarRadius * scaling);
  final scrollbarColor =
      merged.scrollbarThumbColor ??
      CoreScrollableClientStyle.defaultScrollbarThumbColor;
  final scrollbarTrackColor =
      merged.scrollbarTrackColor ??
      CoreScrollableClientStyle.defaultScrollbarTrackColor;
  final focusOutlineStyle = CoreScrollableClientStyle.defaultFocusOutlineStyle
      .merge(merged.focusOutlineStyle);

  return ResolvedScrollableClient(
    diagonalDragBehavior: effectiveDiagonalDragBehavior,
    overscroll: effectiveOverscroll,
    clipBehavior: effectiveClipBehavior,
    hitTestBehavior: effectiveHitTestBehavior,
    keyboardDismissBehavior: effectiveKeyboardDismissBehavior,
    scrollbarThickness: scaledScrollbarThickness,
    scrollbarRadius: scaledScrollbarRadius,
    scrollbarColor: scrollbarColor,
    scrollbarTrackColor: scrollbarTrackColor,
    showScrollbar: effectiveShowScrollbar,
    focusOutlineStyle: focusOutlineStyle,
  );
}
