import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreIndexedSwitcherStyle] slot without constructing the
/// widget from scratch. The patch slows the fade-in to the slow step and
/// drops the fade-out, so the new view starts arriving at once.
class IndexedSwitcherChainExample extends StatefulWidget {
  const IndexedSwitcherChainExample({super.key});

  @override
  State<IndexedSwitcherChainExample> createState() => _IndexedSwitcherChainExampleState();
}

class _IndexedSwitcherChainExampleState extends State<IndexedSwitcherChainExample> {
  int _index = 0;

  static const List<String> _labels = ['홈', '검색', '프로필'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: CoreSpace.space256,
          height: CoreSize.size96,
          child:
              IndexedSwitcher(
                index: _index,
                children: [
                  for (final label in _labels) Center(child: Text(label).titleMedium),
                ],
              ).withStyle(
                const CoreIndexedSwitcherStyle(
                  exitDuration: Duration.zero,
                  enterDuration: Duration(milliseconds: CoreDuration.slow),
                ),
              ),
        ),
        const Gap.space16(),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var idx = 0; idx < _labels.length; idx++)
              Padding(
                padding: const CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space4,
                ).toValue(geometry: Theme.of(context).geometry),
                child: Button(
                  variant: idx == _index ? CoreButtonVariant.primary : CoreButtonVariant.outline,
                  onPressed: () => setState(() => _index = idx),
                  child: Text(_labels[idx]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
