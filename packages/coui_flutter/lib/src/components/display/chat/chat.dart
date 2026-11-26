import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';

// `Chat` publishes the scope and `ChatBubble` reads it; exporting it here makes
// it public with them, so a row of your own can hand its side to the bubble it
// holds the same way.
export 'chat_alignment_scope.dart';

/// Unified chat row — avatar + header + bubble + footer in a single
/// horizontally-aligned line.
///
/// `Chat` mirrors the Web daisyUI-style layout (chat-start / chat-end)
/// while resolving every chrome value through [CoreChatStyle]. The
/// only required slot is [bubble]; [avatar], [header], [footer] are
/// optional.
///
/// The row hands its [alignment] to the [bubble] it holds through
/// [ChatAlignmentScope]: a [ChatBubble] that states no `alignment`,
/// `variant` or `tail` takes the row's side and the defaults that side
/// implies — on the `end` side (the sender's own message) a `primary`
/// bubble with its tail on that side, on the `start` side the neutral bubble
/// with no tail. A bubble that states a value keeps it.
///
/// Example:
/// ```dart
/// Chat(
///   alignment: CoreChatAlignment.end,
///   avatar: Avatar(initials: 'M'),
///   header: Text('Minkai'),
///   bubble: ChatBubble(child: Text('Hello!')),
///   footer: Text('10:00 AM'),
/// )
/// ```
class Chat extends StatelessWidget implements CoreChatContract<Widget> {
  /// Creates a [Chat] row.
  const Chat({
    required this.bubble,
    super.key,
    this.alignment = CoreChatAlignment.defaultAlignment,
    this.avatar,
    this.header,
    this.footer,
    this.chatStyle,
  });

  @override
  final Widget bubble;

  @override
  final Widget? avatar;

  @override
  final Widget? header;

  @override
  final Widget? footer;

  @override
  final CoreChatAlignment alignment;

  @override
  final CoreChatStyle? chatStyle;

  /// Returns a copy of this [Chat] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Chat copyWith({
    Key? key,
    Widget? bubble,
    CoreChatAlignment? alignment,
    Widget? avatar,
    Widget? header,
    Widget? footer,
    CoreChatStyle? chatStyle,
  }) {
    return Chat(
      key: key ?? this.key,
      bubble: bubble ?? this.bubble,
      alignment: alignment ?? this.alignment,
      avatar: avatar ?? this.avatar,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      chatStyle: chatStyle ?? this.chatStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveChat(context, chatStyle: chatStyle);
    final isEnd = alignment == .end;
    final crossAxis = isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final column = Column(
      mainAxisSize: .min,
      crossAxisAlignment: crossAxis,
      children: [
        if (header != null)
          DefaultTextStyle.merge(
            style: resolved.headerTextStyle,
            child: header!,
          ),
        ChatAlignmentScope(alignment: alignment, child: bubble),
        if (footer != null)
          DefaultTextStyle.merge(
            style: resolved.footerTextStyle,
            child: footer!,
          ),
      ],
    );

    if (avatar == null) {
      return column;
    }

    final avatarSlot = Padding(
      padding: EdgeInsetsDirectional.only(
        start: isEnd ? resolved.avatarSpacing : 0,
        end: isEnd ? 0 : resolved.avatarSpacing,
      ),
      child: avatar,
    );

    return Row(
      mainAxisAlignment: isEnd ? .end : .start,
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      textDirection: Directionality.maybeOf(context),
      children: [
        if (!isEnd) avatarSlot,
        Flexible(child: column),
        if (isEnd) avatarSlot,
      ],
    );
  }
}

/// Chain sugar for merging a [CoreChatStyle] patch into
/// [Chat.chatStyle] without hand-reconstructing every field. Mirrors
/// the Web `Chat.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreChatStyle.merge` right-side-wins semantics).
extension ChatStyleChain on Chat {
  /// Returns a copy of this [Chat] with [patch] merged into [chatStyle]
  /// (patch fields win on conflict).
  Chat withStyle(CoreChatStyle patch) =>
      copyWith(chatStyle: (chatStyle ?? const CoreChatStyle()).merge(patch));
}

/// Unified chat group — multiple consecutive bubbles from the same
/// sender rendered with a single avatar / header / footer.
class ChatGroup extends StatelessWidget
    implements CoreChatGroupContract<Widget> {
  /// Creates a [ChatGroup].
  const ChatGroup({
    required this.bubbles,
    super.key,
    this.alignment = CoreChatAlignment.defaultAlignment,
    this.avatar,
    this.header,
    this.footer,
    this.chatStyle,
  });

  @override
  final List<Widget> bubbles;

  @override
  final CoreChatAlignment alignment;

  @override
  final Widget? avatar;

  @override
  final Widget? header;

  @override
  final Widget? footer;

  @override
  final CoreChatStyle? chatStyle;

  /// Returns a copy of this [ChatGroup] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ChatGroup copyWith({
    Key? key,
    List<Widget>? bubbles,
    CoreChatAlignment? alignment,
    Widget? avatar,
    Widget? header,
    Widget? footer,
    CoreChatStyle? chatStyle,
  }) {
    return ChatGroup(
      key: key ?? this.key,
      bubbles: bubbles ?? this.bubbles,
      alignment: alignment ?? this.alignment,
      avatar: avatar ?? this.avatar,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      chatStyle: chatStyle ?? this.chatStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveChat(context, chatStyle: chatStyle);
    final isEnd = alignment == .end;
    final crossAxis = isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    // Inter-bubble spacing flows through `Column.spacing` (Flutter
    // native paint-API arg) — no `Gap` interleave. The resolver
    // pre-applies scaling, so the widget reads `resolved.groupSpacing`
    // directly.
    final bubblesColumn = Column(
      mainAxisSize: .min,
      crossAxisAlignment: crossAxis,
      spacing: resolved.groupSpacing,
      children: bubbles,
    );

    final column = Column(
      mainAxisSize: .min,
      crossAxisAlignment: crossAxis,
      children: [
        if (header != null)
          DefaultTextStyle.merge(
            style: resolved.headerTextStyle,
            child: header!,
          ),
        bubblesColumn,
        if (footer != null)
          DefaultTextStyle.merge(
            style: resolved.footerTextStyle,
            child: footer!,
          ),
      ],
    );

    if (avatar == null) {
      return column;
    }

    final avatarSlot = Padding(
      padding: EdgeInsetsDirectional.only(
        start: isEnd ? resolved.avatarSpacing : 0,
        end: isEnd ? 0 : resolved.avatarSpacing,
      ),
      child: avatar,
    );

    return Row(
      mainAxisAlignment: isEnd ? .end : .start,
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      textDirection: Directionality.maybeOf(context),
      children: [
        if (!isEnd) avatarSlot,
        Flexible(child: column),
        if (isEnd) avatarSlot,
      ],
    );
  }
}

/// Chain sugar for merging a [CoreChatStyle] patch into
/// [ChatGroup.chatStyle] without hand-reconstructing every field. Mirrors
/// the Web `ChatGroup.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreChatStyle.merge` right-side-wins semantics).
extension ChatGroupStyleChain on ChatGroup {
  /// Returns a copy of this [ChatGroup] with [patch] merged into
  /// [chatStyle] (patch fields win on conflict).
  ChatGroup withStyle(CoreChatStyle patch) =>
      copyWith(chatStyle: (chatStyle ?? const CoreChatStyle()).merge(patch));
}

/// Unified speech-bubble component used by [Chat] / [ChatGroup].
///
/// A bubble that states no [alignment] sits on the side of the [Chat] row it is
/// in (see [ChatAlignmentScope]), and one that states no [variant] or [tail]
/// takes the defaults that side implies
/// (`CoreChatBubbleContract.defaultVariantFor` / `defaultTailFor`) — `primary`
/// with a tail on the `end` side, the neutral bubble with none on the `start`
/// side. A bubble that states a value keeps it.
///
/// surface:behind — whatever the message column sits over (a chat
/// screen's scrolling body). It draws its own box rather than composing
/// `OutlinedContainer` — its concave tail path is cut against the same
/// fill, a shape the container has no slot for (#4358) — so the marker
/// is restated here directly.
///
/// surface:content — a face in the content layer alongside the messages
/// around it, not a floating affordance: no sticky, fixed, or overlay
/// mount on either platform.
class ChatBubble extends StatelessWidget
    implements CoreChatBubbleContract<Widget> {
  /// Creates a [ChatBubble].
  const ChatBubble({
    required this.child,
    super.key,
    this.variant,
    this.alignment,
    this.tail,
    this.chatBubbleStyle,
  });

  @override
  final Widget child;

  @override
  final CoreChatBubbleVariant? variant;

  @override
  final CoreChatAlignment? alignment;

  @override
  final bool? tail;

  @override
  final CoreChatBubbleStyle? chatBubbleStyle;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveChatBubble(
      context,
      variant: variant,
      alignment: alignment,
      tail: tail,
      chatBubbleStyle: chatBubbleStyle,
    );

    // Variant foreground colour is the base; the resolved paint-ready
    // text style (role + explicit overrides) layers on top — an
    // explicit override colour wins, else the variant foreground.
    final baseTextStyle = TextStyle(color: resolved.foregroundColor);
    final content = Padding(
      padding: resolved.padding,
      child: DefaultTextStyle.merge(
        style: baseTextStyle.merge(resolved.textStyle),
        child: child,
      ),
    );

    Widget bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        borderRadius: resolved.borderRadius,
      ),
      child: content,
    );

    // The rest of the material, around the body only. The backdrop pass and
    // the edge light are bounded by the body's own corners, so the tail —
    // drawn outside this box — keeps the fill share it already folds and no
    // frost, which is what the Web twin's tail gets too. Wrapped only when
    // the style states something to draw, so every other style keeps the
    // tree it had.
    final effectiveBlur = resolved.surfaceBlur;
    if ((effectiveBlur != null && effectiveBlur > 0) ||
        resolved.surfaceSheen != null) {
      bubble = SurfaceBlur(
        borderRadius: resolved.borderRadius,
        surfaceBlur: effectiveBlur,
        surfaceSaturation: resolved.surfaceSaturation,
        surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
        surfaceSheen: resolved.surfaceSheen,
        // The active material's bend — the frost without it is a blurred
        // pane, not glass. Null under every style that states none.
        refraction: Theme.of(context).surfaceRefraction,
        child: bubble,
      );
    }

    if (resolved.tail) {
      // Tail pointer sticking out sideways from the bubble's corner on the
      // tail edge, alignment side, its outer edge flush with that edge
      // (shadcn_flutter tail convention, mirrored for a top tail). Negative
      // offset keeps the tail attached to the bubble edge with a 1-px
      // overlap so no anti-aliasing seam shows
      // (see `CoreChatBubbleContract.tailEdgeOverlap`).
      final isEnd = resolved.alignment == .end;
      final onTop = resolved.tailEdge == .top;
      final tailLeftRight =
          -resolved.tailWidth + CoreChatBubbleContract.tailEdgeOverlap;
      bubble = Stacks(
        clipBehavior: .none,
        children: [
          bubble,
          Position(
            top: onTop ? 0 : null,
            right: isEnd ? tailLeftRight : null,
            bottom: onTop ? null : 0,
            left: isEnd ? null : tailLeftRight,
            child: CustomPaint(
              painter: _ChatTailPainter(
                color: resolved.backgroundColor,
                tipRadius: resolved.tailTipRadius,
                pointEnd: isEnd,
                pointUp: onTop,
              ),
              size: Size(resolved.tailWidth, resolved.tailHeight),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth * resolved.maxWidthFactor
            : double.infinity;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: bubble,
        );
      },
    );
  }
}

/// Speech-bubble tail mirroring shadcn_flutter's tail painter — a
/// right triangle sticking out sideways from the bubble's bottom
/// corner on the alignment side. The bubble-side edge spans the full
/// tail height, the bottom edge is flush with the bubble's bottom,
/// the hypotenuse sweeps down-outward from the top, and the outward
/// tip on the bottom corner is rounded by [tipRadius] (quadratic arc)
/// so it never ends in a needle-sharp point. [pointUp] mirrors it for a
/// tail on the top edge: the top edge is flush with the bubble's top and
/// the tip is the top corner. Same path the Web twin clips.
class _ChatTailPainter extends CustomPainter {
  const _ChatTailPainter({
    required this.color,
    required this.tipRadius,
    required this.pointEnd,
    required this.pointUp,
  });

  final Color color;
  final double tipRadius;
  final bool pointEnd;

  /// Whether the tail sits on the bubble's top edge — the bottom-edge
  /// outline reflected across the tail's own horizontal centre line.
  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = .fill;
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = tipRadius;
    // Where the rounded tip rejoins the hypotenuse — `r` back from the
    // tip along the hypotenuse direction.
    final hypotenuse = sqrt(w * w + h * h);
    final backX = r * w / hypotenuse;
    final backY = r * h / hypotenuse;
    // The bottom-edge outline, reflected for a top tail.
    double y(double v) => pointUp ? h - v : v;
    if (pointEnd) {
      // Tip on the bottom-right (top-right when [pointUp]); the left
      // edge hugs the bubble's right side.
      path
        ..moveTo(0, y(0))
        ..lineTo(w - backX, y(h - backY))
        ..quadraticBezierTo(w, y(h), w - r, y(h))
        ..lineTo(0, y(h))
        ..close();
    } else {
      // Tip on the bottom-left (top-left when [pointUp]); the right
      // edge hugs the bubble's left side.
      path
        ..moveTo(w, y(0))
        ..lineTo(backX, y(h - backY))
        ..quadraticBezierTo(0, y(h), r, y(h))
        ..lineTo(w, y(h))
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChatTailPainter oldDelegate) =>
      color != oldDelegate.color ||
      tipRadius != oldDelegate.tipRadius ||
      pointEnd != oldDelegate.pointEnd ||
      pointUp != oldDelegate.pointUp;
}
