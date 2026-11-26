import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDisclosureBadgeStyle] slot without constructing the
/// widget from scratch.
///
/// `foregroundColor` paints the label and the deferral dot together, so
/// one override keeps the word and the marker in step. The kind's stroke
/// pattern and marker dot are not reachable from here by design
/// (WCAG 1.4.1).
class DisclosureBadgeChainExample extends StatelessWidget {
  const DisclosureBadgeChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.commitment,
      label: '킥오프 시 제공',
    ).withStyle(
      const CoreDisclosureBadgeStyle(
        foregroundColor: CoreColor.token(CoreColors.primary),
        borderColor: CoreColor.token(CoreColors.primary),
        borderWidth: CoreStrokeWidth.stroke2,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        padding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space8,
          vertical: CoreSpace.space4,
        ),
        labelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
        markerSize: CoreSize.size6,
        markerSpacing: CoreSpace.space6,
      ),
    );
  }
}
