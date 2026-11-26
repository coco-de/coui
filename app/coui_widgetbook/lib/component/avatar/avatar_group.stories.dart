import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'avatar_group.stories.g.dart';

const _kDefaultGroupCount = 4;

const _kGroupInitials = ['AB', 'CD', 'EF', 'GH', 'IJ', 'KL', 'MN', 'OP'];

/// Knob input for [AvatarGroup] stories.
class AvatarGroupInput {
  /// Creates an [AvatarGroupInput].
  const AvatarGroupInput({this.count = _kDefaultGroupCount, this.max = 0});

  /// Number of avatars rendered in the group.
  final int count;

  /// Maximum number of visible avatars (0 shows all).
  final int max;
}

/// Navigation metadata for the AvatarGroup component.
const kComponentMeta = ComponentMeta(name: 'AvatarGroup', path: 'display');

/// Story metadata for [AvatarGroup].
const kMeta = Meta(AvatarGroup.new, argsType: AvatarGroupInput.new);

/// Default builder mapping [AvatarGroupInput] args to an [AvatarGroup].
final AvatarGroupDefaults defaults = _Defaults(
  builder: (context, args) => AvatarGroup(
    max: args.max > 0 ? args.max : null,
    children: [
      for (int i = 0; i < args.count; i += 1)
        Avatar(initials: _kGroupInitials[i % _kGroupInitials.length]),
    ],
  ),
);

/// Overlapping avatar group with editable knobs.
final $Default = _Story();
