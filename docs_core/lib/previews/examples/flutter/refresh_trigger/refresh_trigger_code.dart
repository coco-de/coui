/// Code snippet for default RefreshTrigger (Flutter).
String refreshTriggerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class RefreshTriggerChainExample extends StatefulWidget {
  const RefreshTriggerChainExample({super.key});

  @override
  State<RefreshTriggerChainExample> createState() => _RefreshTriggerChainExampleState();
}

class _RefreshTriggerChainExampleState extends State<RefreshTriggerChainExample> {
  // A GlobalKey lets us access the RefreshTrigger's state so we can
  // trigger a programmatic refresh (via the button) in addition to the
  // pull gesture.
  final _refreshTriggerKey = GlobalKey<RefreshTriggerState>();

  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      child: SizedBox(
        height: CoreSpace.space256,
        child:
            RefreshTrigger(
              key: _refreshTriggerKey,
              onRefresh: () async {
                await Future<void>.delayed(const Duration(seconds: 1));
              },
              child: ScrollArea(
                child: Container(
                  height: CoreSpace.space256 * 2,
                  padding: const CoreEdgeInsets.only(
                    top: CoreSpace.space32,
                  ).toValue(geometry: Theme.of(context).geometry),
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      const Text('당겨 보세요'),
                      const Gap.space16(),
                      Button(
                        onPressed: () => _refreshTriggerKey.currentState?.refresh(),
                        variant: .primary,
                        child: const Text('새로고침'),
                      ),
                    ],
                  ),
                ),
              ),
            ).withStyle(
              const CoreRefreshTriggerStyle(
                indicatorBackgroundColor: CoreColor.token(CoreColors.secondaryContainer),
                indicatorBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                indicatorPadding: CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space20,
                  vertical: CoreSpace.space12,
                ),
                indicatorGapStyle: CoreGapStyle(size: CoreSpace.space12),
              ),
            ),
      ),
    );
  }
}''',
    _ =>
      '''class RefreshTriggerDefaultExample extends StatefulWidget {
  const RefreshTriggerDefaultExample({super.key});

  @override
  State<RefreshTriggerDefaultExample> createState() =>
      _RefreshTriggerDefaultExampleState();
}

class _RefreshTriggerDefaultExampleState
    extends State<RefreshTriggerDefaultExample> {
  // A GlobalKey lets us access the RefreshTrigger's state so we can
  // trigger a programmatic refresh (via the button) in addition to the
  // pull gesture.
  final _refreshTriggerKey = GlobalKey<RefreshTriggerState>();

  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      child: SizedBox(
        height: CoreSpace.space256,
        child: RefreshTrigger(
          key: _refreshTriggerKey,
          onRefresh: () async {
            await Future<void>.delayed(const Duration(seconds: 1));
          },
          child: ScrollArea(
            child: Container(
              height: CoreSpace.space256 * 2,
              padding: const CoreEdgeInsets.only(top: CoreSpace.space32).toValue(geometry: Theme.of(context).geometry),
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: .min,
                children: [
                  const Text('당겨 보세요'),
                  const Gap.space16(),
                  Button(
                    onPressed: () =>
                        _refreshTriggerKey.currentState?.refresh(),
                    variant: .primary,
                    child: const Text('새로고침'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}''',
  };
}
