import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'banner.stories.g.dart';

/// Knob input for [Banner] stories.
class BannerInput {
  /// Creates a [BannerInput].
  const BannerInput({
    this.message = 'This is a message banner',
    this.variant = CoreBannerVariant.info,
    this.showIcon = true,
    this.dismissible = false,
  });

  /// Banner message text.
  final String message;

  /// Banner variant.
  final CoreBannerVariant variant;

  /// Whether the variant icon is shown.
  final bool showIcon;

  /// Whether a dismiss button is shown.
  final bool dismissible;
}

/// Navigation metadata for the Banner component.
const kComponentMeta = ComponentMeta(name: 'Banner', path: 'display');

/// Story metadata for [Banner].
const kMeta = Meta(Banner.new, argsType: BannerInput.new);

void _noop() {}

/// Default builder mapping [BannerInput] args to a [Banner].
final BannerDefaults defaults = _Defaults(
  builder: (context, args) => Banner(
    message: Text(args.message),
    variant: args.variant,
    onDismiss: args.dismissible ? _noop : null,
    showIcon: args.showIcon,
  ),
);

/// Info banner with editable knobs.
final $Default = _Story();

/// Warning banner.
final $Warning = _Story(
  args: _Args(
    message: StringArg('Warning banner'),
    variant: EnumArg(
      CoreBannerVariant.warning,
      values: CoreBannerVariant.values,
    ),
  ),
);

/// Destructive (error) banner.
final $Destructive = _Story(
  args: _Args(
    message: StringArg('Error banner'),
    variant: EnumArg(
      CoreBannerVariant.destructive,
      values: CoreBannerVariant.values,
    ),
  ),
);

/// Success banner.
final $Success = _Story(
  args: _Args(
    message: StringArg('Success banner'),
    variant: EnumArg(
      CoreBannerVariant.success,
      values: CoreBannerVariant.values,
    ),
  ),
);

/// Neutral (default variant) banner.
final $Neutral = _Story(
  args: _Args(
    message: StringArg('Default banner'),
    variant: EnumArg(
      CoreBannerVariant.neutral,
      values: CoreBannerVariant.values,
    ),
  ),
);
