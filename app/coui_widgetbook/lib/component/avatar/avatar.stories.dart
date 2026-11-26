import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'avatar.stories.g.dart';

/// Knob input for [Avatar] stories.
class AvatarInput {
  /// Creates an [AvatarInput].
  const AvatarInput({
    this.initials = 'AB',
    this.size = CoreAvatarContract.defaultSize,
    this.shape = CoreAvatarShape.defaultShape,
    this.showBadge = false,
    this.ring = false,
  });

  /// Initials rendered inside the avatar.
  final String initials;

  /// Avatar size.
  final CoreComponentSize size;

  /// Avatar outline — a disc for a person, a rounded tile for an
  /// organisation, a workspace or an app.
  final CoreAvatarShape shape;

  /// Whether a status badge is shown.
  final bool showBadge;

  /// Whether a decorative ring surrounds the avatar.
  final bool ring;
}

/// Navigation metadata for the Avatar component.
const kComponentMeta = ComponentMeta(name: 'Avatar', path: 'display');

/// Story metadata for [Avatar].
const kMeta = Meta(Avatar.new, argsType: AvatarInput.new);

/// Default builder mapping [AvatarInput] args to an [Avatar].
final AvatarDefaults defaults = _Defaults(
  builder: (context, args) => Avatar(
    initials: args.initials,
    size: args.size,
    shape: args.shape,
    ring: args.ring,
    badge: args.showBadge ? const AvatarBadge() : null,
  ),
);

/// Avatar at the default size and shape, with editable knobs.
final $Default = _Story();

/// Extra small avatar.
final $ExtraSmall = _Story(
  name: 'Extra Small',
  args: _Args(
    initials: StringArg('XS'),
    size: EnumArg(CoreComponentSize.xs, values: CoreComponentSize.values),
  ),
);

/// Small avatar.
final $Small = _Story(
  args: _Args(
    initials: StringArg('SM'),
    size: EnumArg(CoreComponentSize.sm, values: CoreComponentSize.values),
  ),
);

/// Large avatar.
final $Large = _Story(
  args: _Args(
    initials: StringArg('LG'),
    size: EnumArg(CoreComponentSize.lg, values: CoreComponentSize.values),
  ),
);

/// Extra large avatar.
final $ExtraLarge = _Story(
  name: 'Extra Large',
  args: _Args(
    initials: StringArg('XL'),
    size: EnumArg(CoreComponentSize.xl, values: CoreComponentSize.values),
  ),
);

/// Large avatar with a status badge.
final $WithBadge = _Story(
  name: 'With Badge',
  args: _Args(
    initials: StringArg('JD'),
    size: EnumArg(CoreComponentSize.lg, values: CoreComponentSize.values),
    showBadge: BoolArg(true),
  ),
);

/// Large avatar with a decorative ring.
final $WithRing = _Story(
  name: 'With Ring',
  args: _Args(
    initials: StringArg('JD'),
    size: EnumArg(CoreComponentSize.lg, values: CoreComponentSize.values),
    ring: BoolArg(true),
  ),
);

/// Large rounded tile — the outline for an organisation, a workspace or an
/// app. The corner is the step's own (a quarter of the diameter).
final $Rounded = _Story(
  args: _Args(
    initials: StringArg('CO'),
    size: EnumArg(CoreComponentSize.lg, values: CoreComponentSize.values),
    shape: EnumArg(CoreAvatarShape.rounded, values: CoreAvatarShape.values),
  ),
);
