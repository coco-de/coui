import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreToastStyle] slot without constructing the widget
/// from scratch.
class ToastChainExample extends StatelessComponent {
  const ToastChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Toast(
      message: '저장했어요',
      description: '변경 사항을 저장했어요.',
      onDismiss: () {},
    ).withStyle(
      const CoreToastStyle(
        panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        panelBorderColor: CoreColor.token(CoreColors.primary),
        panelBorderWidth: CoreStrokeWidth.stroke2,
        panelPaddingWithDismiss: CoreEdgeInsets.directional(
          start: CoreSpace.space16,
          top: CoreSpace.space16,
          end: CoreSpace.space48,
          bottom: CoreSpace.space16,
        ),
        messageDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space8),
      ),
    );
  }
}
