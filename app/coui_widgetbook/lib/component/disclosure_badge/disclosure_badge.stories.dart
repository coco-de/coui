import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'disclosure_badge.stories.g.dart';

/// Knob input for [DisclosureBadge] stories.
class DisclosureBadgeInput {
  /// Creates a [DisclosureBadgeInput].
  const DisclosureBadgeInput({
    this.kind = CoreDisclosureKind.open,
    this.label = 'Evidence available',
  });

  /// Which of the three disclosure states the badge states. It carries
  /// the outline pattern and the deferral dot, so switching it changes
  /// the shape and not only the colour.
  final CoreDisclosureKind kind;

  /// Status text. For [CoreDisclosureKind.private] the reason belongs
  /// here, because a bare "Private" reads as evasion.
  final String label;
}

/// Navigation metadata for the DisclosureBadge component.
const kComponentMeta = ComponentMeta(name: 'DisclosureBadge', path: 'display');

/// Story metadata for [DisclosureBadge].
const kMeta = Meta(DisclosureBadge.new, argsType: DisclosureBadgeInput.new);

/// Substitutes a word when the label knob is cleared.
///
/// [DisclosureBadge] asserts on an empty label by design, so the catalog
/// supplies one rather than red-screening on an emptied text field.
String _label(String label) => label.isEmpty ? 'Disclosure' : label;

/// Default builder mapping [DisclosureBadgeInput] args to a
/// [DisclosureBadge].
final DisclosureBadgeDefaults defaults = _Defaults(
  builder: (context, args) =>
      DisclosureBadge(kind: args.kind, label: _label(args.label)),
);

/// Openable right now — a solid outline and no marker.
final $Default = _Story();

/// Promised for later — a solid outline plus the deferral dot that
/// separates it from an openable badge without relying on colour.
final $Commitment = _Story(
  args: _Args(
    kind: EnumArg(
      CoreDisclosureKind.commitment,
      values: CoreDisclosureKind.values,
    ),
    label: StringArg('Provided at kickoff'),
  ),
);

/// Never openable — a dashed outline, with the reason carried in the
/// label text.
final $Private = _Story(
  args: _Args(
    kind: EnumArg(
      CoreDisclosureKind.private,
      values: CoreDisclosureKind.values,
    ),
    label: StringArg('Private · NDA'),
  ),
);
