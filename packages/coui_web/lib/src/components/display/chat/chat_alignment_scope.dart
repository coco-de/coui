import 'package:coui_core/coui_core.dart' show CoreChatAlignment;
import 'package:jaspr/jaspr.dart';

/// Ambient scope for the side of the thread a `Chat` row sits on — the
/// alignment it hands to the bubble it holds.
///
/// A `ChatBubble` that states no `alignment`, `variant` or `tail` of its own
/// reads [maybeOf] and takes the row's side and the defaults that side
/// implies (`CoreChatBubbleContract.defaultVariantFor` / `defaultTailFor`),
/// so the row's `alignment` is stated once instead of on the row and again on
/// every bubble in it.
///
/// Mirrors the Flutter `ChatAlignmentScope` (`InheritedWidget`) 1:1: pure
/// metadata, no DOM of its own. A component portalled out of the row (an
/// overlay opened from inside it) is mounted under the overlay host, outside
/// the scope — the bubbles in it do not take the row's side, as on Flutter.
class ChatAlignmentScope extends InheritedComponent {
  /// Creates a scope exposing [alignment] to [child].
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
      .dependOnInheritedComponentOfExactType<ChatAlignmentScope>()
      ?.alignment;

  @override
  bool updateShouldNotify(covariant ChatAlignmentScope oldComponent) =>
      alignment != oldComponent.alignment;
}
