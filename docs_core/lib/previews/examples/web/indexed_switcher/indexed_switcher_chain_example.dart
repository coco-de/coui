import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreIndexedSwitcherStyle] slot without constructing the
/// component from scratch. The patch slows the fade-in to the slow step
/// and drops the fade-out, so the new view starts arriving at once.
class IndexedSwitcherChainExample extends StatefulComponent {
  const IndexedSwitcherChainExample({super.key});

  @override
  State<IndexedSwitcherChainExample> createState() => _IndexedSwitcherChainExampleState();
}

class _IndexedSwitcherChainExampleState extends State<IndexedSwitcherChainExample> {
  int _index = 0;

  static const List<String> _labels = ['홈', '검색', '프로필'];

  @override
  Component build(BuildContext context) {
    return div(
      [
        div(
          [
            IndexedSwitcher(
              index: _index,
              children: [
                for (final label in _labels)
                  div(
                    [Text(label).titleMedium],
                    classes: 'flex items-center justify-center h-full',
                  ),
              ],
            ).withStyle(
              const CoreIndexedSwitcherStyle(
                exitDuration: Duration.zero,
                enterDuration: Duration(milliseconds: CoreDuration.slow),
              ),
            ),
          ],
          styles: const Styles(
            raw: {'width': '16rem', 'height': '6rem'},
          ),
        ),
        Gap.space16(),
        div(
          [
            for (var idx = 0; idx < _labels.length; idx++)
              Button(
                variant: idx == _index ? CoreButtonVariant.primary : CoreButtonVariant.outline,
                onPressed: () => setState(() => _index = idx),
                child: Text(_labels[idx]),
              ),
          ],
          classes: 'flex flex-row flex-wrap justify-center gap-${CoreSpace.scale.space8}',
        ),
      ],
      classes: 'inline-flex flex-col items-center',
    );
  }
}
