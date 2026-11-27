import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;

/// Unified window panel — title bar + controls + content area.
///
/// Implements [CoreWindowPanelContract] so Web/Flutter callers share
/// the same API shape.
///
/// surface:functional — the window frame — the box a `Window` floats over
/// the desktop.
class WindowPanel extends StatelessWidget
    implements CoreWindowPanelContract<Widget> {
  /// Creates a [WindowPanel].
  const WindowPanel({
    super.key,
    this.title,
    this.child,
    this.actions,
    this.closable = true,
    this.minimizable = false,
    this.maximizable = false,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.isMinimized = false,
    this.onTitleBarDragStart,
    this.onTitleBarDragUpdate,
    this.onTitleBarDragEnd,
    this.onTitleBarDragCancel,
    this.onTitleBarDoubleTap,
    this.windowPanelStyle,
  });

  @override
  final Widget? title;

  @override
  final Widget? child;

  @override
  final Widget? actions;

  @override
  final bool closable;

  @override
  final bool minimizable;

  @override
  final bool maximizable;

  @override
  final CoreVoidCallback? onClose;

  @override
  final CoreVoidCallback? onMinimize;

  @override
  final CoreVoidCallback? onMaximize;

  @override
  final bool isMinimized;

  @override
  final CoreTitleBarDragStartCallback? onTitleBarDragStart;

  @override
  final CoreTitleBarDragUpdateCallback? onTitleBarDragUpdate;

  @override
  final CoreTitleBarDragEndCallback? onTitleBarDragEnd;

  @override
  final CoreTitleBarDragEndCallback? onTitleBarDragCancel;

  @override
  final CoreVoidCallback? onTitleBarDoubleTap;

  @override
  final CoreWindowPanelStyle? windowPanelStyle;

  /// Returns a copy of this [WindowPanel] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  WindowPanel copyWith({
    Key? key,
    Widget? title,
    Widget? actions,
    bool? closable,
    bool? minimizable,
    bool? maximizable,
    CoreVoidCallback? onClose,
    CoreVoidCallback? onMinimize,
    CoreVoidCallback? onMaximize,
    bool? isMinimized,
    CoreTitleBarDragStartCallback? onTitleBarDragStart,
    CoreTitleBarDragUpdateCallback? onTitleBarDragUpdate,
    CoreTitleBarDragEndCallback? onTitleBarDragEnd,
    CoreTitleBarDragEndCallback? onTitleBarDragCancel,
    CoreVoidCallback? onTitleBarDoubleTap,
    CoreWindowPanelStyle? windowPanelStyle,
    Widget? child,
  }) {
    return WindowPanel(
      key: key ?? this.key,
      title: title ?? this.title,
      actions: actions ?? this.actions,
      closable: closable ?? this.closable,
      minimizable: minimizable ?? this.minimizable,
      maximizable: maximizable ?? this.maximizable,
      onClose: onClose ?? this.onClose,
      onMinimize: onMinimize ?? this.onMinimize,
      onMaximize: onMaximize ?? this.onMaximize,
      isMinimized: isMinimized ?? this.isMinimized,
      onTitleBarDragStart: onTitleBarDragStart ?? this.onTitleBarDragStart,
      onTitleBarDragUpdate: onTitleBarDragUpdate ?? this.onTitleBarDragUpdate,
      onTitleBarDragEnd: onTitleBarDragEnd ?? this.onTitleBarDragEnd,
      onTitleBarDragCancel: onTitleBarDragCancel ?? this.onTitleBarDragCancel,
      onTitleBarDoubleTap: onTitleBarDoubleTap ?? this.onTitleBarDoubleTap,
      windowPanelStyle: windowPanelStyle ?? this.windowPanelStyle,
      child: child ?? this.child,
    );
  }

  /// Shrinks [outer] by the outer-border width ([shrink]) on the
  /// top-left / top-right corners so the title bar fits inside the outer
  /// window border without bleeding over the rounded edge.
  BorderRadiusGeometry _innerTopRadius(
    BorderRadiusGeometry outer,
    double shrink,
  ) {
    final resolved = outer.resolve(.ltr);
    double shrunken(double r) => r - shrink < 0 ? 0 : r - shrink;
    return BorderRadius.only(
      topLeft: .elliptical(
        shrunken(resolved.topLeft.x),
        shrunken(resolved.topLeft.y),
      ),
      topRight: .elliptical(
        shrunken(resolved.topRight.x),
        shrunken(resolved.topRight.y),
      ),
    );
  }

  Widget _buildTitleBar(
    BuildContext context,
    ResolvedWindowPanel style,
  ) {
    // Inner radius = outer radius - border width. Applied only to the top
    // corners so the title-bar background follows the container's rounded
    // inner edge instead of spilling as a square onto the outer border.
    final innerTopRadius = _innerTopRadius(
      style.borderRadius,
      style.containerBorderWidth,
    );
    final row = Container(
      padding: style.titleBarPadding,
      // No divider under the bar — its fill sets it apart from the content.
      decoration: BoxDecoration(
        color: style.titleBarColor,
        borderRadius: innerTopRadius,
      ),
      height: style.titleBarHeight,
      // The title bar is a drag affordance, not copyable content — keep
      // it out of any ancestor SelectionArea (CoUIApp wraps web apps in
      // one for browser-selection parity) the same way the Web twin
      // marks its title bar `select-none`.
      child: SelectionContainer.disabled(
        child: Row(
          children: [
            if (title != null)
              Expanded(
                child: DefaultTextStyle(
                  style: style.titleTextStyle,
                  overflow: .ellipsis,
                  maxLines: 1,
                  child: title!,
                ),
              )
            else
              const Spacer(),
            ?actions,
            _buildControls(context, style),
          ],
        ),
      ),
    );

    // Wrap the title bar row in the gesture handlers declared on the
    // contract. Only attach them when at least one callback is provided
    // so the panel stays fully passive (no hit-test cost) when used in
    // isolation (i.e. not inside a `Window`).
    final dragStart = onTitleBarDragStart;
    final dragUpdate = onTitleBarDragUpdate;
    final dragEnd = onTitleBarDragEnd;
    final dragCancel = onTitleBarDragCancel;
    final doubleTap = onTitleBarDoubleTap;
    final hasDragHandlers =
        dragStart != null ||
        dragUpdate != null ||
        dragEnd != null ||
        dragCancel != null;
    if (!hasDragHandlers && doubleTap == null) {
      return row;
    }

    Widget result = row;
    if (hasDragHandlers) {
      result = GestureDetector(
        onPanStart: dragStart == null
            ? null
            : (details) {
                dragStart(
                  CoreOffset(
                    details.localPosition.dx,
                    details.localPosition.dy,
                  ),
                  CoreOffset(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                  ),
                );
              },
        onPanUpdate: dragUpdate == null
            ? null
            : (details) {
                dragUpdate(
                  CoreOffset(details.delta.dx, details.delta.dy),
                  CoreOffset(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                  ),
                );
              },
        onPanEnd: dragEnd == null ? null : (_) => dragEnd(),
        onPanCancel: dragCancel,
        behavior: .translucent,
        child: result,
      );
    }
    if (doubleTap != null) {
      result = _TapCountDetector(
        onDoubleTap: doubleTap,
        child: result,
      );
    }
    return result;
  }

  /// Composes one control affordance via the unified `Button(variant:
  /// .plain)` + Lucide vector `Icon` (affordance rule — no hand-rolled
  /// `MouseRegion` + `GestureDetector`, no font glyph). Chrome flows
  /// through the resolved nested `CoreButtonStyle` slot; the icon
  /// inherits the button's per-state `IconTheme` foreground.
  Widget _buildControlButton(
    ResolvedWindowPanel style, {
    required CoreVoidCallback? onTap,
    required IconName icon,
    required String label,
    required CoreButtonStyle buttonStyle,
  }) {
    // Drawn at 20×20; the pointer target reaches the WCAG floor. At the
    // default control spacing the neighbouring floors meet in the gap
    // without overlapping.
    return TouchTarget(
      child: Semantics(
        button: true,
        label: label,
        child: Button(
          onPressed: onTap,
          variant: .plain,
          size: .sm,
          buttonStyle: buttonStyle,
          child: Icon(icon, iconStyle: style.controlIconStyle),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, ResolvedWindowPanel style) {
    // Native `Row.spacing` carries the inter-button spacing — no manual
    // `SizedBox` interleave (균등분포 rule per CLAUDE.md PART 1).
    //
    // The strip is at least the pointer floor tall so each button's
    // `TouchTarget` has room to reach above and below it — a `Row` only
    // hands a point down to a child when the point is inside the row.
    // The buttons stay centred and the title bar is taller still, so
    // nothing moves.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: CoreTouchTarget.minimum),
      child: Row(
        mainAxisSize: .min,
        spacing: style.controlSpacing,
        children: [
          if (minimizable)
            _buildControlButton(
              style,
              onTap: onMinimize,
              icon: LucideIcons.minus,
              label: CoUILocalizations.of(context).windowMinimize,
              buttonStyle: style.controlButtonStyle,
            ),
          if (maximizable)
            _buildControlButton(
              style,
              onTap: onMaximize,
              icon: LucideIcons.square,
              label: CoUILocalizations.of(context).windowMaximize,
              buttonStyle: style.controlButtonStyle,
            ),
          if (closable)
            _buildControlButton(
              style,
              onTap: onClose,
              icon: LucideIcons.x,
              label: CoUILocalizations.of(context).buttonClose,
              buttonStyle: style.closeButtonStyle,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveWindowPanel(
      context,
      windowPanelStyle: windowPanelStyle,
    );

    return Semantics(
      container: true,
      label: CoUILocalizations.of(context).windowLabel,
      // The frame's own shadow is painted on a `DecoratedBox` outside
      // the composed `OutlinedContainer` (see [ResolvedWindowPanel
      // .boxShadow]'s doc) — it needs the same `borderRadius` restated
      // so the shadow's silhouette curves to match the frame it sits
      // behind. `OutlinedContainer` owns the fill / border / (CSS
      // border-box parity) inset / material — the widget only composes
      // it (Epic #4349). Its own inner clip (border-minus-radius) is
      // what a manual `ClipRRect` at the same geometry used to do, so
      // children still land on the INNER rounded rect.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: resolved.borderRadius,
          boxShadow: resolved.boxShadow,
        ),
        // The style's rim over the frame — the composed container cannot
        // supply it, since it is handed an empty stack (see
        // [ResolvedWindowPanel.insetBoxShadow]). Empty, and so no wrapper,
        // under every style that states no rim.
        child: InsetShadow(
          shadows: resolved.insetBoxShadow,
          radius: resolved.insetRadius,
          child: OutlinedContainer(
            containerStyle: resolved.containerStyle,
            role: .functional,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = !isMinimized && child != null
                    ? Padding(
                        padding: resolved.contentPadding,
                        child: DefaultTextStyle.merge(
                          style: resolved.contentTextStyle,
                          child: child!,
                        ),
                      )
                    : null;
                return Column(
                  mainAxisSize: .min,
                  children: [
                    _buildTitleBar(context, resolved),
                    if (content != null)
                      // Web parity: the content area is `flex-1
                      // overflow-auto` and the frame fills its box only
                      // when the caller pins the height (`Window` passes
                      // `h-full` on Web / tight constraints here). Under
                      // a tight height the content fills the remaining
                      // space — stretched to at least the viewport so
                      // alignment widgets keep centring — and scrolls
                      // instead of overflowing; loose contexts keep
                      // intrinsic height like the Web panel without
                      // `h-full`.
                      if (constraints.hasTightHeight)
                        Flexible(
                          child: LayoutBuilder(
                            builder: (context, viewport) =>
                                SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: viewport.maxHeight,
                                    ),
                                    child: content,
                                  ),
                                ),
                          ),
                        )
                      else
                        content,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreWindowPanelStyle] patch into
/// [WindowPanel.windowPanelStyle] without hand-reconstructing every field.
/// Mirrors the Web `WindowPanel.withStyle` extension so both platforms read
/// identically. Composition slots (`title` / `child` / `actions`) keep
/// using their own widgets directly — this extension only covers the
/// [CoreWindowPanelStyle] chrome slot.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreWindowPanelStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` primitive — the
/// getter *name* is the token name, so `.radius4` always means
/// `CoreRadius.radius4`, no matter which component it's called on. That
/// fixed name-to-value mapping is what makes a short getter safe to
/// reuse across components — a curated nickname (`.rounded`, `.compact`)
/// would silently map to a different value per component, but a
/// primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreWindowPanelStyle.borderRadius]. A semantic layer that names
/// these after component-specific intent (decided together with design)
/// is a follow-up once more components adopt this pattern.
///
/// ```dart
/// WindowPanel(title: Text('Editor')).radius4
/// ```
extension WindowPanelStyleChain on WindowPanel {
  /// Sets the border color.
  WindowPanel borderColor(CoreColor value) =>
      withStyle(CoreWindowPanelStyle(borderColor: value));

  /// Returns a copy of this [WindowPanel] with [patch] merged into
  /// [windowPanelStyle] (patch fields win on conflict).
  WindowPanel withStyle(CoreWindowPanelStyle patch) => copyWith(
    windowPanelStyle: (windowPanelStyle ?? const CoreWindowPanelStyle()).merge(
      patch,
    ),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  WindowPanel get radius0 => withStyle(
    const CoreWindowPanelStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  WindowPanel get radius2 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  WindowPanel get radius4 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  WindowPanel get radius6 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  WindowPanel get radius8 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  WindowPanel get radius10 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  WindowPanel get radius12 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  WindowPanel get radius14 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  WindowPanel get radius16 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  WindowPanel get radius20 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  WindowPanel get radius24 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  WindowPanel get radius28 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  WindowPanel get radius32 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  WindowPanel get radius36 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  WindowPanel get radius40 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  WindowPanel get radius48 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  WindowPanel get radius56 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  WindowPanel get radius64 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  WindowPanel get radius9999 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}

/// Double-tap detection by counting single taps instead of registering a
/// [GestureDetector.onDoubleTap] recognizer.
///
/// A `DoubleTapGestureRecognizer` ancestor holds every descendant single
/// tap in the gesture arena for the double-tap timeout (~300ms) before it
/// resolves — the title bar's control buttons visibly lagged on every
/// press whenever the window was maximizable. Counting resolved tap-ups
/// keeps single taps instant (the reference implementation's
/// click-count detector works the same way), and taps on the control
/// buttons never reach this detector because the deeper button tap wins
/// the arena — so a quick minimize → restore double-press cannot
/// trigger maximize (Web `click`/`dblclick` fence parity).
class _TapCountDetector extends StatefulWidget {
  const _TapCountDetector({
    required this.onDoubleTap,
    required this.child,
  });

  final CoreVoidCallback onDoubleTap;
  final Widget child;

  @override
  State<_TapCountDetector> createState() => _TapCountDetectorState();
}

class _TapCountDetectorState extends State<_TapCountDetector> {
  DateTime? _lastTapUp;

  void handleTapUp(TapUpDetails details) {
    final now = DateTime.now();
    final last = _lastTapUp;
    if (last != null && now.difference(last) < kDoubleTapTimeout) {
      _lastTapUp = null;
      widget.onDoubleTap();
      return;
    }
    _lastTapUp = now;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: handleTapUp,
      behavior: .translucent,
      child: widget.child,
    );
  }
}

/// Private control button. Uses [MouseRegion] + [GestureDetector] so the
/// cursor becomes a pointer when the button is interactable — matching the
/// Web CSS `cursor-pointer` default.
