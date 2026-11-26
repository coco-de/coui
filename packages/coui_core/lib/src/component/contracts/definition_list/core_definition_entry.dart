/// Platform-independent term / description pair for `DefinitionList`.
library;

import 'package:meta/meta.dart';

/// One term / description pair — a `<dt>` and the `<dd>` that answers it.
///
/// [term] is always a plain [String]. It is the label a screen reader
/// announces before the value, which is the entire point of the
/// component: a number read on its own ("000-00-00000") tells a listener
/// nothing, and the same number read after its term does. A term built
/// from arbitrary markup could be an icon with no text, so the type
/// refuses that case rather than documenting against it.
///
/// The description comes in two shapes:
///
/// * [CoreDefinitionEntry.new] — a plain [String]. The common case.
/// * [CoreDefinitionEntry.rich] — a platform widget / component [W], for
///   a value that is a link, an address block, or otherwise not one run
///   of text.
///
/// Exactly one of [descriptionText] / [description] is non-null; which
/// one is decided by the constructor, so there is no state where both or
/// neither is set.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
@immutable
class CoreDefinitionEntry<W> {
  /// Creates an entry whose description is a plain string.
  ///
  /// ```dart
  /// CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000')
  /// ```
  const CoreDefinitionEntry({
    required this.term,
    required String description,
  }) : descriptionText = description,
       description = null;

  /// Creates an entry whose description is a platform widget / component
  /// — a link, a badge, a multi-line address.
  ///
  /// ```dart
  /// CoreDefinitionEntry.rich(
  ///   term: '이메일',
  ///   description: Link(href: 'mailto:cody@cocode.im', child: ...),
  /// )
  /// ```
  const CoreDefinitionEntry.rich({
    required this.term,
    required W this.description,
  }) : descriptionText = null;

  /// The label announced before the value. Renders as `<dt>` on Web.
  final String term;

  /// The description as plain text. Non-null exactly when the entry was
  /// built through [CoreDefinitionEntry.new].
  final String? descriptionText;

  /// The description as a platform widget / component. Non-null exactly
  /// when the entry was built through [CoreDefinitionEntry.rich].
  final W? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDefinitionEntry<W> &&
          runtimeType == other.runtimeType &&
          term == other.term &&
          descriptionText == other.descriptionText &&
          description == other.description;

  @override
  int get hashCode => Object.hash(term, descriptionText, description);

  @override
  String toString() =>
      'CoreDefinitionEntry(term: $term, '
      'description: ${descriptionText ?? description})';
}
