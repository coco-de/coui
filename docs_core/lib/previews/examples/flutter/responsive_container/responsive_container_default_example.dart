import 'package:coui_flutter/coui_flutter.dart';

/// Default [ResponsiveContainer] — centred, `maxWidth: md`,
/// default horizontal padding.
class ResponsiveContainerDefaultExample extends StatelessWidget {
  /// Creates a [ResponsiveContainerDefaultExample].
  const ResponsiveContainerDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ResponsiveContainer(
      maxWidth: CoreResponsiveContainerMaxWidth.sm,
      child: Card(
        cardStyle: const CoreCardStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space16),
        ),
        child: DefaultTextStyle.merge(
          style: theme.typography.bodyMedium.toValue(theme: theme).copyWith(color: cs.onSurface.toValue()),
          child: const Text(
            '이 내용은 가운데에 놓이고 "sm" 브레이크포인트(640 px)에서 '
            '폭이 멈춰요. 미리보기 크기를 바꿔도 컨테이너는 좌우 여백을 '
            '같게 둔 채 최대 폭 안에 머물러요.',
          ),
        ),
      ),
    );
  }
}
