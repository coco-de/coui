import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `CardImage`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                   // outer flex container, click target
///   └─ OutlinedContainer(containerStyle)          // the card's box — composed
///        └─ body (<div>)                          // flex column inside the box
///             ├─ imageLayer (<div>)               // opacity — dims while disabled
///             │    └─ OutlinedContainer(frameStyle)  // image frame — composed, not hand-rolled
///             │         └─ image (<div>)          // transform: scale(...) — per-state hover
///             │              └─ caller-supplied <img>
///             ├─ Gap(imageContentGapStyle)        // only when a text slot is present
///             └─ textSlot (<div>)                 // opacity; only when title/subtitle/leading/trailing
///                  └─ Basic(contentStyle)
/// ```
///
/// All slot chromes are non-null — `co_card_image` decides whether to
/// render the optional `Gap` + `textSlot` based on instance state.
/// The `image` slot's transform value depends on the runtime hover
/// flag — [resolveCardImage] takes `hovered` as a parameter and
/// the widget re-invokes the resolver every build.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [imageContentGapStyle] is forwarded to
///   `Gap(gapStyle: …)`, [frameStyle] to `OutlinedContainer
///   (containerStyle: …)` — the frame is a composed unified component,
///   not a hand-rolled `<div>` (`core/style-contract.md`'s child-
///   component-composition rule), so it carries its own chrome slot
///   rather than `WebElementChrome` fields this resolver would have to
///   assemble.
///
/// No scalar metadata (direction / gap / etc.) is exposed —
/// semantic identifiers stay on the widget prop, structural choices
/// already live in the resolved class names.
class ResolvedCardImage implements WebResolvedChrome {
  /// Creates a [ResolvedCardImage].
  const ResolvedCardImage({
    required this.root,
    required this.containerStyle,
    required this.body,
    required this.imageLayer,
    required this.frameStyle,
    required this.image,
    required this.textSlot,
    required this.contentStyle,
    required this.imageContentGapStyle,
  });

  /// Paint-ready chrome for the outer flex container `<div>` —
  /// direction-driven flex classes plus `cursor-pointer` when
  /// `interactive` is true.
  @override
  final WebElementChrome root;

  /// Nested [CoreOutlinedContainerStyle] for the card's own box —
  /// raw-forwarded to the outer `OutlinedContainer(containerStyle: …)`.
  final CoreOutlinedContainerStyle containerStyle;

  /// Paint-ready chrome for the flex column inside the card's box —
  /// direction-driven flex classes (mirrors Flutter's `Flex`).
  final WebElementChrome body;

  /// Paint-ready chrome for the `<div>` around the image frame — the
  /// disabled `opacity` when the card is disabled, nothing otherwise.
  final WebElementChrome imageLayer;

  /// Nested [CoreBasicStyle] for the text row — raw-forwarded to
  /// `Basic(basicStyle: …)`.
  final CoreBasicStyle contentStyle;

  /// Nested [CoreOutlinedContainerStyle] for the image frame —
  /// raw-forwarded straight to `OutlinedContainer(containerStyle: …)`;
  /// that widget's own resolver owns border/radius/background emit (no
  /// className/inlineStyles assembly here).
  final CoreOutlinedContainerStyle frameStyle;

  /// Paint-ready chrome for the inner image wrapper `<div>` —
  /// `block leading-none transition-transform ease-in-out` className
  /// plus the `transform: scale(...)` and `transition-duration`
  /// inline-CSS bundle driven by the runtime hover flag.
  final WebElementChrome image;

  /// Paint-ready chrome for the text-slot wrapper `<div>` — a stretching
  /// `min-w-0` flex column, plus the disabled `opacity` when the card is
  /// disabled.
  final WebElementChrome textSlot;

  /// Nested [CoreGapStyle] for the image → text spacer — forwarded
  /// straight to `Gap(gapStyle: …)` by `co_card_image`. `co_card_image`
  /// renders the gap only when a text slot is present.
  final CoreGapStyle imageContentGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCardImage] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.cardImage.style
///   → widget.cardImageStyle
/// ```
///
/// [hovered] is the per-build hover state for the inner image wrapper
/// — the resolver bakes it into the `transform: scale(...)` inline
/// CSS using the resolved `hoverScale` / `normalScale` factors.
///
/// [disabled] is the card's semantic disabled state (`enabled: false`), the
/// same prop the Flutter twin's resolver takes.
ResolvedCardImage resolveCardImage(
  BuildContext context, {
  required bool interactive,
  required bool hovered,
  required bool disabled,
  CoreCardImageStyle? cardImageStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.cardImage;
  final merged = resolveStyleChain(const CoreCardImageStyle(), [
    coreTheme?.style,
    cardImageStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final effectiveDirection =
      merged.direction ?? CoreCardImageStyle.defaultDirection;
  // The image frame is a composed `OutlinedContainer`, so its chrome is
  // a single nested `CoreOutlinedContainerStyle` slot — raw-forwarded to
  // `OutlinedContainer(containerStyle: …)`, never assembled into
  // className / inline CSS here (`resolver/resolver-pattern.md`:
  // "resolver 는 자식 Style 을 조립하지 않는다").
  // A disabled card drops its cast: the disabled layer is laid over the
  // resolved box rather than replacing it.
  final restingContainerStyle = CoreCardImageStyle.defaultContainerStyle.merge(
    merged.containerStyle,
  );
  final containerStyle = disabled
      ? restingContainerStyle.merge(
          CoreCardImageStyle.defaultDisabledContainerStyle.merge(
            merged.disabledContainerStyle,
          ),
        )
      : restingContainerStyle;
  final frameStyle = CoreCardImageStyle.defaultFrameStyle.merge(
    merged.frameStyle,
  );
  final contentStyle = CoreCardImageStyle.defaultContentStyle.merge(
    merged.contentStyle,
  );
  final disabledContentOpacity =
      merged.disabledContentOpacity ??
      CoreCardImageStyle.defaultDisabledContentOpacity;
  final hoverScale = merged.hoverScale ?? CoreCardImageStyle.defaultHoverScale;
  final normalScale =
      merged.normalScale ?? CoreCardImageStyle.defaultNormalScale;
  // Hover scale transition duration — override wins, else the
  // design-system default (mirrors Flutter `AnimatedScale.duration`).
  // Epic #1603 coverage gate — `hoverDuration` is reflected here.
  final hoverDurationMs =
      (merged.hoverDuration ?? CoreCardImageStyle.defaultHoverDuration)
          .inMilliseconds;
  // Merge the design-system default `CoreGapStyle` with the
  // per-instance override — the resolved slot is forwarded straight
  // to `Gap(gapStyle: …)` by `co_card_image`.
  final imageContentGapStyle = CoreCardImageStyle.defaultImageContentGapStyle
      .merge(merged.imageContentGapStyle);
  final scale = hovered ? hoverScale : normalScale;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer `<div>` Tailwind className — a stretching flex
  /// column holding the card's box, `w-fit` (mirrors `mainAxisSize: min`),
  /// `select-none` and optional `cursor-pointer` when [interactive] is true.
  String buildRootClassName() => [
    WebLayout.flexColItemsStretch,
    WebLayout.wFit,
    if (interactive) 'cursor-pointer',
    'select-none',
  ].join(' ');

  /// Composes the body `<div>` Tailwind className — direction-driven flex
  /// (`flex flex-{row|col}`) + `items-stretch` (mirrors Flutter
  /// `crossAxisAlignment: stretch`, so the text slot fills the card).
  String buildBodyClassName() => effectiveDirection == .horizontal
      ? WebLayout.flexRowItemsStretch
      : WebLayout.flexColItemsStretch;

  /// The disabled `opacity` for the image layer and the text slot —
  /// nothing while enabled (mirrors Flutter's `Opacity(1)`).
  Styles? buildDimInlineStyles() =>
      disabled ? .new(raw: {'opacity': '$disabledContentOpacity'}) : null;

  /// Composes the inner image wrapper `<div>` Tailwind className —
  /// `block leading-none transition-transform`. Timing is emitted inline
  /// (see [buildImageInlineStyles]) rather than a bare `ease-in-out`
  /// class — that Tailwind class rides Tailwind's own built-in curve,
  /// not `CoreEasing.move`.
  String buildImageClassName() =>
      '${WebLayout.block} leading-none transition-transform';

  /// Composes the inner image wrapper `<div>` inline CSS — `transform`
  /// from the resolved scale factor + `transition-duration` /
  /// `transition-timing-function` (token-routed) from the resolved hover
  /// duration (mirrors Flutter `AnimatedScale.duration`).
  Styles buildImageInlineStyles() => .new(
    raw: {
      'transform': 'scale($scale)',
      'transition-duration': durationMsCss(hoverDurationMs),
      'transition-timing-function': CoreEasing.move.toVarCss(),
    },
  );

  /// Composes the text-slot `<div>` Tailwind className — a stretching flex
  /// column, so the `Basic` inside it is a flex item that fills the slot (a
  /// bare block would leave the inline-flex `Basic` at its content width and
  /// the trailing chevron right beside the text, not at the card's end);
  /// `min-w-0` so long titles wrap inside it.
  String buildTextSlotClassName() =>
      '${WebLayout.flexColItemsStretch} ${WebLayout.minWZero}';

  return ResolvedCardImage(
    root: WebElementChrome(className: buildRootClassName()),
    containerStyle: containerStyle,
    body: WebElementChrome(className: buildBodyClassName()),
    imageLayer: WebElementChrome(
      className: WebLayout.flexColItemsStretch,
      inlineStyles: buildDimInlineStyles(),
    ),
    frameStyle: frameStyle,
    image: WebElementChrome(
      className: buildImageClassName(),
      inlineStyles: buildImageInlineStyles(),
    ),
    textSlot: WebElementChrome(
      className: buildTextSlotClassName(),
      inlineStyles: buildDimInlineStyles(),
    ),
    contentStyle: contentStyle,
    imageContentGapStyle: imageContentGapStyle,
  );
}
