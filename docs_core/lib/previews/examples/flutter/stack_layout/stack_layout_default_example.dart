import 'package:coui_flutter/coui_flutter.dart';

/// Default preview for `Stacks`: three 160×80 boxes layered with an
/// 8px downward offset (card-deck effect). Mirrors the Web version
/// token-for-token: same surface-container background, outline border,
/// `CoreRadius.radius16`, and `bodyMedium` typography.
///
/// Uses [Stacks] (z-stack primitive, equivalent of Flutter `Stack`)
/// and explicit [Position] children to express the per-layer offset
/// rather than baking the deck math into the layout primitive itself.
class StackLayoutDefaultExample extends StatelessWidget {
  const StackLayoutDefaultExample({super.key});

  static const _kLabels = ['레이어 1', '레이어 2', '레이어 3'];
  static const _kPerLayerOffset = CoreSpace.space8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalHeight = CoreSpace.space80 + (_kLabels.length - 1) * _kPerLayerOffset;
    return SizedBox(
      width: CoreSpace.space160,
      height: totalHeight,
      child: Stacks(
        children: [
          for (var i = 0; i < _kLabels.length; i++)
            Position(
              top: i * _kPerLayerOffset,
              child: Container(
                width: CoreSpace.space160,
                height: CoreSpace.space80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer.toValue(),
                  borderRadius: BorderRadius.circular(CoreRadius.radius16),
                  border: Border.all(color: theme.colorScheme.outline.toValue()),
                ),
                child: Text(
                  _kLabels[i],
                  style: theme.typography.bodyMedium
                      .toValue(theme: theme)
                      .copyWith(
                        color: theme.colorScheme.onSurface.toValue(),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
