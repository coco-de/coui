/// Platform-independent contract for chat components.
library;

import 'package:coui_core/src/component/contracts/chat/chat_style.dart';
import 'package:coui_core/src/component/contracts/chat/chat_variant.dart';

/// Contract for a single chat row (avatar + header + bubble + footer).
///
/// Renders one conversational message line in a chat thread. The
/// horizontal alignment is set by [alignment] (`start` for incoming
/// messages, `end` for outgoing). Slots (`avatar`, `header`, `footer`)
/// are optional; only [bubble] is mandatory.
///
/// The row hands its [alignment] to the [bubble] it holds: a
/// `ChatBubble` that states no `alignment`, `variant` or `tail` of its own
/// takes the row's side and the defaults that side implies
/// ([CoreChatBubbleContract.defaultVariantFor] /
/// [CoreChatBubbleContract.defaultTailFor]) — a message on the `end` side is
/// the sender's own, so it is a `primary` bubble with its tail on that side
/// unless the caller says otherwise.
///
/// Per Epic #1415 every chrome / dimensional override flows through
/// the single [chatStyle] slot — see [CoreChatStyle].
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreChatContract<W> {
  /// Required message bubble (typically a `ChatBubble`).
  W get bubble;

  /// Optional avatar shown next to the bubble.
  W? get avatar;

  /// Optional header (sender name, etc.) rendered above the bubble.
  W? get header;

  /// Optional footer (timestamp / delivery status) rendered below the
  /// bubble.
  W? get footer;

  /// Horizontal alignment of the chat row.
  CoreChatAlignment get alignment;

  /// Per-instance row chrome (avatar gap / header & footer text
  /// styles).
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// CoreChatStyle.defaultX
  ///   → CoreChatTheme.style
  ///   → parent component slot override
  ///   → widget.chatStyle
  /// ```
  CoreChatStyle? get chatStyle;
}

/// Contract for a chat bubble (the visual speech-bubble container that
/// holds the message text/content).
///
/// Per Epic #1415 every chrome / dimensional override flows through
/// the single [chatBubbleStyle] slot — see [CoreChatBubbleStyle].
///
/// Type parameters:
/// - [W] — platform widget type.
abstract interface class CoreChatBubbleContract<W> {
  /// 1-px overlap between the bubble edge and the tail pointer so no
  /// anti-aliasing seam shows between the two paints. Shared by the
  /// Flutter `Position` offset and the Web inline `left`/`right`
  /// offset — a single source so the attachment depth cannot silently
  /// diverge.
  static const double tailEdgeOverlap = 1;

  /// Default for [tail] on the `start` side: v2 bubbles carry no pointer.
  /// Shared by the Flutter and Web constructors (and the widgetbook knob) so
  /// the two platforms cannot disagree on whether an unspecified bubble has
  /// one. The `end` side asks for one — see [defaultTailFor].
  static const bool defaultTail = false;

  /// The [variant] a bubble takes when it states none, by the [alignment] it
  /// sits on.
  ///
  /// A chat thread tells the two senders apart by default: what the reader
  /// sent sits on the `end` side in the accent colour (`primary`), what was
  /// received sits on the `start` side in the neutral surface
  /// ([CoreChatBubbleVariant.defaultVariant]). Naming the variant on every
  /// bubble would make the distinction something each caller can forget; a
  /// bubble that does name one keeps it.
  ///
  /// One table both platforms read, so a `ChatBubble` cannot be `primary` on
  /// one and `neutral` on the other for the same row.
  static CoreChatBubbleVariant defaultVariantFor(CoreChatAlignment alignment) =>
      switch (alignment) {
        CoreChatAlignment.start => CoreChatBubbleVariant.defaultVariant,
        CoreChatAlignment.end => CoreChatBubbleVariant.primary,
      };

  /// The [tail] a bubble takes when it states none, by the [alignment] it
  /// sits on: the `end` side carries the pointer back at its sender, the
  /// `start` side keeps [defaultTail].
  static bool defaultTailFor(CoreChatAlignment alignment) =>
      switch (alignment) {
        CoreChatAlignment.start => defaultTail,
        CoreChatAlignment.end => true,
      };

  /// Bubble content (message text or composed widget).
  W get child;

  /// Semantic colour variant. `null` → [defaultVariantFor] the bubble's
  /// alignment.
  CoreChatBubbleVariant? get variant;

  /// Horizontal alignment of the bubble inside its parent row. Drives
  /// max-width factor application and (when the tail is drawn) the tail
  /// direction. `null` → the alignment of the `Chat` row the bubble sits in,
  /// else [CoreChatAlignment.defaultAlignment].
  CoreChatAlignment? get alignment;

  /// Whether to render the speech-bubble pointer (tail). `null` →
  /// [defaultTailFor] the bubble's alignment.
  ///
  /// Ignored when the bubble paints no fill (`plain`, or a transparent
  /// override): there is no surface for a tail to extend.
  bool? get tail;

  /// Per-instance bubble chrome / dimensional / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// CoreChatBubbleStyle.defaultX
  ///   → CoreChatBubbleStyle.defaultsByVariant[variant]
  ///   → CoreChatBubbleTheme.style
  ///   → CoreChatBubbleTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.chatBubbleStyle
  /// ```
  CoreChatBubbleStyle? get chatBubbleStyle;
}

/// Contract for a chat group — multiple consecutive bubbles from the
/// same sender rendered with a single avatar / header / footer.
///
/// Type parameters:
/// - [W] — platform widget type.
abstract interface class CoreChatGroupContract<W> {
  /// Ordered list of bubble widgets (typically `ChatBubble`s).
  List<W> get bubbles;

  /// Horizontal alignment of the group.
  CoreChatAlignment get alignment;

  /// Optional shared avatar (rendered once next to the group).
  W? get avatar;

  /// Optional shared header rendered above the first bubble.
  W? get header;

  /// Optional shared footer rendered below the last bubble.
  W? get footer;

  /// Per-instance group chrome (avatar gap / group spacing / header &
  /// footer text styles).
  CoreChatStyle? get chatStyle;
}
