/// Code snippet for Banner (Flutter). Variant-aware.
String bannerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class BannerChainExample extends StatefulWidget {
  const BannerChainExample({super.key});

  @override
  State<BannerChainExample> createState() => _BannerChainExampleState();
}

class _BannerChainExampleState extends State<BannerChainExample> {
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
          Banner.info(
            message: const Text('일반 안내예요.'),
            onDismiss: () => setState(() => _showCombo = false),
          ).radius16.backgroundColor(.primary)
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showCombo = true),
            child: const Text('배너 보기'),
          ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        if (_showFull)
          Banner.info(
            message: const Text('일반 안내예요.'),
            onDismiss: () => setState(() => _showFull = false),
          ).withStyle(
            const CoreBannerStyle(
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
            child: const Text('배너 보기'),
          ),
      ],
    );
  }
}''',
    'info' =>
      '''
class BannerInfoExample extends StatefulWidget {
  const BannerInfoExample({super.key});

  @override
  State<BannerInfoExample> createState() => _BannerInfoExampleState();
}

class _BannerInfoExampleState extends State<BannerInfoExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Banner.info(
        message: const Text('새로운 업데이트가 준비되었습니다.'),
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('배너 보기'),
    );
  }
}''',
    'success' =>
      '''
class BannerSuccessExample extends StatefulWidget {
  const BannerSuccessExample({super.key});

  @override
  State<BannerSuccessExample> createState() => _BannerSuccessExampleState();
}

class _BannerSuccessExampleState extends State<BannerSuccessExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Banner.success(
        message: const Text('변경 사항이 성공적으로 저장되었습니다.'),
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('배너 보기'),
    );
  }
}''',
    'warning' =>
      '''
class BannerWarningExample extends StatefulWidget {
  const BannerWarningExample({super.key});

  @override
  State<BannerWarningExample> createState() => _BannerWarningExampleState();
}

class _BannerWarningExampleState extends State<BannerWarningExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Banner.warning(
        message: const Text('세션이 5분 후에 만료됩니다.'),
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('배너 보기'),
    );
  }
}''',
    'solid' =>
      '''
class BannerSolidExample extends StatefulWidget {
  const BannerSolidExample({super.key});

  @override
  State<BannerSolidExample> createState() => _BannerSolidExampleState();
}

class _BannerSolidExampleState extends State<BannerSolidExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Banner(
        variant: CoreBannerVariant.destructive,
        emphasis: CoreBannerEmphasis.solid,
        message: const Text('지금은 결제를 할 수 없어요.'),
        description: const Text('복구하고 있어요. 따로 하실 일은 없어요.'),
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('배너 보기'),
    );
  }
}''',
    'destructive' =>
      '''
class BannerDestructiveExample extends StatefulWidget {
  const BannerDestructiveExample({super.key});

  @override
  State<BannerDestructiveExample> createState() =>
      _BannerDestructiveExampleState();
}

class _BannerDestructiveExampleState extends State<BannerDestructiveExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Banner.destructive(
        message: const Text('요청을 처리하는 중 문제가 발생했습니다.'),
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('배너 보기'),
    );
  }
}''',
    'narrow' =>
      '''
// A phone-width column: too narrow for the message to keep its minimum
// width beside the action and dismiss.
const double _kNarrowWidth = 320;

/// Narrow-width Banner example for docs_site Flutter preview.
///
/// At 320 the message can't keep its minimum width beside the action and
/// dismiss, so the trailing group drops to its own line under the text.
class BannerNarrowExample extends StatefulWidget {
  const BannerNarrowExample({super.key});

  @override
  State<BannerNarrowExample> createState() => _BannerNarrowExampleState();
}

class _BannerNarrowExampleState extends State<BannerNarrowExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return SizedBox(
        width: _kNarrowWidth,
        child: Banner.warning(
          message: const Text('체험 기간이 3일 남았어요.'),
          description: const Text('업그레이드하면 프로젝트를 계속 쓸 수 있어요.'),
          action: Button(
            variant: CoreButtonVariant.outline,
            size: CoreComponentSize.sm,
            onPressed: () {},
            child: const Text('업그레이드'),
          ),
          onDismiss: () => setState(() => _show = false),
        ),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('배너 보기'),
    );
  }
}''',
    _ =>
      '''
class BannerDefaultExample extends StatefulWidget {
  const BannerDefaultExample({super.key});

  @override
  State<BannerDefaultExample> createState() => _BannerDefaultExampleState();
}

class _BannerDefaultExampleState extends State<BannerDefaultExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Banner.info(
        message: const Text('일반 안내예요.'),
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('배너 보기'),
    );
  }
}''',
  };
}
