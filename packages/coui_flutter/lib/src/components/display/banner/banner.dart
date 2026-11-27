import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';

/// A unified banner component for important announcements or alerts.
///
/// Renders a full-bleed band with variant-based styling, a hairline
/// bottom rule on the `weak` emphasis, optional icon, dismiss button,
/// and action widget.
///
/// Per Epic #1302 / #1696 every chrome / dimensional / nested-slot
/// override flows through the single [bannerStyle] (a [CoreBannerStyle]).
/// The semantic enum (`variant`) and behaviour fields (`message` /
/// `description` / `action` / `onDismiss` / `showIcon`) stay flat on
/// the widget.
///
/// ```text
/// design system default for banner
///   → CoreBannerTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → widget.bannerStyle                     // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// Banner(
///   message: Text('Your session will expire in 5 minutes.'),
///   variant: CoreBannerVariant.warning,
///   onDismiss: () => setState(() => _show = false),
///   action: Button(
///     variant: CoreButtonVariant.outline,
///     onPressed: () => extendSession(),
///     child: Text('Extend'),
///   ),
/// )
/// ```
///
/// surface:behind — dismissible and full-width, commonly pinned atop
/// scrollable content as a top-of-page announcement the way a host shell
/// stacks `Dock` or `NavigationBar` over a scrolling body.
///
/// surface:content — a face in the page flow: what shows through it is
/// whatever content it announces over, not a parent panel.
class Banner extends StatelessWidget implements CoreBannerContract<Widget> {
  /// Creates a [Banner].
  const Banner({
    required this.message,
    this.description,
    this.variant = CoreBannerVariant.defaultVariant,
    this.emphasis = CoreBannerEmphasis.defaultEmphasis,
    this.onDismiss,
    this.action,
    this.showIcon = true,
    this.bannerStyle,
    super.key,
  });

  /// Creates an info banner.
  const Banner.info({
    required this.message,
    this.description,
    this.emphasis = CoreBannerEmphasis.defaultEmphasis,
    this.onDismiss,
    this.action,
    this.showIcon = true,
    this.bannerStyle,
    super.key,
  }) : variant = CoreBannerVariant.info;

  /// Creates a success banner.
  const Banner.success({
    required this.message,
    this.description,
    this.emphasis = CoreBannerEmphasis.defaultEmphasis,
    this.onDismiss,
    this.action,
    this.showIcon = true,
    this.bannerStyle,
    super.key,
  }) : variant = CoreBannerVariant.success;

  /// Creates a warning banner.
  const Banner.warning({
    required this.message,
    this.description,
    this.emphasis = CoreBannerEmphasis.defaultEmphasis,
    this.onDismiss,
    this.action,
    this.showIcon = true,
    this.bannerStyle,
    super.key,
  }) : variant = CoreBannerVariant.warning;

  /// Creates a destructive/error banner.
  const Banner.destructive({
    required this.message,
    this.description,
    this.emphasis = CoreBannerEmphasis.defaultEmphasis,
    this.onDismiss,
    this.action,
    this.showIcon = true,
    this.bannerStyle,
    super.key,
  }) : variant = CoreBannerVariant.destructive;

  @override
  final Widget message;

  @override
  final Widget? description;

  @override
  final CoreBannerVariant variant;

  @override
  final CoreBannerEmphasis emphasis;

  @override
  final VoidCallback? onDismiss;

  @override
  final Widget? action;

  /// Whether to show the default variant icon when no custom leading is given.
  @override
  final bool showIcon;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `titleStyle` / `descriptionStyle` / `iconStyle` /
  /// `actionButtonStyle` / `closeButtonStyle` slots. See
  /// [CoreBannerStyle] for the merge chain.
  @override
  final CoreBannerStyle? bannerStyle;

  /// Returns a copy of this [Banner] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Banner copyWith({
    Key? key,
    VoidCallback? onDismiss,
    Widget? message,
    Widget? description,
    CoreBannerVariant? variant,
    Widget? action,
    bool? showIcon,
    CoreBannerEmphasis? emphasis,
    CoreBannerStyle? bannerStyle,
  }) {
    return Banner(
      key: key ?? this.key,
      message: message ?? this.message,
      description: description ?? this.description,
      variant: variant ?? this.variant,
      emphasis: emphasis ?? this.emphasis,
      onDismiss: onDismiss ?? this.onDismiss,
      action: action ?? this.action,
      showIcon: showIcon ?? this.showIcon,
      bannerStyle: bannerStyle ?? this.bannerStyle,
    );
  }

  /// Maps each banner variant to its `LucideIcons` glyph. Mirrors
  /// `Alert._variantIconName` so the two surfaces share the same
  /// visual language (`info` / `circleCheck` / `triangleAlert` /
  /// `circleX`); banner-only `neutral` uses `bell` for a generic
  /// notification feel.
  IconName _variantIconName() {
    return switch (variant) {
      .neutral => LucideIcons.bell,
      .info => LucideIcons.info,
      .success => LucideIcons.circleCheck,
      .warning => LucideIcons.triangleAlert,
      .destructive => LucideIcons.circleX,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Single-entry-point resolve — encapsulates theme.coreComponentTheme
    // access and the nested-merge chain inside banner_style.dart.
    final resolved = resolveBanner(
      context,
      variant: variant,
      emphasis: emphasis,
      hasAction: action != null,
      bannerStyle: bannerStyle,
    );

    final padding = resolved.padding;
    final borderRadius = resolved.borderRadius;
    final borderWidth = resolved.borderWidth;

    return Semantics(
      container: true,
      label: CoUILocalizations.of(context).bannerLabel,
      // The bottom-only rule blocks composing
      // `OutlinedContainer` as this surface's outer box (that primitive
      // only expresses a uniform `Border.all`), so the active theme's
      // glass material is applied directly via `SurfaceBlur` instead —
      // the same widget `OutlinedContainer` itself delegates to, and the
      // pattern `Dock` already uses for its own asymmetric border.
      //
      // The style's contributed cast goes outside both, for the same
      // composition reason: `OutlinedContainer` would have handed it over
      // at rest. Outside the box rather than in the decoration, because the
      // material can leave this fill translucent.
      child: InjectedCast(
        shadows: resolved.boxShadow,
        borderRadius: borderRadius,
        child: SurfaceBlur(
          borderRadius: borderRadius,
          surfaceBlur: resolved.surfaceBlur,
          surfaceSaturation: resolved.surfaceSaturation,
          surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
          surfaceSheen: resolved.surfaceSheen,
          refraction: Theme.of(context).surfaceRefraction,
          child: Container(
            constraints: BoxConstraints(minHeight: resolved.minHeight),
            padding: padding,
            decoration: BoxDecoration(
              color: resolved.backgroundColor,
              // Bottom rule only, and only when this emphasis states one —
              // `solid` resolves `borderColor` to null and gets no border at
              // all. Zero also removes the rule: a zero-width solid BorderSide
              // is a Flutter hairline, not the zero-width CSS rule, and it
              // cannot be painted together with rounded corners.
              border: resolved.borderColor == null || borderWidth == 0
                  ? null
                  : Border(
                      bottom: .new(
                        color: resolved.borderColor!,
                        width: borderWidth,
                      ),
                    ),
              borderRadius: borderRadius,
            ),
            // The Row keeps Flutter's default centre cross-alignment on
            // purpose: with `minHeight` holding the band at a fixed 72, a
            // description-less banner would pin its content to the top and
            // leave dead space underneath if this were `start`.
            child: Row(
              children: [
                // `showIcon` is a widget-only behaviour flag — the theme
                // cannot override it (semantic / behaviour stays on the widget).
                // The icon leads the message column and the trailing group,
                // which share one wrapping line: when the trailing group
                // wraps it starts where the message text starts, not under
                // the icon, and the icon stays centred on the message block
                // rather than on both lines. Web wraps the same two items
                // with `flex-wrap` and hangs the icon off the message column.
                Expanded(
                  child: _BannerBody(
                    hasLeading: showIcon,
                    leadingGap: resolved.iconContentGap,
                    gap: resolved.contentTrailingGap,
                    contentMinWidth: resolved.contentMinWidth,
                    runSpacing: resolved.trailingRunSpacing,
                    children: [
                      if (showIcon)
                        Icon(_variantIconName(), iconStyle: resolved.iconStyle),
                      // Message + description. Banner provides both the
                      // variant tone and the surface-appropriate typography
                      // via DefaultTextStyle so a plain Text passed into the
                      // slot picks both up automatically. Web does the same
                      // with labelLarge + variant tone wrapper classes that
                      // flow through to Text's cascade-friendly build. The
                      // description slot uses bodySmall so the surface keeps
                      // a visible message versus description hierarchy.
                      Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .start,
                        children: [
                          DefaultTextStyle.merge(
                            style: resolved.titleTextStyle,
                            child: message,
                          ),
                          if (description != null) ...[
                            Gap(gapStyle: resolved.titleDescriptionGapStyle),
                            DefaultTextStyle.merge(
                              style: resolved.descriptionTextStyle,
                              child: description!,
                            ),
                          ],
                        ],
                      ),
                      if (action != null || onDismiss != null)
                        Row(
                          mainAxisSize: .min,
                          children: [
                            // A `Button` action gets the resolved action
                            // chrome merged UNDER its own `buttonStyle`, so
                            // the variant foreground reaches the label and
                            // the caller's fields still win. Any other widget
                            // passes through (asChild) — same shape as Web
                            // and as `Toast`.
                            if (action case final Button button)
                              button.copyWith(
                                buttonStyle:
                                    (button.variant == CoreButtonVariant.plain
                                            ? resolved.plainActionButtonStyle
                                            : resolved.actionButtonStyle)
                                        .merge(button.buttonStyle),
                              )
                            else
                              ?action,
                            // Dismiss button — a unified plain-variant
                            // Button. The plain variant owns the transparent
                            // fill / hover-fade, and the raw-forwarded
                            // closeButtonStyle slot supplies the full-round
                            // corner (circle on the square shape) / hover
                            // transition / variant foreground. The close
                            // glyph's colour is null so it inherits the
                            // button's foreground via the ambient IconTheme.
                            if (onDismiss != null) ...[
                              if (action != null)
                                Gap(gapStyle: resolved.contentDismissGapStyle),
                              Semantics(
                                label: CoUILocalizations.of(
                                  context,
                                ).dismissLabel,
                                child: Button(
                                  onPressed: onDismiss,
                                  variant: .plain,
                                  shape: .square,
                                  buttonStyle: resolved.closeButtonStyle,
                                  child: Icon(
                                    LucideIcons.x,
                                    iconStyle: resolved
                                        .closeButtonStyle
                                        .leadingIconStyle,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreBannerStyle] patch into
/// [Banner.bannerStyle] without hand-reconstructing every field. Mirrors
/// the Web `Banner.withStyle` extension so both platforms read
/// identically. Composition slots (`message` / `description` / `action`)
/// keep using the `Text(...).bodyMedium...` chain directly — this
/// extension only covers the [CoreBannerStyle] chrome slot.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBannerStyle.merge` right-side-wins semantics).
///
/// `.info`, `.success`, `.warning` select component options.
/// Use `backgroundColor(.primary)` to set the background explicitly.
extension BannerStyleChain on Banner {
  /// Sets the content padding.
  Banner contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreBannerStyle(padding: value));

  /// Sets the border color.
  Banner borderColor(CoreColor value) =>
      withStyle(CoreBannerStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  Banner borderWidth(double value) =>
      withStyle(CoreBannerStyle(borderWidth: value));

  /// Sets the content foreground color.
  Banner foregroundColor(CoreColor value) =>
      withStyle(CoreBannerStyle(foregroundColor: value));

  /// Sets the background paint and preserves the other style fields.
  Banner backgroundColor(CoreColor value) =>
      withStyle(CoreBannerStyle(backgroundColor: value));

  /// Returns a copy of this [Banner] with [patch] merged into
  /// [bannerStyle] (patch fields win on conflict).
  Banner withStyle(CoreBannerStyle patch) => copyWith(
    bannerStyle: (bannerStyle ?? const CoreBannerStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Banner get radius0 => withStyle(
    const CoreBannerStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Banner get radius2 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Banner get radius4 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Banner get radius6 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Banner get radius8 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Banner get radius10 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Banner get radius12 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Banner get radius14 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Banner get radius16 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Banner get radius20 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Banner get radius24 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Banner get radius28 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Banner get radius32 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Banner get radius36 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Banner get radius40 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Banner get radius48 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Banner get radius56 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Banner get radius64 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Banner get radius9999 => withStyle(
    const CoreBannerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Banner get primary => withStyle(
    const CoreBannerStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Banner get secondary => withStyle(
    const CoreBannerStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Banner get tertiary => withStyle(
    const CoreBannerStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Banner get surface => withStyle(
    const CoreBannerStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Banner get surfaceContainer => withStyle(
    const CoreBannerStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Banner get error => withStyle(
    const CoreBannerStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// Selects `variant: .success` using the component theme.
  Banner get success => copyWith(variant: .success);

  /// Selects `variant: .warning` using the component theme.
  Banner get warning => copyWith(variant: .warning);

  /// Selects `variant: .info` using the component theme.
  Banner get info => copyWith(variant: .info);

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Banner get outline => withStyle(
    const CoreBannerStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Banner get transparent =>
      withStyle(const CoreBannerStyle(backgroundColor: .transparent));
}

/// Lays out the banner's leading icon, its message column and its trailing
/// group (action + dismiss).
///
/// The icon (when [hasLeading]) takes its natural width, then [leadingGap];
/// the message column and the trailing group share what is left. The
/// trailing group keeps its natural width. While the message column can keep
/// [contentMinWidth] beside it (plus [gap]), both share one line: the column
/// takes the rest of the width and both are centred on the line, as the
/// former `Row` placed them. Otherwise the column takes the full width and
/// the trailing group moves to a line of its own, [runSpacing] below, at the
/// column's start edge — where the message text starts. The decision reads
/// what the children measure, never the banner's width against a breakpoint.
///
/// The icon is centred on the message column in both poses. On one line that
/// is the line's centre; once wrapped it is the message block's, not the
/// centre of the two lines together. The Web twin states the same rules with
/// `flex-wrap` (`flex: 1 1 <min>` beside `flex: 0 0 auto`) and an icon hung
/// off the message column's box.
class _BannerBody extends MultiChildRenderObjectWidget {
  const _BannerBody({
    required this.hasLeading,
    required this.leadingGap,
    required this.gap,
    required this.contentMinWidth,
    required this.runSpacing,
    required super.children,
  });

  final bool hasLeading;
  final double leadingGap;
  final double gap;
  final double contentMinWidth;
  final double runSpacing;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBannerBody(
    hasLeading: hasLeading,
    leadingGap: leadingGap,
    gap: gap,
    contentMinWidth: contentMinWidth,
    runSpacing: runSpacing,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderBannerBody renderObject,
  ) {
    renderObject
      ..hasLeading = hasLeading
      ..leadingGap = leadingGap
      ..gap = gap
      ..contentMinWidth = contentMinWidth
      ..runSpacing = runSpacing
      ..textDirection = Directionality.of(context);
  }
}

class _BannerBodyParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBannerBody extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BannerBodyParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BannerBodyParentData> {
  _RenderBannerBody({
    required bool hasLeading,
    required double leadingGap,
    required double gap,
    required double contentMinWidth,
    required double runSpacing,
    required TextDirection textDirection,
  }) : _hasLeading = hasLeading,
       _leadingGap = leadingGap,
       _gap = gap,
       _contentMinWidth = contentMinWidth,
       _runSpacing = runSpacing,
       _textDirection = textDirection;

  bool _hasLeading;
  bool get hasLeading => _hasLeading;
  set hasLeading(bool value) {
    if (value == _hasLeading) return;
    _hasLeading = value;
    markNeedsLayout();
  }

  double _leadingGap;
  double get leadingGap => _leadingGap;
  set leadingGap(double value) {
    if (value == _leadingGap) return;
    _leadingGap = value;
    markNeedsLayout();
  }

  double _gap;
  double get gap => _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _contentMinWidth;
  double get contentMinWidth => _contentMinWidth;
  set contentMinWidth(double value) {
    if (value == _contentMinWidth) return;
    _contentMinWidth = value;
    markNeedsLayout();
  }

  double _runSpacing;
  double get runSpacing => _runSpacing;
  set runSpacing(double value) {
    if (value == _runSpacing) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox? get _leading => _hasLeading ? firstChild : null;

  RenderBox? get _content {
    final first = firstChild;
    if (first == null) return null;
    return _hasLeading ? childAfter(first) : first;
  }

  RenderBox? get _trailing {
    final content = _content;
    return content == null ? null : childAfter(content);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BannerBodyParentData) {
      child.parentData = _BannerBodyParentData();
    }
  }

  /// The width the icon and its gap take off the front.
  double _leadingExtent() {
    final leading = _leading;
    return leading == null
        ? 0
        : leading.getMaxIntrinsicWidth(double.infinity) + _leadingGap;
  }

  /// Whether a trailing group of [trailingWidth] fits beside a message
  /// column of at least [_contentMinWidth] in [width].
  bool _sharesLine(double width, double trailingWidth) =>
      _contentMinWidth + _gap + trailingWidth <= width;

  @override
  double computeMinIntrinsicWidth(double height) {
    final content = _content?.getMinIntrinsicWidth(height) ?? 0;
    final trailing = _trailing?.getMinIntrinsicWidth(height) ?? 0;
    return _leadingExtent() + (content > trailing ? content : trailing);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final content = _content?.getMaxIntrinsicWidth(height) ?? 0;
    final trailing = _trailing;
    final rest = trailing == null
        ? content
        : content + _gap + trailing.getMaxIntrinsicWidth(height);
    return _leadingExtent() + rest;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _heightFor(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _heightFor(width);

  double _heightFor(double width) {
    final content = _content;
    if (content == null) return 0;
    final leadingHeight = _leading?.getMaxIntrinsicHeight(double.infinity) ?? 0;
    final rest = width - _leadingExtent();
    final trailing = _trailing;
    double max(double a, double b) => a > b ? a : b;
    if (trailing == null) {
      return max(content.getMaxIntrinsicHeight(rest), leadingHeight);
    }
    final trailingWidth = trailing.getMaxIntrinsicWidth(double.infinity);
    final trailingHeight = trailing.getMaxIntrinsicHeight(trailingWidth);
    if (_sharesLine(rest, trailingWidth)) {
      final contentHeight = content.getMaxIntrinsicHeight(
        rest - _gap - trailingWidth,
      );
      return max(max(contentHeight, trailingHeight), leadingHeight);
    }
    final block = max(content.getMaxIntrinsicHeight(rest), leadingHeight);
    return block + _runSpacing + trailingHeight;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final content = _content;
    final trailing = _trailing;
    final leading = _leading;
    final maxWidth = constraints.maxWidth;
    final rtl = _textDirection == TextDirection.rtl;
    Size measure(RenderBox child, BoxConstraints c) => dry
        ? child.getDryLayout(c)
        : (child..layout(c, parentUsesSize: true)).size;
    // [x] runs from the start edge for a box of [w]; mirrored for
    // right-to-left text.
    void place(RenderBox child, double x, double w, double y) {
      if (dry) return;
      (child.parentData! as _BannerBodyParentData).offset = Offset(
        rtl ? maxWidth - x - w : x,
        y,
      );
    }

    if (content == null) return constraints.smallest;
    final l = leading == null
        ? Size.zero
        : measure(leading, BoxConstraints(maxWidth: maxWidth));
    final start = leading == null ? 0.0 : l.width + _leadingGap;
    final rest = maxWidth - start;
    final t = trailing == null
        ? Size.zero
        : measure(trailing, BoxConstraints(maxWidth: rest));
    final oneLine = trailing == null || _sharesLine(rest, t.width);
    final contentWidth = trailing != null && oneLine
        ? rest - _gap - t.width
        : rest;
    final c = measure(content, BoxConstraints.tightFor(width: contentWidth));
    // The message block — the column, or the icon if it is taller — is what
    // the icon centres on. On one line the trailing group shares it.
    var line = c.height > l.height ? c.height : l.height;
    if (oneLine && t.height > line) line = t.height;
    place(content, start, contentWidth, (line - c.height) / 2);
    if (leading != null) place(leading, 0, l.width, (line - l.height) / 2);
    if (trailing == null) return constraints.constrain(Size(maxWidth, line));
    if (oneLine) {
      place(trailing, maxWidth - t.width, t.width, (line - t.height) / 2);
      return constraints.constrain(Size(maxWidth, line));
    }
    place(trailing, start, t.width, line + _runSpacing);
    return constraints.constrain(
      Size(maxWidth, line + _runSpacing + t.height),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
