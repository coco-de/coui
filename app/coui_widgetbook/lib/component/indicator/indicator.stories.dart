import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'indicator.stories.g.dart';

// Indicator widgetbook constants.
const _kAvatarInitials = 'DW';
const _kBadgeCount = '3';
const _kOffsetDefault = 0.0;

/// Knob input for [Indicator] stories.
class IndicatorInput {
  /// Creates an [IndicatorInput].
  const IndicatorInput({
    this.horizontalPosition = CoreIndicatorHorizontalPosition.end,
    this.verticalPosition = CoreIndicatorVerticalPosition.top,
    this.offset = _kOffsetDefault,
    this.showBadge = false,
  });

  /// Horizontal anchor of the indicator item.
  final CoreIndicatorHorizontalPosition horizontalPosition;

  /// Vertical anchor of the indicator item.
  final CoreIndicatorVerticalPosition verticalPosition;

  /// Outward offset of the indicator item.
  final double offset;

  /// Whether a count [Badge] is overlaid instead of a [Status] dot.
  final bool showBadge;
}

/// Navigation metadata for the Indicator component.
const kComponentMeta = ComponentMeta(name: 'Indicator', path: 'display');

/// Story metadata for [Indicator].
const kMeta = Meta(Indicator.new, argsType: IndicatorInput.new);

/// Default builder mapping [IndicatorInput] args to an [Indicator].
///
/// Distinct from `DotIndicator` (a row of page dots for pagination):
/// `Indicator` overlays an arbitrary widget — a [Status] dot or a
/// count [Badge] — on a corner of the wrapped child.
final IndicatorDefaults defaults = _Defaults(
  builder: (context, args) => args.showBadge
      ? Indicator(
          item: const Badge(
            tone: CoreBadgeTone.destructive,
            variant: CoreBadgeVariant.filled,
            form: CoreBadgeForm.count,
            size: CoreComponentSize.xs,
            child: Text(_kBadgeCount),
          ),
          horizontalPosition: args.horizontalPosition,
          verticalPosition: args.verticalPosition,
          indicatorStyle: CoreIndicatorStyle(offset: args.offset),
          child: const Icon(
            LucideIcons.bell,
            iconStyle: CoreIconStyle(size: CoreSpace.space24),
          ),
        )
      : Indicator(
          item: const Status(
            color: .success,
            size: .lg,
          ),
          horizontalPosition: args.horizontalPosition,
          verticalPosition: args.verticalPosition,
          indicatorStyle: CoreIndicatorStyle(offset: args.offset),
          child: const Avatar(initials: _kAvatarInitials),
        ),
);

/// Status dot overlaid on an avatar with editable knobs.
final $Default = _Story();

/// Count badge overlaid on a bell icon.
final $WithBadge = _Story(
  name: 'With Badge',
  args: _Args(showBadge: BoolArg(true)),
);
