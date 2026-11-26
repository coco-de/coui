import 'package:coui_web/coui_web.dart';

/// Default RefreshTrigger example for docs_site Web preview.
///
/// Mirrors the shadcn_flutter demo: a fixed-height outlined viewport
/// hosting scrollable content with a "Pull Me" hint and a button that
/// triggers a programmatic refresh. Pulling the content past its top
/// boundary (touch or mouse drag — both built into the component) or
/// pressing the button runs the async `onRefresh` callback.
class RefreshTriggerDefaultExample extends StatefulComponent {
  const RefreshTriggerDefaultExample({super.key});

  @override
  State<RefreshTriggerDefaultExample> createState() => _RefreshTriggerDefaultExampleState();
}

class _RefreshTriggerDefaultExampleState extends State<RefreshTriggerDefaultExample> {
  // A GlobalStateKey lets us access the RefreshTrigger's state so we
  // can trigger a programmatic refresh (via the button) in addition to
  // the pull gesture.
  final _refreshTriggerKey = GlobalStateKey<RefreshTriggerState>();

  @override
  Component build(BuildContext context) {
    return OutlinedContainer(
      classes: 'w-full',
      child: RefreshTrigger(
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
      ),
    );
  }
}
