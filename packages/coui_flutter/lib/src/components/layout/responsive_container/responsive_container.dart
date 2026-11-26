import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/responsive_container/responsive_container_style.dart';
import 'package:flutter/widgets.dart';

/// Horizontally-centred, max-width-constrained layout wrapper.
///
/// Mirrors the Web `ResponsiveContainer` — same parameter names,
/// same defaults (`maxWidth: xl`, `centered: true`, horizontal
/// `CoreSpace.space16` padding), same visual outcome. Content wider
/// than the effective max-width is clipped by the parent; narrower
/// viewports see the container stretch to the full parent width and
/// the padding remains applied.
class ResponsiveContainer extends StatelessWidget
    implements CoreResponsiveContainerContract<Widget> {
  /// Creates a [ResponsiveContainer].
  const ResponsiveContainer({
    required this.child,
    super.key,
    this.maxWidth,
    this.responsiveMaxWidth,
    this.centered,
    this.padding,
    this.responsiveContainerStyle,
  });

  @override
  final Widget child;

  @override
  final CoreResponsiveContainerMaxWidth? maxWidth;

  @override
  final Map<CoreBreakpointTier, CoreResponsiveContainerMaxWidth>?
  responsiveMaxWidth;

  @override
  final bool? centered;

  @override
  final CoreEdgeInsets? padding;

  @override
  final CoreResponsiveContainerStyle? responsiveContainerStyle;

  /// Returns a copy of this [ResponsiveContainer] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  ResponsiveContainer copyWith({
    Key? key,
    Widget? child,
    CoreResponsiveContainerMaxWidth? maxWidth,
    Map<CoreBreakpointTier, CoreResponsiveContainerMaxWidth>?
    responsiveMaxWidth,
    bool? centered,
    CoreEdgeInsets? padding,
    CoreResponsiveContainerStyle? responsiveContainerStyle,
  }) {
    return ResponsiveContainer(
      key: key ?? this.key,
      maxWidth: maxWidth ?? this.maxWidth,
      responsiveMaxWidth: responsiveMaxWidth ?? this.responsiveMaxWidth,
      centered: centered ?? this.centered,
      padding: padding ?? this.padding,
      responsiveContainerStyle:
          responsiveContainerStyle ?? this.responsiveContainerStyle,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveResponsiveContainer(
      context,
      maxWidth: maxWidth,
      responsiveMaxWidth: responsiveMaxWidth,
      centered: centered,
      padding: padding,
      responsiveContainerStyle: responsiveContainerStyle,
    );

    Widget result = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: resolved.maxWidth),
      child: SizedBox(
        width: .infinity,
        child: Padding(padding: resolved.horizontalPadding, child: child),
      ),
    );

    if (resolved.centered) {
      // `Align(topCenter)` mirrors the Web's `w-full mx-auto` —
      // horizontal centring only, vertical alignment stays at the
      // top so both platforms render the same way inside arbitrary
      // parent heights.
      result = Align(alignment: Alignment.topCenter, child: result);
    }

    return result;
  }
}

/// Chain sugar for merging a [CoreResponsiveContainerStyle] patch into
/// [ResponsiveContainer.responsiveContainerStyle] without
/// hand-reconstructing every field. Mirrors the Web
/// `ResponsiveContainer.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreResponsiveContainerStyle.merge` right-side-wins
/// semantics).
extension ResponsiveContainerStyleChain on ResponsiveContainer {
  /// Returns a copy of this [ResponsiveContainer] with [patch] merged
  /// into [responsiveContainerStyle] (patch fields win on conflict).
  ResponsiveContainer withStyle(CoreResponsiveContainerStyle patch) => copyWith(
    responsiveContainerStyle:
        (responsiveContainerStyle ?? const CoreResponsiveContainerStyle())
            .merge(patch),
  );
}
