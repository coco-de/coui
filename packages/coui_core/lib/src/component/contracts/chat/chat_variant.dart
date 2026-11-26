/// Variants for `ChatBubble`.
library;

import 'package:coui_core/src/shape/border_radius.dart';

/// Semantic colour variant of a chat bubble.
///
/// `neutral` is the default fallback. Other variants map to the design
/// system semantic palette (primary / secondary / accent / info / success /
/// warning / error) and let `Co{Chat,ChatBubble}` apply a contrasting
/// background colour without per-instance `Color` overrides.
enum CoreChatBubbleVariant {
  /// Surface-container-high-coloured bubble (default — neutral).
  neutral,

  /// `primary` filled bubble.
  primary,

  /// `secondary` filled bubble.
  secondary,

  /// `accent` filled bubble.
  accent,

  /// `info` filled bubble (semantic informational).
  info,

  /// `success` filled bubble (semantic positive).
  success,

  /// `warning` filled bubble (semantic warning).
  warning,

  /// `error` filled bubble (semantic destructive).
  error,

  /// Bubble without a fill: the words sit on the page itself. It draws no
  /// surface, no tail, no inner padding and may take the full row width.
  plain;

  /// Default variant on the `start` side — the one a bubble that states none
  /// takes there. The `end` side asks for `primary`
  /// (`CoreChatBubbleContract.defaultVariantFor`). Shared by the Flutter and
  /// Web `ChatBubble` so silent divergence cannot happen.
  static const CoreChatBubbleVariant defaultVariant = neutral;
}

/// Horizontal alignment of a chat row (`Chat`).
///
/// Maps onto Web `chat-start` / `chat-end` daisyUI classes and onto
/// Flutter `Column.crossAxisAlignment` + horizontal child positioning.
enum CoreChatAlignment {
  /// Align the chat row to the start (left in LTR, right in RTL).
  start,

  /// Align the chat row to the end (right in LTR, left in RTL).
  end;

  /// Widget default alignment — shared by Flutter and Web `Chat`
  /// constructors.
  static const CoreChatAlignment defaultAlignment = start;
}

/// The edge of a chat bubble its tail sits on.
///
/// The tail is the bubble's point back at its sender. A drawn pointer leaves
/// from this edge's corner on the alignment side, and a bubble with no
/// pointer can still mark that corner with
/// `CoreChatBubbleStyle.tailCornerRadius`.
///
/// `bottom` is the convention daisyUI and shadcn draw: the pointer leaves
/// after the last line. `top` points from where the message begins, toward
/// the avatar a chat row aligns to its top.
enum CoreChatBubbleTailEdge {
  /// The bubble's top edge.
  top,

  /// The bubble's bottom edge.
  bottom;

  /// [radius] with its tail corner — this edge, on the [alignment] side —
  /// replaced by [corner].
  ///
  /// Physical, like [CoreBorderRadius] itself: `end` is the right-hand
  /// corner, and a right-to-left page does not mirror it.
  CoreBorderRadius withTailCorner(
    CoreBorderRadius radius, {
    required CoreChatAlignment alignment,
    required double corner,
  }) {
    final onEnd = alignment == CoreChatAlignment.end;
    final onTop = this == CoreChatBubbleTailEdge.top;

    return CoreBorderRadius.only(
      topLeft: onTop && !onEnd ? corner : radius.topLeft,
      topRight: onTop && onEnd ? corner : radius.topRight,
      bottomLeft: !onTop && !onEnd ? corner : radius.bottomLeft,
      bottomRight: !onTop && onEnd ? corner : radius.bottomRight,
    );
  }
}
