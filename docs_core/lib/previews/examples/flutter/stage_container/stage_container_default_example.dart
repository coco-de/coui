import 'package:coui_flutter/coui_flutter.dart';

/// Default preview for `StageContainer`: wraps a coloured box with a
/// responsive container that clamps the content width onto Bootstrap-style
/// breakpoint rungs (576 / 768 / 992 / 1200 / 1400) and redistributes the
/// remaining viewport width as symmetric horizontal padding.
class StageContainerDefaultExample extends StatelessWidget {
  const StageContainerDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StageContainer(
      builder: (context, padding) {
        return Padding(
          padding: padding.toValue(),
          child: Container(
            height: CoreSpace.space80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.toValue(),
              borderRadius: BorderRadius.circular(CoreRadius.radius16),
              border: Border.all(color: theme.colorScheme.outline.toValue()),
            ),
            child: Text(
              '왼쪽: ${padding.left.toStringAsFixed(0)}, '
              '오른쪽: ${padding.right.toStringAsFixed(0)}',
              style: theme.typography.bodyMedium
                  .toValue(theme: theme)
                  .copyWith(
                    color: theme.colorScheme.onSurface.toValue(),
                  ),
            ),
          ),
        );
      },
    );
  }
}
