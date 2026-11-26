import 'package:coui_flutter/coui_flutter.dart';

/// Style modifier chains — italic / underline / lineThrough / overline.
class TextModifiersExample extends StatelessWidget {
  const TextModifiersExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          Text(
            '스타일 수식',
            style: theme.typography.titleSmall
                .toValue(theme: theme)
                .copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant.toValue(),
                ),
          ),
          const Text('기울임 텍스트').italic,
          const Text('밑줄 텍스트').underline,
          const Text('취소선 텍스트').lineThrough,
          const Text('윗줄 텍스트').overline,
        ],
      ),
    );
  }
}
