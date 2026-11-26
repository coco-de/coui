import 'package:coui_web/coui_web.dart';

/// Default preview for `Stacks` on Web: three boxes layered with an
/// 8px downward offset. Uses `bg-${cs.surfaceContainer}` + `border-${cs.outline}`
/// + `text-${CoreTextStyles.bodyMedium.name}` via scale tokens so the rendering matches the
/// Flutter counterpart token-for-token.
///
/// Uses [Stacks] (z-stack primitive, equivalent of Flutter `Stack`)
/// and explicit [Position] children to express the per-layer offset
/// rather than baking the deck math into the layout primitive itself.
class StackLayoutDefaultExample extends StatelessComponent {
  const StackLayoutDefaultExample({super.key});

  static const _kLabels = ['레이어 1', '레이어 2', '레이어 3'];
  static const _kPerLayerOffset = CoreSpace.space8;

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    // Width / height utilities use the `size*` Tailwind keys (see
    // `ThemeConfig.tailwindConfig`) — `space*` keys are reserved for
    // padding / margin / gap.
    final layerClasses =
        'w-${CoreSpace.scale.space160} h-${CoreSize.scale.size80} '
        'flex items-center justify-center '
        'bg-${cs.surfaceContainer} border border-${cs.outline} '
        'rounded-${CoreRadius.scale.radius16} '
        'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurface}';
    final totalHeight = CoreSize.size80 + (_kLabels.length - 1) * _kPerLayerOffset;
    // Mirrors the Flutter version: a parent box gives the deck its
    // bounds (the stack itself only contains positioned children, so
    // it collapses to 0×0 without an explicit size).
    return div(
      [
        Stacks(
          children: [
            for (var i = 0; i < _kLabels.length; i++)
              Position(
                top: i * _kPerLayerOffset,
                child: div(
                  [Text(_kLabels[i])],
                  classes: layerClasses,
                ),
              ),
          ],
        ),
      ],
      classes: 'w-${CoreSpace.scale.space160} h-${CoreSpace.scale.space104}',
      // The CSS-pixel total height is `size80 + 2 * space8 = 96px`,
      // which falls between `size96` and `size104`; we round up to
      // `size104` (`6.5rem`) so all three layers fit cleanly inside
      // the deck's bounding box.
      styles: Styles(
        raw: {
          'height': '${totalHeight / 16}rem',
        },
      ),
    );
  }
}
