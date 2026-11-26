/// Web implementation of the unified chat components — `Chat`,
/// `ChatGroup`, and `ChatBubble`. Mirrors the Flutter API so that
/// the same source code reads identically on both platforms.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/chat/chat_alignment_scope.dart';
import 'package:coui_web/src/components/display/chat/chat_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

// `Chat` publishes the scope and `ChatBubble` reads it; exporting it here makes
// it public with them, so a row of your own can hand its side to the bubble it
// holds the same way.
export 'chat_alignment_scope.dart';

/// Unified chat row — `Chat` mirrors the Flutter side.
///
/// The row hands its [alignment] to the [bubble] it holds through
/// [ChatAlignmentScope]: a [ChatBubble] that states no `alignment`,
/// `variant` or `tail` takes the row's side and the defaults that side
/// implies — on the `end` side (the sender's own message) a `primary`
/// bubble with its tail on that side, on the `start` side the neutral bubble
/// with no tail. A bubble that states a value keeps it.
class Chat extends UiComponent implements CoreChatContract<Component> {
  /// Creates a [Chat] row.
  const Chat({
    required this.bubble,
    super.key,
    this.alignment = CoreChatAlignment.defaultAlignment,
    this.avatar,
    this.header,
    this.footer,
    this.chatStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component bubble;

  @override
  final Component? avatar;

  @override
  final Component? header;

  @override
  final Component? footer;

  @override
  final CoreChatAlignment alignment;

  @override
  final CoreChatStyle? chatStyle;

  @override
  Chat copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? bubble,
    CoreChatAlignment? alignment,
    Component? avatar,
    Component? header,
    Component? footer,
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
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveChat(
      context,
      alignment: alignment,
      chatStyle: chatStyle,
    );
    final isEnd = alignment == .end;
    final avatarSlot = avatar;

    final column = div(
      [
        if (header case final h?)
          div(
            [h],
            classes: resolved.header.className,
            styles: resolved.header.inlineStyles,
          ),
        ChatAlignmentScope(alignment: alignment, child: bubble),
        if (footer case final f?)
          div(
            [f],
            classes: resolved.footer.className,
            styles: resolved.footer.inlineStyles,
          ),
      ],
      classes: resolved.column.className,
    );

    final children = <Component>[];
    if (avatarSlot != null && !isEnd) {
      children.add(
        div(
          [avatarSlot],
          classes: resolved.avatarWrapper.className,
          styles: resolved.avatarWrapper.inlineStyles,
        ),
      );
    }
    children.add(column);
    if (avatarSlot != null && isEnd) {
      children.add(
        div(
          [avatarSlot],
          classes: resolved.avatarWrapper.className,
          styles: resolved.avatarWrapper.inlineStyles,
        ),
      );
    }

    return div(
      children,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
    );
  }
}

/// Chain sugar mirroring the Flutter `Chat.withStyle` extension —
/// merges a [CoreChatStyle] patch into [Chat.chatStyle] via the
/// existing [Chat.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreChatStyle.merge` right-side-wins semantics).
extension ChatStyleChain on Chat {
  /// Returns a copy of this [Chat] with [patch] merged into [chatStyle]
  /// (patch fields win on conflict).
  Chat withStyle(CoreChatStyle patch) =>
      copyWith(chatStyle: (chatStyle ?? const CoreChatStyle()).merge(patch));
}

/// Unified chat group — `ChatGroup` mirrors the Flutter side.
class ChatGroup extends UiComponent
    implements CoreChatGroupContract<Component> {
  /// Creates a [ChatGroup].
  const ChatGroup({
    required this.bubbles,
    super.key,
    this.alignment = CoreChatAlignment.defaultAlignment,
    this.avatar,
    this.header,
    this.footer,
    this.chatStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final List<Component> bubbles;

  @override
  final CoreChatAlignment alignment;

  @override
  final Component? avatar;

  @override
  final Component? header;

  @override
  final Component? footer;

  @override
  final CoreChatStyle? chatStyle;

  @override
  ChatGroup copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    List<Component>? bubbles,
    CoreChatAlignment? alignment,
    Component? avatar,
    Component? header,
    Component? footer,
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
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveChat(
      context,
      alignment: alignment,
      chatStyle: chatStyle,
    );
    final isEnd = alignment == .end;
    final avatarSlot = avatar;

    // Inter-bubble spacing flows through the `bubblesColumn` wrapper's
    // native flex `gap` CSS rule (baked into
    // `resolved.bubblesColumn.inlineStyles`) — no separator element
    // interleaved between bubbles. Parity with Flutter `Column.spacing`.
    final bubblesColumn = div(
      bubbles,
      classes: resolved.bubblesColumn.className,
      styles: resolved.bubblesColumn.inlineStyles,
    );

    final column = div(
      [
        if (header case final h?)
          div(
            [h],
            classes: resolved.header.className,
            styles: resolved.header.inlineStyles,
          ),
        bubblesColumn,
        if (footer case final f?)
          div(
            [f],
            classes: resolved.footer.className,
            styles: resolved.footer.inlineStyles,
          ),
      ],
      classes: resolved.column.className,
    );

    final children = <Component>[];
    if (avatarSlot != null && !isEnd) {
      children.add(
        div(
          [avatarSlot],
          classes: resolved.avatarWrapper.className,
          styles: resolved.avatarWrapper.inlineStyles,
        ),
      );
    }
    children.add(column);
    if (avatarSlot != null && isEnd) {
      children.add(
        div(
          [avatarSlot],
          classes: resolved.avatarWrapper.className,
          styles: resolved.avatarWrapper.inlineStyles,
        ),
      );
    }

    return div(
      children,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
    );
  }
}

/// Chain sugar mirroring the Flutter `ChatGroup.withStyle` extension —
/// merges a [CoreChatStyle] patch into [ChatGroup.chatStyle] via the
/// existing [ChatGroup.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreChatStyle.merge` right-side-wins semantics).
extension ChatGroupStyleChain on ChatGroup {
  /// Returns a copy of this [ChatGroup] with [patch] merged into
  /// [chatStyle] (patch fields win on conflict).
  ChatGroup withStyle(CoreChatStyle patch) =>
      copyWith(chatStyle: (chatStyle ?? const CoreChatStyle()).merge(patch));
}

/// Unified chat bubble — `ChatBubble` mirrors the Flutter side.
///
/// A bubble that states no [alignment] sits on the side of the [Chat] row it is
/// in (see [ChatAlignmentScope]), and one that states no [variant] or [tail]
/// takes the defaults that side implies
/// (`CoreChatBubbleContract.defaultVariantFor` / `defaultTailFor`) — `primary`
/// with a tail on the `end` side, the neutral bubble with none on the `start`
/// side. A bubble that states a value keeps it.
///
/// surface:behind — whatever the message column sits over. It draws its
/// own box rather than composing `OutlinedContainer` — its concave tail
/// path is cut against the same fill, a shape the container has no slot
/// for (#4358) — so the marker is restated here directly.
///
/// surface:content — a face in the content layer alongside the messages
/// around it, not a floating affordance: no sticky, fixed, or overlay
/// mount.
class ChatBubble extends UiComponent
    implements CoreChatBubbleContract<Component> {
  /// Creates a [ChatBubble].
  const ChatBubble({
    required this.child,
    super.key,
    this.variant,
    this.alignment,
    this.tail,
    this.chatBubbleStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component child;

  @override
  final CoreChatBubbleVariant? variant;

  @override
  final CoreChatAlignment? alignment;

  @override
  final bool? tail;

  @override
  final CoreChatBubbleStyle? chatBubbleStyle;

  @override
  ChatBubble copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    CoreChatBubbleVariant? variant,
    CoreChatAlignment? alignment,
    bool? tail,
    CoreChatBubbleStyle? chatBubbleStyle,
    Component? child,
  }) {
    return ChatBubble(
      key: key ?? this.key,
      variant: variant ?? this.variant,
      alignment: alignment ?? this.alignment,
      tail: tail ?? this.tail,
      chatBubbleStyle: chatBubbleStyle ?? this.chatBubbleStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveChatBubble(
      context,
      variant: variant,
      alignment: alignment,
      tail: tail,
      chatBubbleStyle: chatBubbleStyle,
    );

    final attrs = componentAttributes.isEmpty ? null : componentAttributes;
    final evts = events.isEmpty ? null : events;

    final wrapper = resolved.wrapper;
    final tailChrome = resolved.tail;
    if (wrapper == null || tailChrome == null) {
      return div(
        [child],
        id: id,
        classes: rootClasses(resolved.root.className),
        styles: css != null
            ? Styles.combine([?resolved.root.inlineStyles, css!])
            : resolved.root.inlineStyles,
        attributes: attrs,
        events: evts,
      );
    }

    // The tail is the bubble's child so it inherits the bubble's computed
    // fill — see `ResolvedChatBubble`'s DOM note.
    return div(
      [
        div(
          [
            child,
            div(
              const [],
              classes: tailChrome.className,
              styles: tailChrome.inlineStyles,
            ),
          ],
          classes: resolved.root.className,
          styles: resolved.root.inlineStyles,
        ),
      ],
      id: id,
      classes: rootClasses(wrapper.className),
      styles: css != null
          ? Styles.combine([?wrapper.inlineStyles, css!])
          : wrapper.inlineStyles,
      attributes: attrs,
      events: evts,
    );
  }
}
