/// Code snippet for Alert (Flutter). Variant-aware.
String alertCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class AlertChainExample extends StatefulWidget {
  const AlertChainExample({super.key});

  @override
  State<AlertChainExample> createState() => _AlertChainExampleState();
}

class _AlertChainExampleState extends State<AlertChainExample> {
  bool _showCombo = true;
  bool _showFull = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        if (_showCombo)
          Alert(
            title: '확인이 필요해요',
            description: '결제 수단을 다시 확인해 주세요.',
            onDismiss: () => setState(() => _showCombo = false),
          ).radius16.backgroundColor(.primary)
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showCombo = true),
            child: const Text('알림 보기'),
          ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        if (_showFull)
          Alert(
            title: '확인이 필요해요',
            description: '결제 수단을 다시 확인해 주세요.',
            onDismiss: () => setState(() => _showFull = false),
          ).withStyle(
            const CoreAlertStyle(
              backgroundColor: .tertiaryContainer,
              foregroundColor: .onTertiaryContainer,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          )
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showFull = true),
            child: const Text('알림 보기'),
          ),
      ],
    );
  }
}''',
    'info' =>
      '''
class AlertInfoExample extends StatefulWidget {
  const AlertInfoExample({super.key});

  @override
  State<AlertInfoExample> createState() => _AlertInfoExampleState();
}

class _AlertInfoExampleState extends State<AlertInfoExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Alert.info(
        title: '정보',
        description: '새로운 업데이트가 있습니다.',
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('알림 보기'),
    );
  }
}''',
    'success' =>
      '''
class AlertSuccessExample extends StatefulWidget {
  const AlertSuccessExample({super.key});

  @override
  State<AlertSuccessExample> createState() => _AlertSuccessExampleState();
}

class _AlertSuccessExampleState extends State<AlertSuccessExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Alert.success(
        title: '저장 완료',
        description: '변경 사항이 성공적으로 저장되었습니다.',
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('알림 보기'),
    );
  }
}''',
    'warning' =>
      '''
class AlertWarningExample extends StatefulWidget {
  const AlertWarningExample({super.key});

  @override
  State<AlertWarningExample> createState() => _AlertWarningExampleState();
}

class _AlertWarningExampleState extends State<AlertWarningExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Alert.warning(
        title: '주의',
        description: '이 작업은 되돌릴 수 없습니다.',
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('알림 보기'),
    );
  }
}''',
    'destructive' =>
      '''
class AlertDestructiveExample extends StatefulWidget {
  const AlertDestructiveExample({super.key});

  @override
  State<AlertDestructiveExample> createState() =>
      _AlertDestructiveExampleState();
}

class _AlertDestructiveExampleState extends State<AlertDestructiveExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Alert.destructive(
        title: '오류 발생',
        description: '요청을 처리하는 중 문제가 발생했습니다.',
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('알림 보기'),
    );
  }
}''',
    'text-only' =>
      '''
class AlertTextOnlyExample extends StatelessWidget {
  const AlertTextOnlyExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        coreComponentTheme: () => const CoreComponentTheme(
          alert: CoreAlertTheme(
            variantStyles: {
              CoreAlertVariant.success: CoreAlertStyle(
                titleColor: CoreColor.token(CoreColors.onSuccessContainer),
              ),
              CoreAlertVariant.warning: CoreAlertStyle(
                titleColor: CoreColor.token(CoreColors.onWarningContainer),
              ),
            },
          ),
        ),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Alert.success(
            title: '송금 완료',
            description: '10분 안에 입금돼요.',
            showIcon: false,
          ),
          Gap.space12(),
          Alert.warning(
            title: '오후 4시에 환율이 바뀌어요',
            description: '그 전에 보내면 지금 환율이 적용돼요.',
            showIcon: false,
          ),
        ],
      ),
    );
  }
}''',
    'inline' =>
      '''
class AlertInlineExample extends StatelessWidget {
  const AlertInlineExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Alert(
      layout: CoreAlertLayout.inline,
      leading: Badge(
        tone: CoreBadgeTone.success,
        showDot: true,
        child: Text('동기화됨'),
      ),
      title: '모든 변경 사항을 클라우드에 저장했어요.',
      action: Icon(
        LucideIcons.chevronDown,
        iconStyle: CoreIconStyle(
          size: CoreIconSize.size16,
          color: CoreColor.token(CoreColors.onSurfaceSubtle),
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class AlertDefaultExample extends StatefulWidget {
  const AlertDefaultExample({super.key});

  @override
  State<AlertDefaultExample> createState() => _AlertDefaultExampleState();
}

class _AlertDefaultExampleState extends State<AlertDefaultExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Alert(
        title: '확인이 필요해요',
        description: '결제 수단을 다시 확인해 주세요.',
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('알림 보기'),
    );
  }
}''',
  };
}
