import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain sugar for quickly patching
/// `RefreshTrigger.refreshTriggerStyle` on an already-built instance,
/// instead of only being able to pass
/// `refreshTriggerStyle: CoreRefreshTriggerStyle(...)` in the
/// constructor.
class RefreshTriggerChainExample extends StatefulComponent {
  const RefreshTriggerChainExample({super.key});

  @override
  State<RefreshTriggerChainExample> createState() => _RefreshTriggerChainExampleState();
}

class _RefreshTriggerChainExampleState extends State<RefreshTriggerChainExample> {
  // A GlobalStateKey lets us access the RefreshTrigger's state so we
  // can trigger a programmatic refresh (via the button) in addition to
  // the pull gesture.
  final _refreshTriggerKey = GlobalStateKey<RefreshTriggerState>();

  @override
  Component build(BuildContext context) {
    return OutlinedContainer(
      classes: 'w-full',
      child:
          RefreshTrigger(
            key: _refreshTriggerKey,
            css: const Styles(raw: {'height': 'var(--coui-space-256)'}),
            onRefresh: () async {
              await Future<void>.delayed(const Duration(seconds: 1));
            },
            child: div(
              [
                const Text('당겨 보세요'),
                const Gap.space16(),
                Button(
                  onPressed: () => _refreshTriggerKey.currentState?.refresh(),
                  variant: .primary,
                  child: const Text('새로고침'),
                ),
              ],
              classes: 'flex w-full flex-col items-center',
              styles: const Styles(
                raw: {
                  'height': 'calc(var(--coui-space-256) * 2)',
                  'padding-top': 'var(--coui-space-32)',
                },
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
    );
  }
}
