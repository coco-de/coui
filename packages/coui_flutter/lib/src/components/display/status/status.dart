import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform status dot indicator with token-based rendering.
///
/// Displays a small colored dot to indicate current state
/// such as online, offline, or error.
/// Uses [CoreStatusContract] from `coui_core` for consistent
/// cross-platform API.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [statusStyle] slot. Behavioural fields (`color`, `size`,
/// `semanticLabel`) stay flat on the widget.
///
/// Example:
/// ```dart
/// Status(
///   color: CoreStatusColor.success,
///   size: CoreStatusSize.lg,
///   semanticLabel: 'Online',
/// )
/// ```
class Status extends StatelessWidget implements CoreStatusContract<Widget> {
  /// Creates a [Status].
  const Status({
    super.key,
    this.color = CoreStatusColor.neutral,
    this.variant,
    this.size = CoreStatusSize.md,
    this.label,
    this.semanticLabel,
    this.animated = false,
    this.statusStyle,
  });

  @override
  final CoreStatusColor color;

  @override
  final CoreStatusVariant? variant;

  @override
  final CoreStatusSize size;

  @override
  final Widget? label;

  @override
  final String? semanticLabel;

  @override
  final bool animated;

  @override
  final CoreStatusStyle? statusStyle;

  /// Returns a copy of this [Status] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Status copyWith({
    Key? key,
    CoreStatusColor? color,
    CoreStatusVariant? variant,
    CoreStatusSize? size,
    Widget? label,
    String? semanticLabel,
    bool? animated,
    CoreStatusStyle? statusStyle,
  }) {
    return Status(
      key: key ?? this.key,
      color: color ?? this.color,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      label: label ?? this.label,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      animated: animated ?? this.animated,
      statusStyle: statusStyle ?? this.statusStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveStatus(
      context,
      color: color,
      size: size,
      variant: variant,
      statusStyle: statusStyle,
    );

    // A ring state keeps the box and draws only its edge (inside the box, so
    // the dot is the same size as a filled one); a filled state fills it.
    final dot = Container(
      decoration: BoxDecoration(
        color: resolved.hollow ? null : resolved.color,
        borderRadius: resolved.borderRadius,
        border: resolved.hollow
            ? Border.all(color: resolved.color, width: resolved.ringWidth)
            : null,
      ),
      width: resolved.size,
      height: resolved.size,
      alignment: Alignment.center,
      child: resolved.hasBar
          ? SizedBox(
              width: resolved.barLength,
              height: resolved.barWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: resolved.barColor,
                  borderRadius: resolved.barBorderRadius,
                ),
              ),
            )
          : null,
    );

    // A name only when the caller gives one — `label: 'status'` would
    // announce the word "status" and nothing about which state the dot is
    // in, the one thing a reader needed. Unnamed, this is a coloured dot
    // beside something that already says what it means, so saying nothing
    // is truthful.
    //
    // When there *is* a name, the dot is a live region so a state change
    // announces itself — that is what the Web twin's `role="status"` does,
    // and Flutter had no counterpart.
    final label = semanticLabel;
    var child = label == null
        ? dot
        : Semantics(label: label, liveRegion: true, child: dot);

    final reduceMotion = resolveReducedMotion(context);
    if (animated && !reduceMotion) {
      child = _StatusPulse(child: child);
    }

    final visibleLabel = this.label;
    if (visibleLabel == null) {
      return child;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: resolved.labelSpacing,
      children: [
        child,
        DefaultTextStyle.merge(
          style: resolved.labelTextStyle,
          child: visibleLabel,
        ),
      ],
    );
  }
}

class _StatusPulse extends StatefulWidget {
  const _StatusPulse({required this.child});

  final Widget child;

  @override
  State<_StatusPulse> createState() => _StatusPulseState();
}

class _StatusPulseState extends State<_StatusPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: CoreDuration.ms1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
      child: widget.child,
    );
  }
}

/// Chain sugar for merging a [CoreStatusStyle] patch into
/// [Status.statusStyle] without hand-reconstructing every field.
/// Mirrors the Web `Status.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStatusStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreStatusStyle.borderRadius]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Status(color: CoreStatusColor.success).radius4
/// ```
extension StatusStyleChain on Status {
  /// Returns a copy of this [Status] with [patch] merged into
  /// [statusStyle] (patch fields win on conflict).
  Status withStyle(CoreStatusStyle patch) => copyWith(
    statusStyle: (statusStyle ?? const CoreStatusStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Status get radius0 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Status get radius2 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Status get radius4 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Status get radius6 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Status get radius8 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Status get radius10 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Status get radius12 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Status get radius14 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Status get radius16 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Status get radius20 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Status get radius24 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Status get radius28 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Status get radius32 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Status get radius36 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Status get radius40 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Status get radius48 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Status get radius56 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Status get radius64 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Status get radius9999 => withStyle(
    const CoreStatusStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
