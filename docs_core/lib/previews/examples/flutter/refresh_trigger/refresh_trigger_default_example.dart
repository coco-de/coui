import 'package:coui_flutter/coui_flutter.dart';

/// Default RefreshTrigger example for docs_site Flutter preview.
///
/// Mirrors the shadcn_flutter demo: a fixed-height outlined viewport
/// hosting a scrollable area with a "Pull Me" hint and a button that
/// triggers a programmatic refresh. Pulling the content past its top
/// boundary (touch or mouse drag — both built into the component) or
/// pressing the button runs the async `onRefresh` callback.
class RefreshTriggerDefaultExample extends StatefulWidget {
  const RefreshTriggerDefaultExample({super.key});

  @override
  State<RefreshTriggerDefaultExample> createState() => _RefreshTriggerDefaultExampleState();
}

class _RefreshTriggerDefaultExampleState extends State<RefreshTriggerDefaultExample> {
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
                    onPressed: () => _refreshTriggerKey.currentState?.refresh(),
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
}
