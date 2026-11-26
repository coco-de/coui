import 'package:coui_flutter/coui_flutter.dart';

/// Ambient scope for the side of the thread a [Chat] row sits on — the
/// alignment it hands to the bubble it holds.
///
/// A [ChatBubble] that states no `alignment`, `variant` or `tail` of its own
/// reads [maybeOf] and takes the row's side and the defaults that side
/// implies (`CoreChatBubbleContract.defaultVariantFor` /
/// `defaultTailFor`), so the row's `alignment` is stated once instead of on
/// the row and again on every bubble in it.
///
/// Mirrors the Web `ChatAlignmentScope` (`InheritedComponent`) 1:1: a plain
/// [InheritedWidget], pure metadata, no widget of its own. Deliberately NOT a
/// `Data<T>`: the kit's overlays copy every `Data<T>` between the trigger and
/// the overlay root, so a `Data`-based scope would follow a dialog or popover
/// opened from inside a chat row — and the bubbles in it would take the row's
/// side though none of them sits in the row.
class ChatAlignmentScope extends InheritedWidget {
  /// Creates a [ChatAlignmentScope] exposing [alignment] to [child].
  const ChatAlignmentScope({
    required this.alignment,
    required super.child,
    super.key,
  });

  /// The side of the thread the row sits on.
  final CoreChatAlignment alignment;

  /// Returns the alignment of the nearest chat row above [context], or null
  /// when the bubble is not inside one.
  static CoreChatAlignment? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ChatAlignmentScope>()
      ?.alignment;

  @override
  bool updateShouldNotify(ChatAlignmentScope oldWidget) =>
      alignment != oldWidget.alignment;
}
