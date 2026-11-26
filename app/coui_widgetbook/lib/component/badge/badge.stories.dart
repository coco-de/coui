import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'badge.stories.g.dart';

/// Knob input for [Badge] stories.
class BadgeInput {
  /// Creates a [BadgeInput].
  const BadgeInput({
    this.text = 'Badge',
    this.tone = CoreBadgeTone.defaultTone,
    this.variant = CoreBadgeVariant.defaultVariant,
    this.form = CoreBadgeForm.defaultForm,
    this.size = CoreBadgeContract.defaultSize,
    this.showDot = CoreBadgeContract.defaultShowDot,
    this.showLeadingIcon = false,
    this.showTrailingIcon = false,
    this.clickable = false,
  });

  /// Badge label text.
  final String text;

  /// What the badge's colour means.
  final CoreBadgeTone tone;

  /// How loud the badge is — filled, tonal or outlined.
  final CoreBadgeVariant variant;

  /// What the badge holds — a word, a number, or nothing.
  final CoreBadgeForm form;

  /// Badge size.
  final CoreComponentSize size;

  /// Whether the leading status dot is shown.
  final bool showDot;

  /// Whether a leading icon is shown.
  final bool showLeadingIcon;

  /// Whether a trailing icon is shown.
  final bool showTrailingIcon;

  /// Whether the badge reacts to taps (press feedback).
  final bool clickable;
}

/// Navigation metadata for the Badge component.
const kComponentMeta = ComponentMeta(name: 'Badge', path: 'display');

/// Story metadata for [Badge].
const kMeta = Meta(Badge.new, argsType: BadgeInput.new);

void _noop() {}

/// Default builder mapping [BadgeInput] args to a [Badge].
final BadgeDefaults defaults = _Defaults(
  builder: (context, args) => Badge(
    tone: args.tone,
    variant: args.variant,
    form: args.form,
    size: args.size,
    showDot: args.showDot,
    leading: args.showLeadingIcon
        ? const Icon(
            LucideIcons.star,
            iconStyle: CoreIconStyle(size: CoreSpace.space16),
          )
        : null,
    trailing: args.showTrailingIcon
        ? const Icon(
            LucideIcons.x,
            iconStyle: CoreIconStyle(size: CoreSpace.space16),
          )
        : null,
    onPressed: args.clickable ? _noop : null,
    child: Text(args.text),
  ),
);

/// Every default — a neutral, tonal word at md (a tag).
final $Default = _Story();

/// A status label — a tone with the leading status dot.
final $Status = _Story(
  args: _Args(
    text: StringArg('Approved'),
    tone: EnumArg(CoreBadgeTone.success, values: CoreBadgeTone.values),
    showDot: BoolArg(true),
  ),
);

/// An unread count — a filled number pill.
final $Count = _Story(
  args: _Args(
    text: StringArg('3'),
    tone: EnumArg(CoreBadgeTone.info, values: CoreBadgeTone.values),
    variant: EnumArg(
      CoreBadgeVariant.filled,
      values: CoreBadgeVariant.values,
    ),
    form: EnumArg(CoreBadgeForm.count, values: CoreBadgeForm.values),
    size: EnumArg(CoreComponentSize.xs, values: CoreComponentSize.values),
  ),
);

/// Outlined strength — a line in the tone's colour.
final $Outlined = _Story(
  args: _Args(
    variant: EnumArg(
      CoreBadgeVariant.outlined,
      values: CoreBadgeVariant.values,
    ),
  ),
);

/// Dot form — no content, only the tone.
final $Dot = _Story(
  args: _Args(
    tone: EnumArg(CoreBadgeTone.destructive, values: CoreBadgeTone.values),
    form: EnumArg(CoreBadgeForm.dot, values: CoreBadgeForm.values),
  ),
);

/// Badge with a leading icon.
final $WithLeadingIcon = _Story(
  args: _Args(showLeadingIcon: BoolArg(true)),
);

/// Clickable badge with hover / pressed state layer.
final $Clickable = _Story(
  args: _Args(clickable: BoolArg(true)),
);
