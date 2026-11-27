import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform bottom sheet — the panel that rises from the
/// bottom of a phone screen: a title, a short line under it, the content,
/// and the actions that finish it.
///
/// Uses [CoreBottomSheetContract] from `coui_core`, so the Web `BottomSheet`
/// takes the same named properties. Anatomy, top to bottom:
/// `[ handle ] [ title · close ] [ description ] [ divider ] [ content ]
/// [ footer ]`. The sheet owns the arrangement, the padding and the filled
/// surface with its two rounded top corners; the [content] and the
/// [footer] (a `BottomActionBar` by convention) are the caller's own.
///
/// The sheet is the panel, not the presenter: it does not open, dim the
/// page or dismiss itself — [onClose] only reports the close button's
/// press. For a panel that slides in from an edge, see `Drawer`; on a phone
/// the bottom panel is this sheet.
///
/// The sheet is at most `maxHeightFactor` of the viewport's height. Past
/// that the content alone scrolls — the header stays at the top and the
/// footer stays pinned at the bottom, with the content clipped above it.
/// The footer's area paints no fill, and the hairline above it shows only
/// while more content lies below.
///
/// ```dart
/// BottomSheet(
///   title: Text('Sort by'),
///   showCloseButton: true,
///   onClose: () {},
///   content: OptionList(children: [...]),
///   footer: BottomActionBar(primaryAction: Button(child: Text('Apply'))),
/// )
/// ```
///
/// The Web `BottomSheet` shares the same parameter names and order.
///
/// surface:behind — a sheet rises over a page that scrolls beneath it.
///
/// surface:functional — the sheet groups a short task above the page.
class BottomSheet extends StatelessWidget
    implements CoreBottomSheetContract<Widget> {
  /// Creates a [BottomSheet].
  const BottomSheet({
    required this.title,
    super.key,
    this.description,
    this.content,
    this.footer,
    this.showHandle = CoreBottomSheetContract.defaultShowHandle,
    this.showCloseButton = CoreBottomSheetContract.defaultShowCloseButton,
    this.showDivider = CoreBottomSheetContract.defaultShowDivider,
    this.onClose,
    this.bottomSheetStyle,
  });

  @override
  final Widget title;

  @override
  final Widget? description;

  @override
  final Widget? content;

  @override
  final Widget? footer;

  @override
  final bool showHandle;

  @override
  final bool showCloseButton;

  @override
  final bool showDivider;

  @override
  final void Function()? onClose;

  @override
  final CoreBottomSheetStyle? bottomSheetStyle;

  /// Returns a copy of this sheet with the supplied non-null fields
  /// overridden.
  BottomSheet copyWith({
    Key? key,
    Widget? title,
    Widget? description,
    Widget? content,
    Widget? footer,
    bool? showHandle,
    bool? showCloseButton,
    bool? showDivider,
    void Function()? onClose,
    CoreBottomSheetStyle? bottomSheetStyle,
  }) {
    return BottomSheet(
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      footer: footer ?? this.footer,
      showHandle: showHandle ?? this.showHandle,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      showDivider: showDivider ?? this.showDivider,
      onClose: onClose ?? this.onClose,
      bottomSheetStyle: bottomSheetStyle ?? this.bottomSheetStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveBottomSheet(
      context,
      bottomSheetStyle: bottomSheetStyle,
    );

    Widget sheet = DecoratedBox(
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        borderRadius: resolved.borderRadius,
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          if (showHandle)
            Padding(
              padding: resolved.handlePadding,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: resolved.handleColor,
                    borderRadius: resolved.handleBorderRadius,
                  ),
                  child: SizedBox(
                    width: resolved.handleWidth,
                    height: resolved.handleHeight,
                  ),
                ),
              ),
            ),
          Padding(
            padding: resolved.headerPadding,
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                // The cross axis stays at the `Row` default, the centre, so
                // the 32-px close button and the title's line share a centre
                // line. The Web twin states `items-center` because a flex
                // row stretches by default.
                Row(
                  spacing: resolved.headerSpacing,
                  children: [
                    Expanded(
                      child: DefaultTextStyle(
                        style: resolved.titleTextStyle,
                        child: title,
                      ),
                    ),
                    if (showCloseButton)
                      Semantics(
                        button: true,
                        label: CoUILocalizations.of(context).dismissLabel,
                        child: Button(
                          onPressed: onClose,
                          variant: .plain,
                          size: .sm,
                          shape: .square,
                          buttonStyle: resolved.closeButtonStyle,
                          child: const Icon(LucideIcons.x),
                        ),
                      ),
                  ],
                ),
                if (description case final description?) ...[
                  Gap(gapStyle: resolved.titleGapStyle),
                  DefaultTextStyle(
                    style: resolved.descriptionTextStyle,
                    child: description,
                  ),
                ],
              ],
            ),
          ),
          if (showDivider) Divider(dividerStyle: resolved.dividerStyle),
          if (content != null || footer != null)
            // Without a known viewport the column is unbounded and a flex
            // child would throw; the body then sizes to its content.
            if (resolved.maxHeight.isFinite)
              Flexible(
                child: _BottomSheetBody(
                  resolved: resolved,
                  content: content,
                  footer: footer,
                  scrolls: true,
                ),
              )
            else
              _BottomSheetBody(
                resolved: resolved,
                content: content,
                footer: footer,
                scrolls: false,
              ),
        ],
      ),
    );

    // A fill-less sheet handed a material would stack a backdrop pass over
    // nothing, and a style with no material draws no pass at all — the
    // default tree is the plain box.
    final blur = resolved.surfaceBlur;
    if (((blur != null && blur > 0) || resolved.surfaceSheen != null) &&
        resolved.backgroundColor.a > 0) {
      sheet = SurfaceBlur(
        borderRadius: resolved.borderRadius,
        surfaceBlur: blur,
        surfaceSaturation: resolved.surfaceSaturation,
        surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
        surfaceSheen: resolved.surfaceSheen,
        // The active material's bend. Every surface that draws the material
        // draws all of it — the frost and the chroma without the bend is a
        // blurred panel, not glass.
        refraction: resolved.refraction,
        child: sheet,
      );
    }

    sheet = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: resolved.maxHeight),
      child: sheet,
    );

    return CoUISemantics(container: true, child: sheet);
  }
}

/// Scroll-end slack in logical px — sub-pixel offsets at the end of a
/// scroll would otherwise keep the hairline on. Not a design token: a
/// numeric tolerance, mirroring the Web twin's measurer.
const double _kScrollEndTolerance = 1;

/// The content's scroll view and the pinned footer. Detects whether more
/// content lies below the visible part and picks the resolver's footer
/// hairline for that state.
class _BottomSheetBody extends StatefulWidget {
  const _BottomSheetBody({
    required this.resolved,
    required this.content,
    required this.footer,
    required this.scrolls,
  });

  final ResolvedBottomSheet resolved;
  final Widget? content;
  final Widget? footer;

  /// Whether the body is height-bounded, so the content can scroll.
  final bool scrolls;

  @override
  State<_BottomSheetBody> createState() => _BottomSheetBodyState();
}

class _BottomSheetBodyState extends State<_BottomSheetBody> {
  final ScrollController _controller = ScrollController();
  bool _moreBelow = false;

  @override
  void initState() {
    super.initState();
    // The first layout's metrics: a sheet that opens already overflowing
    // shows the hairline without waiting for a scroll.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted || !_controller.hasClients) return;
    _handleMetrics(_controller.position);
  }

  void _handleMetrics(ScrollMetrics metrics) {
    final moreBelow = metrics.extentAfter > _kScrollEndTolerance;
    if (moreBelow != _moreBelow) setState(() => _moreBelow = moreBelow);
  }

  bool _handleNotification(Notification notification) {
    switch (notification) {
      // Only the sheet's own scroll view — a scrollable inside the content
      // reports at a deeper depth.
      case ScrollMetricsNotification(depth: 0, :final metrics):
        _handleMetrics(metrics);
      case ScrollUpdateNotification(depth: 0, :final metrics):
        _handleMetrics(metrics);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolved;
    final content = widget.content;
    final footer = widget.footer;
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        if (content != null)
          if (widget.scrolls)
            Flexible(
              child: NotificationListener<Notification>(
                onNotification: _handleNotification,
                child: SingleChildScrollView(
                  controller: _controller,
                  padding: resolved.contentPadding,
                  child: content,
                ),
              ),
            )
          else
            Padding(padding: resolved.contentPadding, child: content),
        if (footer != null)
          // Foreground, so the line takes no layout height: showing it never
          // moves the footer or changes the scroll extent.
          DecoratedBox(
            position: .foreground,
            decoration: BoxDecoration(
              border: Border(
                top: _moreBelow
                    ? resolved.footerOverflowBorder
                    : resolved.footerRestBorder,
              ),
            ),
            child: _FooterBarTheme(
              footerBarStyle: resolved.footerBarStyle,
              child: footer,
            ),
          ),
      ],
    );
  }
}

/// Installs the sheet's `BottomActionBar` theme style around the footer, so
/// a bar placed there resolves the sheet's action-area chrome. Any other
/// widget ignores the slot. Mirrors the Web twin.
class _FooterBarTheme extends StatelessWidget {
  const _FooterBarTheme({required this.footerBarStyle, required this.child});

  final CoreBottomActionBarStyle footerBarStyle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final components = theme.coreComponentTheme ?? const CoreComponentTheme();
    return Theme(
      data: theme.copyWith(
        coreComponentTheme: () => components.copyWith(
          bottomActionBar: CoreBottomActionBarTheme(style: footerBarStyle),
        ),
      ),
      child: child,
    );
  }
}

/// Chain sugar for merging a [CoreBottomSheetStyle] patch into
/// [BottomSheet.bottomSheetStyle] without hand-reconstructing every field.
/// Mirrors the Web `BottomSheet.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBottomSheetStyle.merge` right-side-wins semantics).
extension BottomSheetStyleChain on BottomSheet {
  /// Sets the background paint and preserves the other style fields.
  BottomSheet backgroundColor(CoreColor value) =>
      withStyle(CoreBottomSheetStyle(backgroundColor: value));

  /// Returns a copy of this [BottomSheet] with [patch] merged into
  /// [bottomSheetStyle] (patch fields win on conflict).
  BottomSheet withStyle(CoreBottomSheetStyle patch) => copyWith(
    bottomSheetStyle: (bottomSheetStyle ?? const CoreBottomSheetStyle()).merge(
      patch,
    ),
  );
}
