import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_fade.dart';

/// Unified cross-platform tooltip with token-based rendering.
///
/// Wraps a trigger [child] and shows a tooltip on pointer hover, driven
/// by the [Hover] widget for wait / show / min timing and the shared
/// [PopoverOverlayHandler] for overlay placement. There is no keyboard
/// focus or touch (long-press) trigger yet — see the component doc for
/// current platform coverage.
///
/// Per Epic #1302, all panel-chrome / dimensional / surface-effect
/// overrides flow through [tooltipStyle]
/// (`CoreTooltipStyle`). Semantic [position] stays as a top-level
/// widget parameter (원칙 6/7).
///
/// Example:
/// ```dart
/// Tooltip(
///   message: 'Add to favorites',
///   child: Button(
///     onPressed: () {},
///     leading: Icon(LucideIcons.heart),
///   ),
/// )
/// ```
///
/// surface:functional — the overlay positioner anchors it over whatever it
/// describes.
class Tooltip extends StatefulWidget implements CoreTooltipContract<Widget> {
  /// Creates a [Tooltip].
  const Tooltip({
    required this.child,
    this.message = '',
    this.tooltipChild,
    super.key,
    this.position = CoreTooltipPosition.top,
    this.waitDuration = CoreTooltipContract.defaultWaitDuration,
    this.showDuration = CoreTooltipContract.defaultShowDuration,
    this.minDuration,
    this.tooltipStyle,
  });

  @override
  final String message;

  @override
  final Widget? tooltipChild;

  @override
  final Widget child;

  @override
  final CoreTooltipPosition position;

  @override
  final Duration? waitDuration;

  @override
  final Duration? showDuration;

  @override
  final Duration? minDuration;

  @override
  final CoreTooltipStyle? tooltipStyle;

  /// Returns a copy of this [Tooltip] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Tooltip copyWith({
    Key? key,
    String? message,
    Widget? tooltipChild,
    CoreTooltipPosition? position,
    Duration? waitDuration,
    Duration? showDuration,
    Duration? minDuration,
    CoreTooltipStyle? tooltipStyle,
    Widget? child,
  }) {
    return Tooltip(
      key: key ?? this.key,
      message: message ?? this.message,
      tooltipChild: tooltipChild ?? this.tooltipChild,
      position: position ?? this.position,
      waitDuration: waitDuration ?? this.waitDuration,
      showDuration: showDuration ?? this.showDuration,
      minDuration: minDuration ?? this.minDuration,
      tooltipStyle: tooltipStyle ?? this.tooltipStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<Tooltip> createState() => _TooltipState();
}

/// Chain sugar for merging a [CoreTooltipStyle] patch into
/// [Tooltip.tooltipStyle] without hand-reconstructing every field. Mirrors
/// the Web `Tooltip.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTooltipStyle.merge` right-side-wins semantics).
extension TooltipStyleChain on Tooltip {
  /// Returns a copy of this [Tooltip] with [patch] merged into
  /// [tooltipStyle] (patch fields win on conflict).
  Tooltip withStyle(CoreTooltipStyle patch) => copyWith(
    tooltipStyle: (tooltipStyle ?? const CoreTooltipStyle()).merge(patch),
  );
}

class _TooltipState extends State<Tooltip> {
  // The unified popover overlay engine (the same one `Popover` uses),
  // called directly so the tooltip no longer routes through the deprecated
  // `OverlayManager` / `PopoverController`. Anchored overlays share one engine
  // (mirroring the Web `OverlayPositioner`).
  static const PopoverOverlayHandler _handler = PopoverOverlayHandler();

  PopoverEntryHandle<void>? _activeEntry;

  AlignmentGeometry get _alignment => switch (widget.position) {
    .top => Alignment.bottomCenter,
    .bottom => Alignment.topCenter,
    .left => Alignment.centerRight,
    .right => Alignment.centerLeft,
  };

  @override
  void dispose() {
    _activeEntry?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTooltip(
      context,
      tooltipStyle: widget.tooltipStyle,
    );

    // Surface opacity is a behaviour multiplier applied to the
    // paint-ready background colour at render time.
    var bgColor = resolved.backgroundColor;
    final effectiveOpacity = resolved.surfaceOpacity;
    if (effectiveOpacity != null) {
      bgColor = bgColor.withValues(alpha: effectiveOpacity);
    }
    final borderRadius = resolved.borderRadius;

    // Both content paths sit under the same label style. `merge` only
    // supplies defaults, so a `tooltipChild` that states its own colour
    // or size still wins — the child keeps owning its typography (the
    // Web twin says the same thing by putting the role + colour class on
    // the bubble, which the child inherits). What this stops is the
    // *unstyled* child falling through to the ambient app text style,
    // whose colour is the same `onSurface` token that fills the panel —
    // a 1.00:1 contrast that renders the child invisible.
    final tooltipContent = DefaultTextStyle.merge(
      style: resolved.labelTextStyle,
      child: widget.tooltipChild ?? Text(widget.message),
    );

    // Web twin: the panel `<div>` carries `role="tooltip"`. Flutter has
    // no floating-panel semantics node to mirror it onto, so the
    // closest cross-platform equivalent is exposing the message as the
    // trigger's semantic tooltip hint (omitted when a custom
    // `tooltipChild` replaces the plain message).
    return Semantics(
      container: true,
      tooltip: widget.tooltipChild == null && widget.message.isNotEmpty
          ? widget.message
          : null,
      child: Hover(
        minDuration: widget.minDuration,
        onHover: (hovered) {
          if (hovered) {
            if (_activeEntry != null) return;
            // The engine flips the bubble away from a viewport edge, and
            // the tail has to go with it or it points away from the
            // trigger. The flip is known only after layout, and this
            // overlay's subtree does not rebuild with this state, so the
            // side reaches the tail through a notifier the builder closes
            // over. Until the engine reports, the requested side stands.
            final requestedSide = widget.position;
            final tailSide = ValueNotifier(requestedSide);
            var tailSideDisposed = false;
            final entry = _handler.show<void>(
              alignment: _alignment,
              context: context,
              consumeOutsideTaps: false,
              dismissBackdropFocus: false,
              // A tooltip is positioned once on hover and does not track the
              // trigger every frame — `follow: true` keeps the engine ticker
              // running so the overlay never settles.
              follow: false,
              modal: false,
              onFlipResolved:
                  ({
                    required invertedHorizontally,
                    required invertedVertically,
                  }) {
                    if (tailSideDisposed) return;
                    tailSide.value = _resolvedTailSide(
                      requestedSide,
                      invertedHorizontally: invertedHorizontally,
                      invertedVertically: invertedVertically,
                    );
                  },
              builder: (context) {
                Widget bubble = Container(
                  padding: resolved.padding,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: borderRadius,
                  ),
                  child: tooltipContent,
                );
                // A width ceiling turns the bubble into a wrapping block —
                // `Text` already wraps once something bounds it, so the
                // constraint is the whole mechanism. Absent by default, so
                // tooltips stay on one line exactly as before.
                final maxWidth = resolved.panelMaxWidth;
                if (maxWidth != null) {
                  bubble = ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: bubble,
                  );
                }
                // Trigger-pointing tail — a painted triangle sharing the
                // bubble background, centred on the edge facing the
                // trigger and protruding into the placement gap (the Web
                // twin renders the same clip-path triangle).
                if (resolved.tailWidth > 0 && resolved.tailHeight > 0) {
                  bubble = Stacks(
                    clipBehavior: .none,
                    children: [
                      bubble,
                      Position.fill(
                        child: ValueListenableBuilder(
                          valueListenable: tailSide,
                          builder: (_, side, _) => _TooltipTail(
                            position: side,
                            color: bgColor,
                            baseWidth: resolved.tailWidth,
                            protrusion: resolved.tailHeight,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                final effectiveBlur = resolved.surfaceBlur;
                final panelBubble = bubble;
                // The active material's bend. Every surface that draws the
                // material draws all of it — the frost and the chroma without
                // the bend is a blurred panel, not glass, and the bend is the
                // term the material is named for.
                //
                // Falls back rather than being required: a style that states
                // no refraction leaves this null and the surface simply does
                // not bend, which is how every preset but glass renders.
                final refraction = Theme.of(context).surfaceRefraction;
                final hasMaterial =
                    (effectiveBlur != null && effectiveBlur > 0) ||
                    resolved.surfaceSheen != null;

                // The bubble as it is drawn at [fadeProgress] of the way in
                // view, or at rest where it is null — see
                // `SurfaceFadeAdopter`.
                Widget drawBubble(double? fadeProgress) => hasMaterial
                    ? SurfaceBlur(
                        borderRadius: borderRadius,
                        surfaceBlur: effectiveBlur,
                        surfaceSaturation: resolved.surfaceSaturation,
                        surfaceBackdropBrightness:
                            resolved.surfaceBackdropBrightness,
                        surfaceSheen: resolved.surfaceSheen,
                        refraction: refraction,
                        fadeProgress: fadeProgress,
                        child: panelBubble,
                      )
                    : panelBubble;

                // The bubble is the surface of the panel the engine is
                // fading, so it is offered the fade, whether or not it draws a
                // pass: an opaque bubble declines, and with it declining
                // nothing below it is asked.
                final fadeScope = SurfaceFadeScope.maybeOf(context);
                bubble = fadeScope == null
                    ? drawBubble(null)
                    : SurfaceFadeAdopter(
                        scope: fadeScope,
                        drawsPass: surfaceDrawsBackdropPass(
                          blur: effectiveBlur,
                          refraction: refraction,
                        ),
                        builder: drawBubble,
                      );
                return Padding(
                  padding: .all(resolved.gap),
                  child: bubble,
                );
              },
            );
            _activeEntry = entry;
            unawaited(
              entry.future.whenComplete(() {
                _activeEntry = null;
              }),
            );
            // Held until the close animation ends — the fading bubble
            // still listens to it.
            unawaited(
              entry.animationFuture.whenComplete(() {
                tailSideDisposed = true;
                tailSide.dispose();
              }),
            );
          } else {
            _activeEntry?.close();
          }
        },
        showDuration: widget.showDuration,
        waitDuration: widget.waitDuration,
        child: widget.child,
      ),
    );
  }
}

/// The side the bubble actually landed on, given the side it asked for and
/// the axes the overlay engine flipped it on.
///
/// Only the flip along the requested side's own axis moves the bubble to
/// the other side — a bubble above its trigger is centred horizontally, so
/// a horizontal flip leaves it above.
CoreTooltipPosition _resolvedTailSide(
  CoreTooltipPosition requested, {
  required bool invertedHorizontally,
  required bool invertedVertically,
}) {
  return switch (requested) {
    .top => invertedVertically ? .bottom : .top,
    .bottom => invertedVertically ? .top : .bottom,
    .left => invertedHorizontally ? .right : .left,
    .right => invertedHorizontally ? .left : .right,
  };
}

/// Positions the tail triangle on the bubble edge facing the trigger.
class _TooltipTail extends StatelessWidget {
  const _TooltipTail({
    required this.position,
    required this.color,
    required this.baseWidth,
    required this.protrusion,
  });

  final CoreTooltipPosition position;
  final Color color;
  final double baseWidth;
  final double protrusion;

  @override
  Widget build(BuildContext context) {
    // The bubble edge the tail sits on — opposite of the placement
    // side: a bubble above the trigger points down from its bottom.
    final vertical = position == .top || position == .bottom;
    final size = vertical
        ? Size(baseWidth, protrusion)
        : Size(protrusion, baseWidth);
    final tail = CustomPaint(
      painter: _TailPainter(position: position, color: color),
      size: size,
    );
    return switch (position) {
      .top => Align(
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: Offset(0, protrusion),
          child: tail,
        ),
      ),
      .bottom => Align(
        alignment: Alignment.topCenter,
        child: Transform.translate(
          offset: Offset(0, -protrusion),
          child: tail,
        ),
      ),
      .left => Align(
        alignment: Alignment.centerRight,
        child: Transform.translate(
          offset: Offset(protrusion, 0),
          child: tail,
        ),
      ),
      .right => Align(
        alignment: Alignment.centerLeft,
        child: Transform.translate(
          offset: Offset(-protrusion, 0),
          child: tail,
        ),
      ),
    };
  }
}

/// Paints the tail triangle — base flush against the bubble edge, tip
/// pointing away toward the trigger.
class _TailPainter extends CustomPainter {
  const _TailPainter({required this.position, required this.color});

  final CoreTooltipPosition position;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = switch (position) {
      // Bubble above the trigger — tip points down.
      .top =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height)
          ..close(),
      // Bubble below the trigger — tip points up.
      .bottom =>
        Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close(),
      // Bubble left of the trigger — tip points right.
      .left =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height)
          ..close(),
      // Bubble right of the trigger — tip points left.
      .right =>
        Path()
          ..moveTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height / 2)
          ..close(),
    };
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) =>
      oldDelegate.position != position || oldDelegate.color != color;
}
