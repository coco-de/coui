/// Code snippet for Toast — variant-aware entry point.
String toastCode(String? variant) => switch (variant) {
  'chain' => toastChainCode(),
  'destructive' => toastDestructiveCode(),
  'no-icon' => toastNoIconCode(),
  _ => toastDefaultCode(),
};

/// Code snippet for the `withStyle` chain Toast example (Flutter).
String toastChainCode() => '''class ToastChainExample extends StatelessWidget {
  const ToastChainExample({super.key});

  @override
  Widget build(BuildContext context) {
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
}''';

/// Code snippet for default Toast (Flutter).
String toastDefaultCode() => '''class ToastDefaultExample extends StatefulWidget {
  const ToastDefaultExample({super.key});

  @override
  State<ToastDefaultExample> createState() => _ToastDefaultExampleState();
}

class _ToastDefaultExampleState extends State<ToastDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return Toast(
      message: '저장했어요',
      description: '변경 사항을 저장했어요.',
      onDismiss: () {},
    );
  }
}''';

/// Code snippet for destructive Toast (Flutter).
String toastDestructiveCode() => '''class ToastDestructiveExample extends StatefulWidget {
  const ToastDestructiveExample({super.key});

  @override
  State<ToastDestructiveExample> createState() =>
      _ToastDestructiveExampleState();
}

class _ToastDestructiveExampleState extends State<ToastDestructiveExample> {
  @override
  Widget build(BuildContext context) {
    return Toast(
      message: '저장하지 못했어요',
      description: '문제가 생겼어요. 다시 시도해 주세요.',
      variant: CoreToastVariant.destructive,
      onDismiss: () {},
    );
  }
}''';

/// Code snippet for no-icon Toast (Flutter).
String toastNoIconCode() => '''class ToastNoIconExample extends StatelessWidget {
  const ToastNoIconExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Toast(
      message: '저장했어요',
      description: '변경 사항을 저장했어요.',
      variant: CoreToastVariant.success,
      showIcon: false,
      onDismiss: () {},
    );
  }
}''';
